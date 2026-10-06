// AISettingsView.swift – AI feature settings + developer testing menu

import SwiftUI

struct AISettingsView: View {
    @EnvironmentObject var appState: AppState
    @State private var aiService = AIQuestionService.shared
    @State private var showDevMenu = false
    @State private var devTestTopic = MathTopic.algebra.rawValue
    @State private var devTestSubject = Subject.math
    @State private var generatedQuestion: Question? = nil
    @State private var verificationResult: Bool? = nil
    @State private var isVerifying = false

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - AI Status
                Section("Apple Intelligence") {
                    HStack {
                        Image(systemName: aiService.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(aiService.isAvailable ? .green : .red)
                        Text(aiService.isAvailable ? "Available on this device" : "Not available (requires iPhone 15 Pro+ with iOS 18.1+)")
                            .font(.subheadline)
                    }
                }

                // MARK: - Settings
                Section("Settings") {
                    Toggle("Enable AI Questions", isOn: $appState.aiEnabled)
                        .disabled(!aiService.isAvailable)
                    if appState.aiEnabled {
                        Picker("When to show AI questions", selection: $appState.aiTriggerMode) {
                            ForEach(AppState.AITriggerMode.allCases, id: \.self) {
                                Text($0.rawValue).tag($0)
                            }
                        }
                        .pickerStyle(.inline)
                    }
                }

                // MARK: - Accuracy Tracking
                if !appState.aiAccuracyByTopic.isEmpty {
                    Section("AI Accuracy by Topic") {
                        ForEach(appState.aiAccuracyByTopic, id: \.topic) { item in
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(item.topic).font(.subheadline)
                                    Text("\(item.count) question(s) tested").font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(String(format: "%.0f%%", item.accuracy * 100))
                                    .font(.subheadline.bold())
                                    .foregroundStyle(accuracyColor(item.accuracy))
                                Image(systemName: accuracyIcon(item.accuracy))
                                    .foregroundStyle(accuracyColor(item.accuracy))
                            }
                        }
                    }
                }

#if DEBUG
                // MARK: - Premium Status (Developer Testing)
                Section("Premium Subscription Status") {
                    HStack {
                        Text("Current Tier")
                        Spacer()
                        Text(appState.currentUser.isPremium ? "Max Premium 👑" : "Free Tier")
                            .foregroundStyle(appState.currentUser.isPremium ? .purple : .secondary)
                            .bold()
                    }
                    Button(appState.currentUser.isPremium ? "Simulate Free Tier (dev only)" : "Simulate Premium Tier (dev only)") {
                        var user = appState.currentUser
                        user.isPremium.toggle()
                        appState.saveUser(user)
                    }
                    .foregroundStyle(.orange)
                    Text("Paywall is currently \(FeatureFlags.paywallEnabled ? "ENABLED" : "DISABLED") globally via FeatureFlags.")
                        .font(.caption).foregroundStyle(.secondary)
                }

                // MARK: - Debug: Review Prompt
                Section {
                    let eligible = appState.shouldPromptForReview
                    HStack {
                        Text("Review Prompt Eligible")
                        Spacer()
                        Text(eligible ? "✅ Yes" : "❌ No")
                            .foregroundStyle(eligible ? .green : .secondary)
                            .font(.subheadline.bold())
                    }
                    Button("🔄 Reset Prompt History (Test Mode)") {
                        appState.debugForceReviewEligible()
                    }
                    .foregroundStyle(.orange)
                } header: {
                    Text("App Store Review Prompt")
                } footer: {
                    Text("Resets the prompt date history so the prompt can fire again on next Dashboard load. In production the prompt shows max 3× per year, ≥60 days apart.")
                }

                // MARK: - Developer Menu
                Section {
                    Button("🛠 Developer Testing Menu") { showDevMenu = true }
                        .foregroundStyle(.blue)
                } footer: {
                    Text("Test AI question generation without waiting to exhaust the question bank.")
                }
#endif
            }
            .navigationTitle("AI Features")
#if DEBUG
            .sheet(isPresented: $showDevMenu) {
                DevTestingMenu(
                    topic: $devTestTopic,
                    subject: $devTestSubject,
                    generatedQuestion: $generatedQuestion,
                    verificationResult: $verificationResult,
                    isVerifying: $isVerifying
                )
                .environmentObject(appState)
            }
#endif
        }
    }

    private func accuracyColor(_ acc: Double) -> Color {
        acc >= 0.85 ? .green : acc >= 0.65 ? .orange : .red
    }
    private func accuracyIcon(_ acc: Double) -> String {
        acc >= 0.85 ? "checkmark.seal.fill" : acc >= 0.65 ? "exclamationmark.triangle.fill" : "xmark.seal.fill"
    }
}

// MARK: - Developer Testing Menu

struct DevTestingMenu: View {
    @Binding var topic: String
    @Binding var subject: Subject
    @Binding var generatedQuestion: Question?
    @Binding var verificationResult: Bool?
    @Binding var isVerifying: Bool

    @EnvironmentObject var appState: AppState
    @State private var aiService = AIQuestionService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var useDevMock = false
    @State private var selectedDifficulty = Difficulty.medium
    @State private var searchQuery = ""
    @State private var inspectedQuestion: Question?

    private var allTopics: [(String, Subject)] {
        MathTopic.allCases.map { ($0.rawValue, Subject.math) } +
        EBRWTopic.allCases.map { ($0.rawValue, Subject.ebrw) }
    }

