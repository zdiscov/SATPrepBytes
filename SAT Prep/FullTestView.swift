// FullTestView.swift

import SwiftUI

import Combine

struct FullTestView: View {
    @EnvironmentObject var appState: AppState
    @State private var isTestActive = false
    @State private var completedSession: PracticeSession? = nil
    @State private var showPaywall = false

    var body: some View {
        NavigationStack {
            if let session = completedSession {
                TestScoreView(session: session) { completedSession = nil }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "doc.text.fill")
                        .font(.system(size: 72)).foregroundStyle(.blue)
                    Text("Full Practice Test").font(.title.bold())

                    VStack(alignment: .leading, spacing: 10) {
                        TestInfoRow(icon: "timer",              label: "Timed",     value: "Approx. 20 min")
                        TestInfoRow(icon: "questionmark.circle",label: "Questions", value: "20 (Math + EBRW)")
                        TestInfoRow(icon: "chart.bar",          label: "Score",     value: "400–1600 scale")
                        TestInfoRow(icon: "wifi.slash",         label: "Offline",   value: "Fully supported")
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 14)
                        .fill(Color.cardBackground))
                    .padding(.horizontal)

                    Spacer()
                    
                    Button("Start Test") {
                        let testCount = appState.sessions.filter(\.isFullTest).count
                        if testCount >= 1 && !appState.currentUser.isPremium {
                            showPaywall = true
                        } else {
                            isTestActive = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)

                    let testCount = appState.sessions.filter(\.isFullTest).count
                    if testCount > 0 {
                        Text("You've taken \(testCount) test(s)")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 20)
                }
                .navigationTitle("Tests")
                .fullScreenCover(isPresented: $isTestActive) {
                    TimedTestSession { session in
                        appState.recordSession(session)
                        completedSession = session
                        isTestActive = false
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
}

// MARK: - Paywall View

struct PaywallView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 28) {
            HStack {
                Spacer()
                Button { dismiss() } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding([.top, .trailing])

            Image(systemName: "sparkles")
                .font(.system(size: 72))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            VStack(spacing: 8) {
                Text("Unlock SAT Prep Max")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("Get access to all tests and official questions")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 14) {
                PaywallFeatureRow(icon: "doc.text.fill", text: "Unlimited full, timed practice exams")
                PaywallFeatureRow(icon: "checkmark.seal.fill", text: "2,400+ official College Board questions")
                PaywallFeatureRow(icon: "star.fill", text: "Spaced-repetition review of mistakes")
                PaywallFeatureRow(icon: "brain.head.profile", text: "Smart performance analytics & streak metrics")
            }
            .padding(.horizontal, 24)

            Spacer()

            Button {
                var user = appState.currentUser
                user.isPremium = true
                appState.saveUser(user)
                dismiss()
            } label: {
                Text("Upgrade to Max - $9.99")
                    .font(.headline.bold())
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
    }
}

private struct PaywallFeatureRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 28)
            Text(text)
                .font(.body)
                .foregroundStyle(.primary)
            Spacer()
        }
    }
}

// MARK: - Timed Test Session

private struct TimedTestSession: View {
    let onComplete: (PracticeSession) -> Void

    @EnvironmentObject var appState: AppState

    @State private var questions: [Question] = []
    @State private var currentIndex = 0
    @State private var selectedAnswers: [Int: Int] = [:]
    @State private var timeRemaining: Int = 20 * 60
    @State private var showConfirmSubmit = false
    @State private var timerCancellable: AnyCancellable? = nil

    // Time tracking variables
    @State private var questionTimeSpent: [Int: TimeInterval] = [:]
    @State private var currentQuestionStartTime = Date()

    private var current: Question {
        guard !questions.isEmpty, currentIndex < questions.count else {
            return Question(id: UUID(), text: "", options: [], correctIndex: 0, explanation: "", subject: .math, topic: "", difficulty: .easy)
        }
        return questions[currentIndex]
    }

    private func updateTimeSpent() {
        let elapsed = Date().timeIntervalSince(currentQuestionStartTime)
        questionTimeSpent[currentIndex, default: 0] += elapsed
        currentQuestionStartTime = Date()
    }

