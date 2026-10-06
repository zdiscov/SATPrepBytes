// OnboardingView.swift – Signup, profile setup, and diagnostic

import SwiftUI

// MARK: - Onboarding Container

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var step: OnboardingStep = .welcome

    enum OnboardingStep { case welcome, profile, diagnostic }

    var body: some View {
        switch step {
        case .welcome:
            WelcomeScreen { step = .profile }
        case .profile:
            ProfileSetupScreen { user in
                appState.saveUser(user)
                step = .diagnostic
            }
        case .diagnostic:
            DiagnosticScreen { sessions in
                for s in sessions { appState.recordSession(s) }
                var user = appState.currentUser
                user.hasCompletedDiagnostic = true
                user.hasCompletedOnboarding = true
                appState.saveUser(user)
                appState.generateStudyPlan()
            }
        }
    }
}

// MARK: - Welcome Screen

private struct WelcomeScreen: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 80))
                .foregroundStyle(.blue)
            Text("SAT Prep")
                .font(.largeTitle.bold())
            Text("Personalized practice, adaptive study plans, and real SAT-format questions.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button(action: onContinue) {
                Text("Get Started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 32)
            Text("Free core content · No ads")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Profile Setup Screen

private struct ProfileSetupScreen: View {
    let onContinue: (User) -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var grade = 11
    @State private var targetScore = 1200
    @State private var testDate = Calendar.current.date(byAdding: .month, value: 3, to: Date())!
    @State private var showError = false

    var body: some View {
        NavigationStack {
            Form {
                Section("About You") {
                    TextField("Your Name", text: $name)
                        .textContentType(.name)
                    TextField("Email (optional)", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                }
                Section("Academic Info") {
                    Picker("Grade", selection: $grade) {
                        ForEach(9...12, id: \.self) { Text("Grade \($0)").tag($0) }
                    }
                    VStack(alignment: .leading) {
                        Text("Target Score: \(targetScore)")
                        Slider(value: Binding(
                            get: { Double(targetScore) },
                            set: { targetScore = (Int($0) / 10) * 10 }
                        ), in: 400...1600, step: 10)
                        HStack { Text("400").font(.caption); Spacer(); Text("1600").font(.caption) }
                            .foregroundStyle(.secondary)
                    }
                    DatePicker("Test Date", selection: $testDate, displayedComponents: .date)
                }
            }
            .navigationTitle("Set Up Your Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Next") {
                        guard !name.isEmpty else { showError = true; return }
                        var user = User.empty
                        user.name = name
                        user.email = email
                        user.grade = grade
                        user.targetScore = targetScore
                        user.testDate = testDate
                        onContinue(user)
                    }
                }
            }
            .alert("Please enter your name.", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            }
        }
    }
}

// MARK: - Diagnostic Screen

struct DiagnosticScreen: View {
    let onComplete: ([PracticeSession]) -> Void

    @EnvironmentObject var appState: AppState
    @State private var questions: [Question] = QuestionBank.diagnosticSet()
    @State private var currentIndex = 0
    @State private var selectedOption: Int? = nil
    @State private var attempts: [QuestionAttempt] = []
    @State private var showExplanation = false
    @State private var isComplete = false

    private var current: Question { questions[currentIndex] }
    private var progress: Double { Double(currentIndex) / Double(questions.count) }

    var body: some View {
        NavigationStack {
            if isComplete {
                DiagnosticResultsView(attempts: attempts, questions: questions) {
                    let session = PracticeSession(
                        id: UUID(), userId: appState.currentUser.id, date: Date(),
                        attempts: attempts, sessionType: .practice(topic: "Diagnostic", subject: .math)
                    )
                    onComplete([session])
                }
            } else {
                VStack(spacing: 0) {
                    ProgressView(value: progress)
                        .padding()
                    Text("Question \(currentIndex + 1) of \(questions.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label(current.subject.rawValue, systemImage: current.subject == .math ? "function" : "book")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Spacer()
                                Text(current.difficulty.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(difficultyColor(current.difficulty))
                            }

                            LaTeXView(current.text, fontSize: 16)

                            ForEach(current.options.indices, id: \.self) { i in
                                OptionButton(
                                    label: optionLabel(i), text: current.options[i],
                                    state: optionState(i),
                                    isDisabled: showExplanation
                                ) {
                                    guard !showExplanation else { return }
                                    selectedOption = i
                                }
                            }

                            if showExplanation {
                                ExplanationCard(
                                    isCorrect: selectedOption == current.correctIndex,
                                    explanation: current.explanation
                                )
                            }
                        }
                        .padding()
                    }

                    Spacer()
                    VStack(spacing: 12) {
                        if !showExplanation {
                            Button("Check Answer") {
                                showExplanation = true
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(selectedOption == nil)
                            .frame(maxWidth: .infinity)
                        } else {
                            Button(currentIndex + 1 < questions.count ? "Next Question" : "See Results") {
                                let attempt = QuestionAttempt(
                                    questionId: current.id,
                                    selectedIndex: selectedOption ?? -1,
                                    isCorrect: selectedOption == current.correctIndex,
                                    timeSpent: 0
                                )
                                attempts.append(attempt)
                                if currentIndex + 1 < questions.count {
                                    currentIndex += 1
                                    selectedOption = nil
                                    showExplanation = false
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
                .navigationTitle("Diagnostic Test")
            }
        }
    }

    private func optionLabel(_ i: Int) -> String { ["A", "B", "C", "D"][i] }

    private func optionState(_ i: Int) -> OptionButton.State {
        guard showExplanation else {
            return selectedOption == i ? .selected : .normal
        }
        if i == current.correctIndex { return .correct }
        if i == selectedOption { return .incorrect }
        return .normal
    }

    private func difficultyColor(_ d: Difficulty) -> Color {
        switch d {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
}

// MARK: - Diagnostic Results

private struct DiagnosticResultsView: View {
    let attempts: [QuestionAttempt]
    let questions: [Question]
    let onContinue: () -> Void

    private var score: Int { attempts.filter(\.isCorrect).count }
    private var total: Int { attempts.count }
    private var pct: Double { Double(score) / Double(total) }

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: pct >= 0.7 ? "star.fill" : "chart.bar.fill")
                .font(.system(size: 60))
                .foregroundStyle(.yellow)
            Text("Diagnostic Complete!")
                .font(.title.bold())
            Text("\(score) / \(total) correct")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("We've identified your strengths and weaknesses. Your personalized study plan is ready.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)
            Spacer()
            Button("Start My Study Plan", action: onContinue)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal, 32)
            Spacer(minLength: 20)
        }
    }
}

// MARK: - Shared UI Components

struct OptionButton: View {
    enum State { case normal, selected, correct, incorrect }
    let label: String
    let text: String
    let state: State
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(label)
                    .font(.headline)
                    .frame(width: 28, height: 28)
                    .background(labelBackground)
                    .foregroundStyle(labelForeground)
                    .clipShape(Circle())
                if text.contains("<") || text.contains("$") {
                    LaTeXView(text, fontSize: 15)
                } else {
                    Text(text.strippingLatex)
                        .multilineTextAlignment(.leading)
                        .foregroundStyle(.primary)
                    Spacer()
                }
                if state == .correct { Image(systemName: "checkmark.circle.fill").foregroundStyle(.green) }
                if state == .incorrect { Image(systemName: "xmark.circle.fill").foregroundStyle(.red) }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(background))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(borderColor, lineWidth: 1.5))
        }
        .disabled(isDisabled)
    }

    private var background: Color {
        switch state {
        case .normal: return Color.cardBackground
        case .selected: return .blue.opacity(0.1)
        case .correct: return .green.opacity(0.1)
        case .incorrect: return .red.opacity(0.1)
        }
    }
    private var borderColor: Color {
        switch state {
        case .normal: return .clear
        case .selected: return .blue
        case .correct: return .green
        case .incorrect: return .red
        }
    }
    private var labelBackground: Color {
        switch state {
        case .selected: return .blue
        case .correct: return .green
        case .incorrect: return .red
        default: return Color.cardBackground
        }
    }
    private var labelForeground: Color {
        state == .normal ? .primary : .white
    }
}

struct ExplanationCard: View {
    let isCorrect: Bool
    let explanation: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(isCorrect ? .green : .red)
                Text(isCorrect ? "Correct!" : "Incorrect")
                    .font(.headline)
            }
            LaTeXView(explanation, fontSize: 15)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 12).fill(Color.cardBackground))
    }
}
