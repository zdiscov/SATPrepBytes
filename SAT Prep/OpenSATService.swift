// OpenSATService.swift
// Fetches SAT questions from OpenSAT — open source, MIT licensed.
// Source: github.com/Anas099X/OpenSAT  Data: api.jsonsilo.com (public)

import Foundation

#if canImport(FoundationModels)
import FoundationModels
#endif

// MARK: - Raw JSON Models

private struct OpenSATResponse: Decodable {
    let math: [OpenSATQuestion]
    let english: [OpenSATQuestion]
}

private struct OpenSATQuestion: Decodable {
    let id: String
    let domain: String
    let difficulty: String         // "Easy", "Medium", "Hard"
    let question: OpenSATContent
}

private struct OpenSATContent: Decodable {
    let question: String
    let paragraph: String?
    let choices: OpenSATChoices
    let correct_answer: String     // "A", "B", "C", "D"
    let explanation: String
}

private struct OpenSATChoices: Decodable {
    let A: String
    let B: String
    let C: String
    let D: String
}

// MARK: - Service

final class OpenSATService {

    static let shared = OpenSATService()
    private let url = "https://api.jsonsilo.com/public/942c3c3b-3a0c-4be3-81c2-12029def19f5"
    private let cacheFile = "opensat_v22.json"

    private init() {}

    func fetchQuestions() async -> [Question] {
        if let cached = loadCache() { return cached }

        guard let url = URL(string: url),
              let (data, _) = try? await URLSession.shared.data(from: url),
              let raw = try? JSONDecoder().decode(OpenSATResponse.self, from: data) else { return [] }

        var questions = (raw.math.map { map($0, subject: .math) } +
                         raw.english.compactMap { q -> OpenSATQuestion? in
                             // Skip English passage questions — OpenSAT passage data is low quality
                             guard q.question.paragraph == nil || q.question.paragraph == "null" else { return nil }
                             return q
                         }.map { map($0, subject: .ebrw) })
            .compactMap { $0 }

        saveCache(questions)

        // Process questions using on-device Apple AI dynamically in the background to save cloud tokens
        Task.detached(priority: .background) {
            await self.processQuestionsWithAI(&questions)
        }

        return questions
    }

    func deduplicated(_ questions: [Question], against hardcoded: [Question]) -> [Question] {
        let existing = Set(hardcoded.map { normalize($0.text) })
        return questions.filter { !existing.contains(normalize($0.text)) }
    }

    private func normalize(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            .prefix(80).description
    }

    // MARK: - Mapping

    private func map(_ q: OpenSATQuestion, subject: Subject) -> Question? {
        let c = q.question
        guard c.correct_answer.count == 1,
              let correctIndex = ["A","B","C","D"].firstIndex(of: c.correct_answer) else { return nil }

        let stem = c.paragraph.map { p in
            p != "null" ? "\(p)\n\n\(c.question)" : c.question
        } ?? c.question

        let stemLower = stem.lowercased()
        let badPatterns = ["shown below","shown above","figure below","figure above",
                           "graph below","graph above","table below","table above",
                           "align*","\\begin{","\\array",
                           // Formatting artifacts
                           "underlined","blank line","[blank]","as used in line",
                           "combines the sentences","completes the text",
                           "conforms to the conventions",
                           "corrects the error in the",
                           "use of metaphors","use of imagery","use of simile",
                           "semicolon in the passage","purpose of the semi",
                           // Self-referential passages
                           "the author's main purpose is to","the author's primary goal is to",
                           "the central theme of the passage is","the author begins by describing",
                           // Math requiring diagrams
                           "chord of the circle","chord of length","chord is"]
        if badPatterns.contains(where: { stemLower.contains($0) }) { return nil }

        return Question(
            id: UUID(),
            text: stem.strippingLatex,
            options: [c.choices.A, c.choices.B, c.choices.C, c.choices.D].map { $0.strippingLatex },
            correctIndex: correctIndex,
            explanation: c.explanation.strippingLatex,
            subject: subject,
            topic: mapTopic(q.domain, subject: subject),
            difficulty: mapDifficulty(q.difficulty),
            isAIGenerated: false,
            aiTopicCategory: "opensat"
        )
    }

    private func mapTopic(_ domain: String, subject: Subject) -> String {
        if subject == .math {
            switch domain {
            case "Algebra":                            return MathTopic.algebra.rawValue
            case "Advanced Math":                      return MathTopic.advancedMath.rawValue
            case "Problem-Solving and Data Analysis":  return MathTopic.problemSolving.rawValue
            default:                                   return MathTopic.geometry.rawValue
            }
        } else {
            switch domain {
            case "Information and Ideas":              return EBRWTopic.informationIdeas.rawValue
            case "Craft and Structure":                return EBRWTopic.craftStructure.rawValue
            case "Expression of Ideas":                return EBRWTopic.expressionIdeas.rawValue
            default:                                   return EBRWTopic.standardEnglish.rawValue
            }
        }
    }

    private func mapDifficulty(_ d: String) -> Difficulty {
        switch d { case "Easy": return .easy; case "Hard": return .hard; default: return .medium }
    }

    // MARK: - Cache

    private var cacheURL: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(cacheFile)
    }

    private func saveCache(_ questions: [Question]) {
        try? JSONEncoder().encode(questions).write(to: cacheURL)
    }

    private func loadCache() -> [Question]? {
        guard let data = try? Data(contentsOf: cacheURL) else { return nil }
        return try? JSONDecoder().decode([Question].self, from: data)
    }

    private func processQuestionsWithAI(_ questions: inout [Question]) async {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, macOS 15.0, *),
              SystemLanguageModel.default.isAvailable else { return }

        let session = LanguageModelSession()
        var updated = false

        for i in 0..<questions.count {
            let q = questions[i]
            let promptText = "Clean up the LaTeX dollar signs and formatting from this SAT question. Output ONLY the cleaned plain text: \(q.text)"
            let promptExpl = "Clean up the LaTeX dollar signs, formatting, and correct any obvious math typos in this SAT explanation. Output ONLY the cleaned plain text: \(q.explanation)"

            var textCleaned = q.text
            var explCleaned = q.explanation

            if q.text.contains("$") {
                if let response = try? await session.respond(to: promptText) {
                    textCleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
            if q.explanation.contains("$") {
                if let response = try? await session.respond(to: promptExpl) {
                    explCleaned = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }

            if textCleaned != q.text || explCleaned != q.explanation {
                questions[i] = Question(
                    id: q.id,
                    text: textCleaned,
                    options: q.options,
                    correctIndex: q.correctIndex,
                    explanation: explCleaned,
                    subject: q.subject,
                    topic: q.topic,
                    difficulty: q.difficulty,
                    isAIGenerated: q.isAIGenerated,
                    aiTopicCategory: q.aiTopicCategory
                )
                updated = true
            }

            // Periodically save cache in background
            if updated && i % 20 == 0 {
                saveCache(questions)
            }
        }

        if updated {
            saveCache(questions)
        }
        #endif
    }
}