    private func buildTestQuestions() -> [Question] {
        let attemptedIds = appState.sessions.flatMap { $0.attempts.map(\.questionId) }
        let attemptedSet = Set(attemptedIds)
        
        let mathPool: [Question]
        let ebrwPool: [Question]
        
        if appState.currentUser.isPremium {
            let allMath = appState.allQuestions.filter { $0.subject == .math }
            let allEbrw = appState.allQuestions.filter { $0.subject == .ebrw }
            
            mathPool = allMath.filter { !attemptedSet.contains($0.id) }
            ebrwPool = allEbrw.filter { !attemptedSet.contains($0.id) }
        } else {
            mathPool = QuestionBank.math.filter { !attemptedSet.contains($0.id) }
            ebrwPool = QuestionBank.ebrw.filter { !attemptedSet.contains($0.id) }
        }
        
        let selectedMath = Array(mathPool.shuffled().prefix(10))
        let selectedEbrw = Array(ebrwPool.shuffled().prefix(10))
        
        let fallbackMath = QuestionBank.math
        let fallbackEbrw = QuestionBank.ebrw
        
        let mathResult = selectedMath.count == 10 ? selectedMath : selectedMath + Array(fallbackMath.filter { !selectedMath.map(\.id).contains($0.id) }.shuffled().prefix(10 - selectedMath.count))
        let ebrwResult = selectedEbrw.count == 10 ? selectedEbrw : selectedEbrw + Array(fallbackEbrw.filter { !selectedEbrw.map(\.id).contains($0.id) }.shuffled().prefix(10 - selectedEbrw.count))
        
        return mathResult + ebrwResult
    }

    var body: some View {
        VStack(spacing: 0) {
            if questions.isEmpty {
                ContentUnavailableView("Loading Test...", systemImage: "clock")
            } else {
                // Header
                HStack {
                    TimerDisplay(seconds: timeRemaining)
                    Spacer()
                    Text("\(currentIndex + 1) / \(questions.count)").font(.subheadline)
                    Spacer()
                    // Bookmark button on current question
                    Button {
                        appState.toggleBookmark(for: current.id)
                    } label: {
                        Image(systemName: appState.isBookmarked(current.id) ? "star.fill" : "star")
                            .foregroundStyle(.yellow)
                    }
                    .padding(.trailing, 12)
                    
                    Button("Submit") { showConfirmSubmit = true }
                        .font(.subheadline.bold()).foregroundStyle(.red)
                }
                .padding()
                .background(Color.cardBackground)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label(current.subject.rawValue,
                                  systemImage: current.subject == .math ? "function" : "book")
                                .font(.caption).foregroundStyle(.blue)
                            Spacer()
                            DifficultyBadge(difficulty: current.difficulty)
                        }
                        LaTeXView(current.text, fontSize: 16)
                        ForEach(current.options.indices, id: \.self) { i in
                            OptionButton(
                                label: ["A","B","C","D"][i],
                                text: current.options[i],
                                state: selectedAnswers[currentIndex] == i ? .selected : .normal,
                                isDisabled: false
                            ) { selectedAnswers[currentIndex] = i }
                        }
                    }
                    .padding()
                }

