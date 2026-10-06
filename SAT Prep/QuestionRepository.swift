// QuestionRepository.swift – Single source of truth for all questions

import Foundation
import Combine

/// QuestionRepository provides a single source of truth for all questions
/// with intelligent caching, deduplication, and efficient queries.
class QuestionRepository: ObservableObject {
    static let shared = QuestionRepository()

    @Published var allQuestions: [Question] = []
    @Published var isLoading = false
    @Published var hasError = false

    // MARK: - Caches
    private var questionsByTopic: [String: [Question]] = [:]
    private var questionsBySubject: [Subject: [Question]] = [:]
    private var questionsByDifficulty: [Difficulty: [Question]] = [:]
    private var cacheValid = false

    private let openSATService = OpenSATService.shared

    private init() {}

    // MARK: - Load

    @MainActor
    func loadAllQuestions() async {
        guard allQuestions.isEmpty else { return }
        isLoading = true
        defer { isLoading = false }

        // Hardcoded bank (always available, offline)
        var questions: [Question] = QuestionBank.math + QuestionBank.ebrw

        // OpenSAT JSON questions (bundled in app bundle)
        let openSATQuestions = await openSATService.fetchQuestions()
        let deduped = deduplicateQuestions(openSATQuestions, against: questions)
        questions.append(contentsOf: deduped)

        allQuestions = questions
        rebuildIndexes()
    }

    // MARK: - Query

    func questions(for topic: String) -> [Question] {
        rebuildIndexesIfNeeded()
        return questionsByTopic[topic] ?? allQuestions.filter { $0.topic == topic }
    }

    func questions(for subject: Subject) -> [Question] {
        rebuildIndexesIfNeeded()
        return questionsBySubject[subject] ?? []
    }

    func questions(for difficulty: Difficulty) -> [Question] {
        rebuildIndexesIfNeeded()
        return questionsByDifficulty[difficulty] ?? []
    }

    func practiceQuestions(topic: String, count: Int = 10) -> [Question] {
        let pool = questions(for: topic).filter { !$0.isTestOnly }
        return Array(pool.shuffled().prefix(count))
    }

    func selectFullTestQuestions() -> [Question] {
        let testPool = allQuestions.filter { $0.isTestOnly }
        let math = Array(testPool.filter { $0.subject == .math }.shuffled().prefix(10))
        let ebrw = Array(testPool.filter { $0.subject == .ebrw }.shuffled().prefix(10))
        return (math + ebrw).shuffled()
    }

    // MARK: - Private Helpers

    private func deduplicateQuestions(_ new: [Question], against existing: [Question]) -> [Question] {
        let existingTexts = Set(existing.map { normalizeText($0.text) })
        return new.filter { !existingTexts.contains(normalizeText($0.text)) }
    }

    private func normalizeText(_ text: String) -> String {
        String(text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            .prefix(80))
    }

    private func rebuildIndexes() {
        questionsByTopic      = Dictionary(grouping: allQuestions) { $0.topic }
        questionsBySubject    = Dictionary(grouping: allQuestions) { $0.subject }
        questionsByDifficulty = Dictionary(grouping: allQuestions) { $0.difficulty }
        cacheValid = true
    }

    private func rebuildIndexesIfNeeded() {
        if !cacheValid { rebuildIndexes() }
    }
}
