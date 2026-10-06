// AppState.swift – Central app state store

import Foundation
import Combine

final class AppState: ObservableObject {

    // MARK: - Published State

    @Published var currentUser: User = User.empty
    @Published var sessions: [PracticeSession] = []
    @Published var performanceRecords: [PerformanceRecord] = []
    @Published var studyPlan: StudyPlan?
    @Published var isOnboarded: Bool = false
    @Published var aiFeedbackRecords: [AIQuestionFeedback] = []
    @Published var aiEnabled: Bool = false
    @Published var aiTriggerMode: AITriggerMode = .afterExhaustion
    @Published var bookmarkedQuestionIds: Set<UUID> = []

    enum AITriggerMode: String, Codable, CaseIterable {
        case afterExhaustion = "After exhausting hardcoded questions"
        case mixed           = "Mix in immediately (10% of questions)"
    }

    // MARK: - Persistence Keys

    private let userKey = "sat_user"
    private let sessionsKey = "sat_sessions"
    private let recordsKey = "sat_records"
    private let planKey = "sat_plan"
    private let aiFeedbackKey = "sat_ai_feedback"
    private let aiEnabledKey = "sat_ai_enabled"
    private let bookmarksKey = "sat_bookmarks"

    // MARK: - Init

    init() {
        load()
    }

    // MARK: - User Management

    func saveUser(_ user: User) {
        currentUser = user
        isOnboarded = user.hasCompletedOnboarding
        persist()
    }