                // Navigation bar
                HStack(spacing: 16) {
                    Button {
                        if currentIndex > 0 {
                            updateTimeSpent()
                            currentIndex -= 1
                        }
                    } label: {
                        HStack { Image(systemName: "chevron.left"); Text("Back") }
                    }
                    .disabled(currentIndex == 0)

                    Spacer()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(questions.indices, id: \.self) { i in
                                Circle()
                                    .fill(dotColor(for: i))
                                    .frame(width: 10, height: 10)
                                    .onTapGesture {
                                        updateTimeSpent()
                                        currentIndex = i
                                    }
                            }
                        }
                    }
                    Spacer()

                    Button {
                        if currentIndex < questions.count - 1 {
                            updateTimeSpent()
                            currentIndex += 1
                        }
                    } label: {
                        HStack { Text("Next"); Image(systemName: "chevron.right") }
                    }
                    .disabled(currentIndex == questions.count - 1)
                }
                .padding()
                .background(Color.cardBackground)
            }
        }
        .onAppear {
            questions = buildTestQuestions()
            currentQuestionStartTime = Date()
            startTimer()
        }
        .alert("Submit Test?", isPresented: $showConfirmSubmit) {
            Button("Submit", role: .destructive) { finishTest() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've answered \(selectedAnswers.count) of \(questions.count) questions.")
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                if timeRemaining > 0 { timeRemaining -= 1 }
                else { finishTest() }
            }
    }

    private func dotColor(for i: Int) -> Color {
        if i == currentIndex { return .blue }
        return selectedAnswers[i] != nil ? .green : Color.cardBackground
    }

    private func finishTest() {
        timerCancellable?.cancel()
        updateTimeSpent()
        let attempts = questions.enumerated().map { i, q in
            let selected = selectedAnswers[i] ?? -1
            let time = questionTimeSpent[i] ?? 0
            return QuestionAttempt(questionId: q.id, selectedIndex: selected,
                                   isCorrect: selected == q.correctIndex, timeSpent: time)
        }
        let session = PracticeSession(id: UUID(), userId: appState.currentUser.id,
                                      date: Date(), attempts: attempts, sessionType: .fullTest)
        onComplete(session)
    }
}

// MARK: - Test Score View

private struct TestScoreView: View {
    let session: PracticeSession
    let onDone: () -> Void

    private var mathAttempts: [QuestionAttempt] {
        let ids = Set(QuestionBank.math.map(\.id))
        return session.attempts.filter { ids.contains($0.questionId) }
    }
    private var ebrwAttempts: [QuestionAttempt] {
        let ids = Set(QuestionBank.ebrw.map(\.id))
        return session.attempts.filter { ids.contains($0.questionId) }
    }
    private func scaledScore(_ attempts: [QuestionAttempt]) -> Int {
        let total = attempts.count, correct = attempts.filter(\.isCorrect).count
        return AppState.scaleScore(correct: correct, total: total, range: 200...800)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Text("Test Complete!").font(.largeTitle.bold()).padding(.top, 32)
                VStack(spacing: 4) {
                    Text("Total Score").font(.headline).foregroundStyle(.secondary)
                    Text("\(scaledScore(mathAttempts) + scaledScore(ebrwAttempts))")
                        .font(.system(size: 72, weight: .bold)).foregroundStyle(.blue)
                    Text("/ 1600").foregroundStyle(.secondary)
                }
                HStack(spacing: 16) {
                    SectionScoreCard(title: "Math",
                                     score: scaledScore(mathAttempts),
                                     correct: mathAttempts.filter(\.isCorrect).count,
                                     total: mathAttempts.count)
                    SectionScoreCard(title: "Reading & Writing",
                                     score: scaledScore(ebrwAttempts),
                                     correct: ebrwAttempts.filter(\.isCorrect).count,
                                     total: ebrwAttempts.count)
                }
                .padding(.horizontal)

                Button("Back to Tests", action: onDone)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 32)
            }
        }
    }
}

private struct SectionScoreCard: View {
    let title: String; let score: Int; let correct: Int; let total: Int
    var body: some View {
        VStack(spacing: 8) {
            Text(title).font(.caption).foregroundStyle(.secondary).multilineTextAlignment(.center)
            Text("\(score)").font(.title.bold())
            Text("\(correct)/\(total)").font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct TimerDisplay: View {
    let seconds: Int
    private var isLow: Bool { seconds < 60 }
    var body: some View {
        Label {
            Text(String(format: "%02d:%02d", seconds / 60, seconds % 60))
                .font(.subheadline.monospacedDigit().bold())
                .foregroundStyle(isLow ? .red : .primary)
        } icon: {
            Image(systemName: "timer").foregroundStyle(isLow ? .red : .orange)
        }
    }
}

private struct TestInfoRow: View {
    let icon: String; let label: String; let value: String
    var body: some View {
        HStack {
            Image(systemName: icon).frame(width: 24).foregroundStyle(.blue)
            Text(label); Spacer()
            Text(value).foregroundStyle(.secondary)
        }
    }
}
