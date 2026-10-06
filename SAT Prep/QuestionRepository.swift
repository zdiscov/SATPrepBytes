import Foundation
import Combine

/// QuestionRepository provides a single source of truth for all questions
/// with intelligent caching, deduplication, and efficient queries.
///
/// **Fixes:**
/// - N+1 query problem: questions grouped by topic on demand
/// - Memory bloat: lazy-loaded and cached question pools
/// - Code duplication: centralized question selection logic
/// - Inefficient filtering: pre-computed topic indexes
class QuestionRepository: ObservableObject {
    static let shared = QuestionRepository()
    
    @Published var allQuestions: [Question] = []
    @Published var isLoading = false
    @Published var hasError = false
    
    // MARK: - Internal Caches (performance optimization)
    private var questionsByTopic: [String: [Question]] = [:]
    private var questionsBySubject: [Subject: [Question]] = [:]
    private var questionsByDifficulty: [Difficulty: [Question]] = [:]
    private var cacheValid = false
    
    private let openSATService = OpenSATService.shared
    private let questionBank = QuestionBank.self
    
    private init() {}
    
    /// Load all questions (hardcoded + OpenSAT)
    /// Deduplicates automatically and caches for performance
    @MainActor
    func loadAllQuestions() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            // Load hardcoded questions first (always available)
            var questions =






























































    func selectFullTestQuestions() -> [Question] {
        let testPool = allQuestions.filter { $0.isTestOnly }
        
        // Get 10 math + 10 EBRW
        let mathQuestions = testPool
            .filter { $0.subject == .math }
            .shuffled()
            .prefix(10)
        
        let ebrwQuestions = testPool
            .filter { $0.subject == .ebrw }
            .shuffled()
            .prefix(10)
        
        var result = Array(mathQuestions) + Array(ebrwQuestions)
        result.shuffle() // Mix them up for a realistic test
        return result
    }
    
    // MARK: - Private Helpers
    
    private func deduplicateQuestions(_ new: [Question], against existing: [Question]) -> [Question] {
        let existingTexts = Set(existing.map { self.normalizeText($0.text) })
        return new.filter { !existingTexts.contains(self.normalizeText($0.text)) }
    }
    
    private func normalizeText(_ text: String) -> String {
        text.lowercased()
            .replacingOccurrences(of: "[^a-z0-9]", with: "", options: .regularExpression)
            .prefix(80)
            .description
    }
    
    private func rebuildIndexes() {
        // Group by topic
        questionsByTopic = Dictionary(grouping: allQuestions, by: { $0.topic })
        
        // Group by subject
        questionsBySubject = Dictionary(grouping: allQuestions, by: { $0.subject })
        
        // Group by difficulty
        questionsByDifficulty = Dictionary(grouping: allQuestions, by: { $0.difficulty })
        
        cacheValid = true
    }
    
    private func rebuildIndexesIfNeeded() {
        if !cacheValid {
            rebuildIndexes()
        }
    }
}