    func updateStreak() {
        let today = Calendar.current.startOfDay(for: Date())
        var user = currentUser
        if let last = user.lastActiveDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let diff = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if diff == 1 {
                user.streakDays += 1
            } else if diff > 1 {
                user.streakDays = 1
            }
            // diff == 0 means same day, no change
        } else {
            user.streakDays = 1
        }
        user.lastActiveDate = Date()
        currentUser = user
        persist()
    }

    // MARK: - Score Scaling Helper

    static func scaleScore(correct: Int, total: Int, range: ClosedRange<Int> = 200...800) -> Int {
        guard total > 0 else { return range.lowerBound }
        let pct = Double(correct) / Double(total)
        let span = Double(range.upperBound - range.lowerBound)
        return Int(Double(range.lowerBound) + pct * span)
    }

    // MARK: - Bookmarking / Spaced Repetition

    func toggleBookmark(for questionId: UUID) {
        if bookmarkedQuestionIds.contains(questionId) {
            bookmarkedQuestionIds.remove(questionId)
        } else {
            bookmarkedQuestionIds.insert(questionId)
        }
        persist()
    }

    func isBookmarked(_ questionId: UUID) -> Bool {
        bookmarkedQuestionIds.contains(questionId)
    }

    // MARK: - Session Recording

    func recordSession(_ session: PracticeSession) {
        sessions.append(session)
        updatePerformance(from: session)
        updateStreak()
        
        // Auto-bookmark incorrect questions for review
        for attempt in session.attempts {
            if !attempt.isCorrect {
                bookmarkedQuestionIds.insert(attempt.questionId)
            }
        }
        
        persist()
    }

    // MARK: - Performance Tracking

    private func updatePerformance(from session: PracticeSession) {
        switch session.sessionType {
        case .practice(let topic, let subject):
            let correct = session.attempts.filter(\.isCorrect).count
            let total = session.attempts.count
            let proficiency = total > 0 ? Double(correct) / Double(total) : 0

            let record = PerformanceRecord(
                id: UUID(),
                userId: currentUser.id,
                topic: topic,
                subject: subject,
                date: session.date,
                proficiency: proficiency,
                questionsAttempted: total,
                questionsCorrect: correct
            )
            performanceRecords.append(record)
        case .fullTest:
            // Group attempts by their actual question topic to build accurate performance analytics
            let questionsMap = Dictionary(uniqueKeysWithValues: allQuestions.map { ($0.id, $0) })
            var topicAttempts: [String: [QuestionAttempt]] = [:]
            for attempt in session.attempts {
                if let q = questionsMap[attempt.questionId] {
                    topicAttempts[q.topic, default: []].append(attempt)
                }
            }
            for (topicName, attempts) in topicAttempts {
                let correct = attempts.filter(\.isCorrect).count
                let total = attempts.count
                let proficiency = total > 0 ? Double(correct) / Double(total) : 0
                if let firstQ = questionsMap[attempts[0].questionId] {
                    let record = PerformanceRecord(
                        id: UUID(),
                        userId: currentUser.id,
                        topic: topicName,
                        subject: firstQ.subject,
                        date: session.date,
                        proficiency: proficiency,
                        questionsAttempted: total,
                        questionsCorrect: correct
                    )
                    performanceRecords.append(record)
                }
            }
        }
    }

    // MARK: - Study Plan Generation

    func generateStudyPlan() {
        let testDate = currentUser.testDate ?? Calendar.current.date(byAdding: .month, value: 3, to: Date())!
        let weakTopics = weakestTopics(limit: 6)
        let totalDays = Calendar.current.dateComponents([.day], from: Date(), to: testDate).day ?? 90
        let interval = max(1, totalDays / max(weakTopics.count, 1))

        let milestones = weakTopics.enumerated().map { (i, topicPair) -> StudyMilestone in
            let target = Calendar.current.date(byAdding: .day, value: (i + 1) * interval, to: Date())!
            return StudyMilestone(id: UUID(), topic: topicPair.topic,
                                  subject: topicPair.subject, targetDate: target, isCompleted: false)
        }

        studyPlan = StudyPlan(id: UUID(), userId: currentUser.id,
                              startDate: Date(), milestones: milestones)
        persist()
    }

    // MARK: - Analytics Helpers

    /// Topics with the lowest proficiency
    func weakestTopics(limit: Int = 4) -> [(subject: Subject, topic: String)] {
        let allTopics = QuestionBank.allTopics
        var scores: [(subject: Subject, topic: String, proficiency: Double)] = allTopics.map { pair in
            let records = performanceRecords.filter { $0.topic == pair.topic }
            let avg = records.isEmpty ? 0.5 : records.map(\.proficiency).reduce(0, +) / Double(records.count)
            return (pair.subject, pair.topic, avg)
        }
        scores.sort { $0.proficiency < $1.proficiency }
        return scores.prefix(limit).map { (subject: $0.subject, topic: $0.topic) }
    }

    func questionsStats(for topic: String) -> (correct: Int, attempted: Int) {
        let topicSessions = sessions.filter { $0.topic == topic }
        let attempts = topicSessions.flatMap(\.attempts)
        let correct = attempts.filter(\.isCorrect).count
        return (correct: correct, attempted: attempts.count)
    }

    func proficiency(for topic: String) -> Double {
        let records = performanceRecords.filter { $0.topic == topic }
        guard !records.isEmpty else { return 0 }
        return records.map(\.proficiency).reduce(0, +) / Double(records.count)
    }

    func recentSessions(limit: Int = 10) -> [PracticeSession] {
        sessions.sorted { $0.date > $1.date }.prefix(limit).map { $0 }
    }

    var mathEstimatedScore: Int {
        let mathQuestionsIds = Set(QuestionBank.math.map(\.id))
        var mathCorrect = 0
        var mathTotal = 0
        for session in sessions {
            for attempt in session.attempts {
                if mathQuestionsIds.contains(attempt.questionId) || session.subject == .math {
                    mathTotal += 1
                    if attempt.isCorrect { mathCorrect += 1 }
                }
            }
        }
        return AppState.scaleScore(correct: mathCorrect, total: mathTotal)
    }

    var ebrwEstimatedScore: Int {
        let ebrwQuestionsIds = Set(QuestionBank.ebrw.map(\.id))
        var ebrwCorrect = 0
        var ebrwTotal = 0
        for session in sessions {
            for attempt in session.attempts {
                if ebrwQuestionsIds.contains(attempt.questionId) || session.subject == .ebrw {
                    ebrwTotal += 1
                    if attempt.isCorrect { ebrwCorrect += 1 }
                }
            }
        }
        return AppState.scaleScore(correct: ebrwCorrect, total: ebrwTotal)
    }

    var estimatedScore: Int {
        mathEstimatedScore + ebrwEstimatedScore
    }

    // MARK: - Persistence

    func persist() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(currentUser) { UserDefaults.standard.set(data, forKey: userKey) }
        if let data = try? encoder.encode(sessions) { UserDefaults.standard.set(data, forKey: sessionsKey) }
        if let data = try? encoder.encode(performanceRecords) { UserDefaults.standard.set(data, forKey: recordsKey) }
        if let data = try? encoder.encode(studyPlan) { UserDefaults.standard.set(data, forKey: planKey) }
        if let data = try? encoder.encode(aiFeedbackRecords) { UserDefaults.standard.set(data, forKey: aiFeedbackKey) }
        if let data = try? encoder.encode(bookmarkedQuestionIds) { UserDefaults.standard.set(data, forKey: bookmarksKey) }
        UserDefaults.standard.set(aiEnabled, forKey: aiEnabledKey)
    }

    private func load() {
        let decoder = JSONDecoder()
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? decoder.decode(User.self, from: data) {
            currentUser = user
            isOnboarded = user.hasCompletedOnboarding
        }
        if let data = UserDefaults.standard.data(forKey: sessionsKey),
           let s = try? decoder.decode([PracticeSession].self, from: data) { sessions = s }
        if let data = UserDefaults.standard.data(forKey: recordsKey),
           let r = try? decoder.decode([PerformanceRecord].self, from: data) { performanceRecords = r }
        if let data = UserDefaults.standard.data(forKey: planKey),
           let p = try? decoder.decode(StudyPlan.self, from: data) { studyPlan = p }
        if let data = UserDefaults.standard.data(forKey: aiFeedbackKey),
           let f = try? decoder.decode([AIQuestionFeedback].self, from: data) { aiFeedbackRecords = f }
        if let data = UserDefaults.standard.data(forKey: bookmarksKey),
           let b = try? decoder.decode(Set<UUID>.self, from: data) { bookmarkedQuestionIds = b }
        aiEnabled = UserDefaults.standard.bool(forKey: aiEnabledKey)
    }

    func resetAll() {
        currentUser = User.empty
        sessions = []
        performanceRecords = []
        studyPlan = nil
        isOnboarded = false
        aiFeedbackRecords = []
        bookmarkedQuestionIds = []
        [userKey, sessionsKey, recordsKey, planKey, aiFeedbackKey, bookmarksKey, reviewPromptDatesKey].forEach {
            UserDefaults.standard.removeObject(forKey: $0)
        }
    }

    // MARK: - Review Prompt Logic

    private let reviewPromptDatesKey = "sat_review_prompt_dates"

    var reviewPromptDates: [Date] {
        get {
            guard let dates = UserDefaults.standard.array(forKey: reviewPromptDatesKey) as? [Date] else { return [] }
            return dates
        }
        set {
            UserDefaults.standard.set(newValue, forKey: reviewPromptDatesKey)
        }
    }

    var shouldPromptForReview: Bool {
        guard sessions.count >= 3 else { return false }
        let now = Date()
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: now) ?? now
        let recentPrompts = reviewPromptDates.filter { $0 > oneYearAgo }
        guard recentPrompts.count < 3 else { return false }
        if let lastPrompt = reviewPromptDates.last {
            let daysSince = Calendar.current.dateComponents([.day], from: lastPrompt, to: now).day ?? 0
            guard daysSince >= 60 else { return false }
        }
        return true
    }

    func recordReviewPromptShown() {
        var dates = reviewPromptDates
        dates.append(Date())
        reviewPromptDates = dates
    }

    func debugForceReviewEligible() {
        UserDefaults.standard.removeObject(forKey: reviewPromptDatesKey)
    }

    @Published var openSATQuestions: [Question] = []
    @Published var openSATLoaded: Bool = false
    @Published var vocabQuestions: [Question] = []
    @Published var vocabLoaded: Bool = false

    /// All available questions: hardcoded + OpenSAT (deduped) + Vocab
    var allQuestions: [Question] {
        QuestionBank.all + openSATQuestions + vocabQuestions
    }

    func loadVocabQuestions() {
        guard let url = Bundle.main.url(forResource: "vocab_questions", withExtension: "json") else {
            return
        }
        if let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode([Question].self, from: data) {
            self.vocabQuestions = decoded
            self.vocabLoaded = true
        }
    }

    func loadOpenSATQuestions() async {
        let fetched = await OpenSATService.shared.fetchQuestions()
        let deduped = OpenSATService.shared.deduplicated(fetched, against: QuestionBank.all)
        await MainActor.run {
            openSATQuestions = deduped
            openSATLoaded = true
        }
    }

    func recordAIFeedback(_ feedback: AIQuestionFeedback) {
        aiFeedbackRecords.append(feedback)
        persist()
    }

    /// Returns agreement rate (0.0–1.0) for a topic. nil if no data.
    func aiAccuracy(for topic: String) -> Double? {
        let records = aiFeedbackRecords.filter { $0.topic == topic }
        guard !records.isEmpty else { return nil }
        let agreed = records.filter(\.verificationAgreed).count
        return Double(agreed) / Double(records.count)
    }

    var aiAccuracyByTopic: [(topic: String, subject: Subject, accuracy: Double, count: Int)] {
        let topics = QuestionBank.allTopics
        return topics.compactMap { pair in
            let records = aiFeedbackRecords.filter { $0.topic == pair.topic }
            guard !records.isEmpty else { return nil }
            let agreed = records.filter(\.verificationAgreed).count
            return (pair.topic, pair.subject, Double(agreed) / Double(records.count), records.count)
        }
    }
}
