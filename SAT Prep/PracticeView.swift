// PracticeView.swift

import SwiftUI

struct PracticeView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeQuiz: QuizConfig? = nil
    @State private var showPaywall = false
    @State private var showReviewView = false

    struct QuizConfig: Identifiable {
        let id = UUID()
        let topic: String
        let subject: Subject
    }

    private func isLocked(_ topic: String) -> Bool {
        if appState.currentUser.isPremium { return false }
        let premiumTopics = [
            MathTopic.advancedMath.rawValue,
            MathTopic.geometry.rawValue,
            EBRWTopic.craftStructure.rawValue,
            EBRWTopic.expressionIdeas.rawValue
        ]
        return premiumTopics.contains(topic)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Review & Spaced Repetition") {
                    let bookmarkedCount = appState.bookmarkedQuestionIds.count
                    if bookmarkedCount == 0 {
                        Text("No questions to review yet! Incorrect answers are added here automatically.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    } else {
                        NavigationLink(destination: BookmarkReviewView()) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Review Bookmarks & Session History")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text("\(bookmarkedCount) bookmarked questions")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "star.fill").foregroundStyle(.yellow)
                                Image(systemName: "chevron.right").foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                Section("Math") {
                    ForEach(MathTopic.allCases, id: \.self) { topic in
                        let locked = isLocked(topic.rawValue)
                        let stats = appState.questionsStats(for: topic.rawValue)
                        TopicRow(topic: topic.rawValue, subject: .math,
                                 proficiency: appState.proficiency(for: topic.rawValue),
                                 correctCount: stats.correct, attemptedCount: stats.attempted,
                                 isLocked: locked) {
                            if locked {
                                showPaywall = true
                            } else {
                                activeQuiz = QuizConfig(topic: topic.rawValue, subject: .math)
                            }
                        }
                    }
                }
                Section("Reading & Writing") {
                    ForEach(EBRWTopic.allCases, id: \.self) { topic in
                        let locked = isLocked(topic.rawValue)
                        let stats = appState.questionsStats(for: topic.rawValue)
                        TopicRow(topic: topic.rawValue, subject: .ebrw,
                                 proficiency: appState.proficiency(for: topic.rawValue),
                                 correctCount: stats.correct, attemptedCount: stats.attempted,
                                 isLocked: locked) {
                            if locked {
                                showPaywall = true
                            } else {
                                activeQuiz = QuizConfig(topic: topic.rawValue, subject: .ebrw)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Practice")
            .sheet(item: $activeQuiz) { config in
                QuizView(topic: config.topic, subject: config.subject, appState: appState) { session in
                    appState.recordSession(session)
                }
                .environmentObject(appState)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Topic Row

private struct TopicRow: View {
    let topic: String
    let subject: Subject
    let proficiency: Double
    let correctCount: Int
    let attemptedCount: Int
    let isLocked: Bool
    let action: () -> Void

    private var proficiencyLabel: String {
        switch proficiency {
        case 0..<0.01: return "Not Started"
        case 0.01..<0.4: return "Needs Work"
        case 0.4..<0.7: return "Developing"
        default: return "Proficient"
        }
    }
    private var proficiencyColor: Color {
        switch proficiency {
        case 0..<0.01: return .gray
        case 0.01..<0.4: return .red
        case 0.4..<0.7: return .orange
        default: return .green
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(topic).font(.subheadline.bold()).foregroundStyle(.primary)
                        if isLocked {
                            Image(systemName: "lock.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    HStack(spacing: 8) {
                        Text(proficiencyLabel).font(.caption).foregroundStyle(proficiencyColor)
                        if attemptedCount > 0 {
                            Text("•  \(correctCount)/\(attemptedCount) correct")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Spacer()
                if proficiency > 0 && !isLocked {
                    CircularProgress(progress: proficiency, color: proficiencyColor)
                        .frame(width: 36, height: 36)
                }
                Image(systemName: "chevron.right").foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Quiz View

struct QuizView: View {
    let topic: String
    let subject: Subject
    let onComplete: (PracticeSession) -> Void

    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var questions: [Question]
    @State private var currentIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var attempts: [QuestionAttempt] = []
    @State private var showExplanation = false
    @State private var isComplete = false
    @State private var startTime = Date()

    init(topic: String, subject: Subject, appState: AppState, onComplete: @escaping (PracticeSession) -> Void) {
        self.topic = topic
        self.subject = subject
        self.onComplete = onComplete
        
        let initialQuestions = Self.generatePracticeQuestions(topic: topic, subject: subject, appState: appState)
        _questions = State(initialValue: initialQuestions)
    }

    private static func generatePracticeQuestions(topic: String, subject: Subject, appState: AppState) -> [Question] {
        if topic == "Review Session" {
            let ids = appState.bookmarkedQuestionIds
            return appState.allQuestions.filter { ids.contains($0.id) }.shuffled()
        }

        let attemptedIds = Set(appState.sessions.flatMap { $0.attempts.map(\.questionId) })

        // Filter out test-only questions for practice
        let hardcodedPool = QuestionBank.all.filter { $0.topic == topic && !$0.isTestOnly }
        let openSATPool = appState.openSATQuestions.filter { $0.topic == topic && !$0.isTestOnly }
        let combinedPool = hardcodedPool + openSATPool

        // Filter for unattempted questions first
        let unattempted = combinedPool.filter { !attemptedIds.contains($0.id) }

        if unattempted.count >= 10 {
            return Array(unattempted.shuffled().prefix(10))
        } else {
            // Fallback: allow repeats if all have been exhausted, but still exclude test-only
            return Array(combinedPool.shuffled().prefix(10))
        }
    }

    private func buildQuestions() -> [Question] {
        Self.generatePracticeQuestions(topic: topic, subject: subject, appState: appState)
    }

    private var current: Question { questions[currentIndex] }

    var body: some View {
        NavigationStack {
            if questions.isEmpty {
                ContentUnavailableView("No questions yet",
                                       systemImage: "questionmark.circle",
                                       description: Text("Questions for this topic are coming soon."))
            } else if isComplete {
                QuizResultsView(attempts: attempts, topic: topic) {
                    onComplete(buildSession())
                    dismiss()
                }
            } else {
                VStack(spacing: 0) {
                    // SwiftUI's built-in ProgressView
                    ProgressView(value: Double(currentIndex), total: Double(questions.count))
                        .padding([.horizontal, .top])
                    Text("\(topic) · \(currentIndex + 1)/\(questions.count)")
                        .font(.caption).foregroundStyle(.secondary).padding(.bottom, 4)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Source badge
                            if current.isAIGenerated {
                                HStack(spacing: 4) {
                                    Image(systemName: "sparkles")
                                    Text(current.aiTopicCategory == "experimental" ? "⚗️ Experimental AI" : "🤖 AI Generated")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 8).padding(.vertical, 4)
                                .background(Capsule().fill(Color.purple.opacity(0.12)))
                                .foregroundStyle(.purple)
                            } else if current.aiTopicCategory == "opensat" {
                                Label("SAT Prep Practice Question", systemImage: "checkmark.seal.fill")
                                    .font(.caption.bold())
                                    .padding(.horizontal, 8).padding(.vertical, 4)
                                    .background(Capsule().fill(Color.blue.opacity(0.12)))
                                    .foregroundStyle(.blue)
                            }
                            DifficultyBadge(difficulty: current.difficulty)
                            LaTeXView(current.text, fontSize: 16)
                            ForEach(current.options.indices, id: \.self) { i in
                                OptionButton(
                                    label: ["A","B","C","D"][i],
                                    text: current.options[i],
                                    state: optionState(i),
                                    isDisabled: showExplanation
                                ) { selectedOption = i }
                            }
                            if showExplanation {
                                ExplanationCard(isCorrect: selectedOption == current.correctIndex,
                                                explanation: current.explanation)
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                        .padding()
                    }

                    VStack(spacing: 12) {
                        if !showExplanation {
                            Button("Check Answer") {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                    showExplanation = true
                                }
                                if selectedOption == current.correctIndex {
                                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                } else {
                                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedOption == nil)
                            .frame(maxWidth: .infinity)
                        } else {
                            Button(currentIndex + 1 < questions.count ? "Next Question" : "Finish Quiz") {
                                recordAttempt()
                                if currentIndex + 1 < questions.count {
                                    currentIndex += 1; selectedOption = nil; showExplanation = false
                                } else {
                                    isComplete = true
                                }
                            }
                            .buttonStyle(.borderedProminent)
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding()
                }
                .navigationTitle(topic)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Exit") { dismiss() }
                    }
                    if !questions.isEmpty && currentIndex < questions.count {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                appState.toggleBookmark(for: current.id)
                            } label: {
                                Image(systemName: appState.isBookmarked(current.id) ? "star.fill" : "star")
                                    .foregroundStyle(.yellow)
                            }
                        }
                    }
                }
                .onChange(of: currentIndex) { _, _ in logCurrent() }
                .onAppear {
                    questions = buildQuestions()
                    logCurrent()
                }
                .onChange(of: appState.openSATQuestions.count) { _, _ in
                    if currentIndex == 0 && !showExplanation { questions = buildQuestions() }
                }
            }
        }
    }

    private func optionState(_ i: Int) -> OptionButton.State {
        guard showExplanation else { return selectedOption == i ? .selected : .normal }
        if i == current.correctIndex { return .correct }
        if i == selectedOption { return .incorrect }
        return .normal
    }

    private func recordAttempt() {
        let isCorrect = selectedOption == current.correctIndex
        if topic == "Review Session" && isCorrect {
            appState.bookmarkedQuestionIds.remove(current.id)
            appState.persist()
        }
        attempts.append(QuestionAttempt(
            questionId: current.id,
            selectedIndex: selectedOption ?? -1,
            isCorrect: isCorrect,
            timeSpent: Date().timeIntervalSince(startTime)
        ))
        startTime = Date()
    }

    private func buildSession() -> PracticeSession {
        let type = SessionType.practice(topic: topic, subject: subject)
        return PracticeSession(id: UUID(), userId: appState.currentUser.id,
                               date: Date(), attempts: attempts, sessionType: type)
    }

    private func logCurrent() {
        guard !questions.isEmpty, currentIndex < questions.count else { return }
        let q = questions[currentIndex]
        let src = q.aiTopicCategory ?? "hardcoded"
        print("─── Q\(currentIndex+1)/\(questions.count) [\(src)] ───")
        print("TEXT: \(q.text)")
        q.options.enumerated().forEach { i, opt in print("\(["A","B","C","D"][i]): \(opt)") }
        print("CORRECT: \(["A","B","C","D"][q.correctIndex])")
    }
}

// MARK: - Quiz Results

private struct QuizResultsView: View {
    let attempts: [QuestionAttempt]
    let topic: String
    let onDone: () -> Void

    private var score: Int { attempts.filter(\.isCorrect).count }
    private var total: Int { attempts.count }
    private var pct: Double { total == 0 ? 0 : Double(score) / Double(total) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Text(pct >= 0.8 ? "🌟" : pct >= 0.6 ? "👍" : "💪").font(.system(size: 64))
            Text("\(score) / \(total) Correct").font(.title.bold())
            Text(String(format: "%.0f%%", pct * 100))
                .font(.largeTitle.bold())
                .foregroundStyle(pct >= 0.8 ? .green : pct >= 0.6 ? .orange : .red)
            Text(pct >= 0.8 ? "Excellent! You've mastered this topic."
                 : pct >= 0.6 ? "Good work! Keep practicing to improve."
                 : "Keep going — review the explanations and try again.")
                .foregroundStyle(.secondary).multilineTextAlignment(.center).padding(.horizontal, 32)
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(.borderedProminent).controlSize(.large).padding(.horizontal, 32)
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Shared UI Helpers

struct DifficultyBadge: View {
    let difficulty: Difficulty
    var body: some View {
        Text(difficulty.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 8).padding(.vertical, 3)
            .background(Capsule().fill(badgeColor.opacity(0.15)))
            .foregroundStyle(badgeColor)
    }
    private var badgeColor: Color {
        switch difficulty { case .easy: return .green; case .medium: return .orange; case .hard: return .red }
    }
}

struct CircularProgress: View {
    let progress: Double
    let color: Color
    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: 4)
            Circle().trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int(progress * 100))%").font(.system(size: 10).bold()).foregroundStyle(color)
        }
    }
}