    private var matchingQuestions: [Question] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else { return [] }
        let query = searchQuery.lowercased()
        return appState.allQuestions.filter {
            $0.id.uuidString.lowercased().contains(query) ||
            $0.text.lowercased().contains(query) ||
            $0.topic.lowercased().contains(query)
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Search Question Bank / Inspector") {
                    TextField("Search text, topic, or ID (e.g. basketball)...", text: $searchQuery)
                    if !searchQuery.isEmpty {
                        let matches = matchingQuestions
                        if matches.isEmpty {
                            Text("No questions found matching '\(searchQuery)'").font(.caption).foregroundStyle(.secondary)
                        } else {
                            ForEach(matches.prefix(5)) { q in
                                Button {
                                    inspectedQuestion = q
                                } label: {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(q.text)
                                            .lineLimit(2)
                                            .font(.subheadline)
                                            .foregroundStyle(.primary)
                                        HStack {
                                            Text(q.topic)
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                            Spacer()
                                            Text("Ans: \(q.correctAnswer)")
                                                .font(.caption2.bold())
                                                .foregroundStyle(.green)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Section("Generate Test Question") {
                    Picker("Topic", selection: $topic) {
                        ForEach(allTopics, id: \.0) { t in
                            Text(t.0).tag(t.0)
                        }
                    }
                    Picker("Difficulty", selection: $selectedDifficulty) {
                        ForEach(Difficulty.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    Toggle("Use Dev Mock (no AI needed)", isOn: $useDevMock)
                        .tint(.orange)

                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            if aiService.isGenerating {
                                ProgressView().scaleEffect(0.8)
                            }
                            Text(useDevMock ? "Generate Mock Question" : "Generate AI Question")
                        }
                    }
                    .disabled(aiService.isGenerating)
                }

                if let q = generatedQuestion {
                    Section("Generated Question") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack(spacing: 4) {
                                if q.isAIGenerated {
                                    Label(q.aiTopicCategory == "experimental" ? "⚗️ Experimental" : "🤖 AI Generated",
                                          systemImage: "sparkles")
                                        .font(.caption).foregroundStyle(.purple)
                                }
                                // Inline validation result
                                let validationError = AIQuestionService.shared.validate(q)
                                if let err = validationError {
                                    Label("⚠️ \(err)", systemImage: "exclamationmark.triangle.fill")
                                        .font(.caption).foregroundStyle(.red)
                                } else {
                                    Label("✅ Passes validation", systemImage: "checkmark.circle.fill")
                                        .font(.caption).foregroundStyle(.green)
                                }
                            }
                            Text(q.text).font(.body)
                            ForEach(q.options.indices, id: \.self) { i in
                                HStack {
                                    Text(["A","B","C","D"][i]).bold()
                                    Text(q.options[i])
                                    if i == q.correctIndex {
                                        Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                                    }
                                }
                                .font(.subheadline)
                            }
                            Text("Explanation: \(q.explanation)")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Section("Verify Answer with AI") {
                        Button {
                            Task { await verify(q) }
                        } label: {
                            HStack {
                                if isVerifying { ProgressView().scaleEffect(0.8) }
                                Text("Run AI Verification")
                            }
                        }
                        .disabled(isVerifying || useDevMock)

                        if let result = verificationResult {
                            HStack {
                                Image(systemName: result ? "checkmark.seal.fill" : "xmark.seal.fill")
                                    .foregroundStyle(result ? .green : .red)
                                Text(result ? "AI agrees with its own answer ✅" : "AI DISAGREES — question would be rejected ⚠️")
                                    .font(.subheadline)
                            }
                        } else if !isVerifying && generatedQuestion != nil {
                            HStack {
                                Image(systemName: "questionmark.circle.fill").foregroundStyle(.orange)
                                Text("Verification inconclusive — ANSWER: not found in response. Question would be rejected.")
                                    .font(.subheadline).foregroundStyle(.orange)
                            }
                        }
                        if useDevMock {
                            Text("Verification disabled in mock mode").font(.caption).foregroundStyle(.secondary)
                        }
                    }

                    Section("Log Feedback") {
                        Button("Record as Tested (agreed)") {
                            recordFeedback(question: q, agreed: true)
                        }
                        Button("Record as Tested (disagreed)") {
                            recordFeedback(question: q, agreed: false)
                        }
                        .foregroundStyle(.orange)
                    }
                }

                if let err = aiService.lastError {
                    Section("Last Error") {
                        Text(err).font(.caption).foregroundStyle(.red)
                    }
                }
            }
            .navigationTitle("🛠 Dev: AI Testing")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $inspectedQuestion) { q in
                QuestionInspectorView(question: q)
            }
        }
    }

    private func generate() async {
        verificationResult = nil
        // Determine subject from topic
        let matchedSubject = MathTopic.allCases.map(\.rawValue).contains(topic) ? Subject.math : Subject.ebrw
        subject = matchedSubject

        if useDevMock {
            generatedQuestion = AIQuestionService.shared.mockQuestion(topic: topic, subject: matchedSubject)
        } else {
            generatedQuestion = await AIQuestionService.shared.generateQuestion(
                topic: topic, subject: matchedSubject, difficulty: selectedDifficulty
            )
        }
    }

    private func verify(_ question: Question) async {
        isVerifying = true
        verificationResult = await AIQuestionService.shared.verifyAnswer(question: question)
        isVerifying = false
    }

    private func recordFeedback(question: Question, agreed: Bool) {
        let feedback = AIQuestionFeedback(
            id: UUID(), topic: question.topic, subject: question.subject,
            date: Date(), aiAnswerIndex: question.correctIndex,
            userAnswerIndex: question.correctIndex,
            verificationAgreed: agreed, hardcodedAnswerIndex: -1
        )
        appState.recordAIFeedback(feedback)
    }
}
