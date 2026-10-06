// AIQuestionService.swift
// Uses Apple's on-device Foundation Models (iOS 18.1+, iPhone 15 Pro+)

import Foundation
import Observation

#if canImport(FoundationModels)
import FoundationModels
#endif

@Observable
@MainActor
final class AIQuestionService {

    static let shared = AIQuestionService()

    var isAvailable: Bool = false
    var isGenerating: Bool = false
    var lastError: String? = nil

    private init() {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            isAvailable = SystemLanguageModel.default.isAvailable
        }
        #endif
    }

    // MARK: - Public API

    func generateQuestion(topic: String, subject: Subject, difficulty: Difficulty = .medium) async -> Question? {
        guard isAvailable else { return nil }
        isGenerating = true
        defer { isGenerating = false }
        let prompt = buildPrompt(topic: topic, subject: subject, difficulty: difficulty)
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            for attempt in 1...2 {
                do {
                    let session = LanguageModelSession()
                    let response = try await session.respond(to: prompt)
                    guard let q = parseQuestion(from: response.content, topic: topic, subject: subject, difficulty: difficulty) else { continue }

                    // Structural validation
                    if let err = validate(q) {
                        lastError = "Attempt \(attempt) validation failed: \(err)"
                        continue
                    }

                    // AI self-verification gate — nil means verification failed, reject
                    let agrees = await verifyAnswer(question: q)
                    guard agrees == true else {
                        lastError = "Attempt \(attempt) rejected: verification \(agrees == nil ? "failed to parse" : "disagreed")"
                        continue
                    }

                    lastError = nil
                    return q
                } catch {
                    lastError = error.localizedDescription
                    return nil
                }
            }
        }
        #endif
        return nil
    }

    func verifyAnswer(question: Question) async -> Bool? {
        guard isAvailable else { return nil }

        // Ask AI to independently solve the question and state the correct answer
        let verifyPrompt = """
        Solve this problem step by step:
        "\(question.text)"
        A: \(question.options[0])
        B: \(question.options[1])
        C: \(question.options[2])
        D: \(question.options[3])

        Show your work, then on the last line write exactly:
        ANSWER: A
        (replace A with whichever letter is correct)
        """

        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession()
                let response = try await session.respond(to: verifyPrompt)
                let content = response.content.uppercased()

                // Extract the ANSWER: letter from the verification response
                if let range = content.range(of: "ANSWER:") {
                    let after = content[range.upperBound...].trimmingCharacters(in: .whitespaces)
                    let verifiedLetter = String(after.prefix(1))
                    let verifiedIndex: Int
                    switch verifiedLetter {
                    case "A": verifiedIndex = 0
                    case "B": verifiedIndex = 1
                    case "C": verifiedIndex = 2
                    case "D": verifiedIndex = 3
                    default: return nil
                    }
                    // Only pass if verification agrees with the generated correctIndex
                    return verifiedIndex == question.correctIndex
                }
                return nil
            } catch { return nil }
        }
        #endif
        return nil
    }

    // MARK: - Dev Mode Mock (always available for testing)

    /// Returns a mock AI question for developer testing without needing Apple Intelligence.
    func mockQuestion(topic: String, subject: Subject) -> Question {
        Question(
            id: UUID(),
            text: "[DEV MOCK] If 3x + 6 = 21, what is the value of 2x? (Topic: \(topic))",
            options: ["5", "10", "12", "15"],
            correctIndex: 1,
            explanation: "[DEV MOCK] 3x = 15 → x = 5 → 2x = 10.",
            subject: subject,
            topic: topic,
            difficulty: .medium,
            isAIGenerated: true,
            aiTopicCategory: subject == .math ? "experimental" : "ebrw"
        )
    }

    // MARK: - Prompt Builder

    private func buildPrompt(topic: String, subject: Subject, difficulty: Difficulty) -> String {
        let difficultyDesc = difficulty == .easy ? "straightforward" : difficulty == .medium ? "moderately challenging" : "challenging"

        if subject == .math {
            return """
            Generate one \(difficultyDesc) Digital SAT math question about \(topic).
            Format your response EXACTLY as:
            QUESTION: [question text]
            A: [option A]
            B: [option B]
            C: [option C]
            D: [option D]
            CORRECT: [A, B, C, or D]
            EXPLANATION: [one sentence explanation]

            Rules:
            - Self-contained, no figures needed, realistic SAT style, exactly 4 options, one correct answer.
            - Use plain text only. Write math using Unicode: × ÷ ≥ ≤ ≠ √ π ² ³ and fractions like 3/4.
            - All answer options must be consistent in form (all values, or all expressions — not mixed).
            """
        } else {
            return """
            Generate one \(difficultyDesc) Digital SAT Reading & Writing question about \(topic).
            Include a short 2-3 sentence passage, then one question about it.
            Format your response EXACTLY as:
            QUESTION: [passage + question text]
            A: [option A]
            B: [option B]
            C: [option C]
            D: [option D]
            CORRECT: [A, B, C, or D]
            EXPLANATION: [one sentence explanation]

            Rules: Passage must be self-contained, question tests \(topic) skills, exactly 4 options. Plain text only (no LaTeX needed).
            """
        }
    }

    // MARK: - Validation

    /// Returns nil if question is malformed, with a reason string.
    func validate(_ q: Question) -> String? {
        // 1. Question text must be non-trivial
        guard q.text.count > 20 else { return "Question text too short" }

        // 2. All options must be non-empty and distinct
        let options = q.options
        guard options.allSatisfy({ !$0.isEmpty }) else { return "Empty option(s)" }
        guard Set(options).count == options.count else { return "Duplicate options" }

        // 3. correctIndex must be valid
        guard q.correctIndex >= 0 && q.correctIndex < options.count else { return "Invalid correctIndex" }

        // 4. Explanation must be non-trivial
        guard q.explanation.count > 10 else { return "Explanation too short" }

        // 5. For math: if question mentions "simplify", "evaluate", "expression"
        //    then options should NOT all contain "=" (they should be values, not equations)
        let mathExpressionKeywords = ["simplify", "equivalent to", "evaluate", "value of the expression"]
        let questionLower = q.text.lowercased()
        let isMathExpression = mathExpressionKeywords.contains { questionLower.contains($0) }
        if isMathExpression && q.subject == .math {
            let optionsWithEquals = options.filter { $0.contains("=") }
            if optionsWithEquals.count == options.count {
                return "All options contain '=' but question asks to simplify/evaluate an expression"
            }
        }

        // 6. Options should not all be identical length single chars (degenerate)
        let allSingleChar = options.allSatisfy { $0.count == 1 }
        guard !allSingleChar else { return "Options are all single characters — likely malformed" }

        // 7. Question should not contain placeholder text
        let placeholders = ["[question", "[option", "[passage", "insert", "xxx"]
        for p in placeholders {
            if questionLower.contains(p) { return "Question contains placeholder text: '\(p)'" }
        }

        return nil // valid
    }

    private func stripLatex(_ text: String) -> String { text.strippingLatex }

    // MARK: - Response Parser

    private func parseQuestion(from text: String, topic: String, subject: Subject, difficulty: Difficulty) -> Question? {
        let lines = text.components(separatedBy: "\n").map { $0.trimmingCharacters(in: .whitespaces) }

        func extract(_ prefix: String) -> String? {
            lines.first { $0.hasPrefix(prefix) }?
                .replacingOccurrences(of: prefix, with: "")
                .trimmingCharacters(in: .whitespaces)
        }

        guard
            let questionText = extract("QUESTION:"),
            let optA = extract("A:"),
            let optB = extract("B:"),
            let optC = extract("C:"),
            let optD = extract("D:"),
            let correct = extract("CORRECT:"),
            let explanation = extract("EXPLANATION:")
        else { return nil }

        let correctIndex: Int
        switch correct.uppercased().first {
        case "A": correctIndex = 0
        case "B": correctIndex = 1
        case "C": correctIndex = 2
        case "D": correctIndex = 3
        default: return nil
        }

        return Question(
            id: UUID(),
            text: stripLatex(questionText),
            options: [optA, optB, optC, optD].map { stripLatex($0) },
            correctIndex: correctIndex,
            explanation: stripLatex(explanation),
            subject: subject,
            topic: topic,
            difficulty: difficulty,
            isAIGenerated: true,
            aiTopicCategory: subject == .math ? "experimental" : "ebrw"
        )
    }
}
