import SwiftUI

struct LazyView<Content: View>: View {
    let build: () -> Content
    init(_ build: @autoclosure @escaping () -> Content) {
        self.build = build
    }
    var body: Content {
        build()
    }
}

/// Simplified 3-Tab Review System - Just Bookmarks
struct BookmarkReviewView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: ReviewTab = .bookmarked
    
    enum ReviewTab {
        case bookmarked
        case byTopic
        case history
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                // Tab Picker
                Picker("Review Type", selection: $selectedTab) {
                    Label("\(appState.bookmarkedQuestionIds.count) Bookmarked", systemImage: "star.fill")
                        .tag(ReviewTab.bookmarked)
                    Label("By Topic", systemImage: "list.bullet")
                        .tag(ReviewTab.byTopic)
                    Label("Sessions", systemImage: "clock.fill")
                        .tag(ReviewTab.history)
                }
                .pickerStyle(.segmented)
                .padding()
                
                // Content
                Group {
                    switch selectedTab {
                    case .bookmarked:
                        BookmarkedQuestionsTab()
                    case .byTopic:
                        BookmarksByTopicTab()
                    case .history:
                        SessionHistoryTab()
                    }
                }
                .environmentObject(appState)
            }
            .navigationTitle("Review")
        }
    }
}

// MARK: - Tab 1: Bookmarked Questions
struct BookmarkedQuestionsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedQuestion: Question?
    @State private var showQuiz = false
    
    var bookmarkedQuestions: [Question] {
        let allFiltered = appState.allQuestions.filter { appState.bookmarkedQuestionIds.contains($0.id) }
        var seen = Set<UUID>()
        return allFiltered.filter { seen.insert($0.id).inserted }
    }
    
    var groupedByTopic: [String: [Question]] {
        Dictionary(grouping: bookmarkedQuestions) { $0.topic }
    }
    
    var body: some View {
        if bookmarkedQuestions.isEmpty {
            ContentUnavailableView(
                "No Bookmarks",
                systemImage: "star.slash",
                description: Text("Questions you bookmark will appear here for review.")
            )
        } else {
            List {
                ForEach(groupedByTopic.keys.sorted(), id: \.self) { topic in
                    Section(topic) {
                        ForEach(groupedByTopic[topic] ?? []) { question in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("\(question.text.prefix(50))...")
                                        .font(.subheadline)
                                        .lineLimit(2)
                                    Text(question.subject.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    appState.toggleBookmark(for: question.id)
                                }) {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                                .buttonStyle(.plain)
                            }
                            .contentShape(Rectangle())
                            .onTapGesture {
                                selectedQuestion = question
                                showQuiz = true
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showQuiz) {
                if let question = selectedQuestion {
                    BookmarkQuizView(question: question)
                        .environmentObject(appState)
                }
            }
        }
    }
}

// MARK: - Tab 2: Bookmarks by Topic
struct BookmarksByTopicTab: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTopic: String?
    @State private var showQuiz = false
    
    var uniqueBookmarkedQuestions: [Question] {
        let allFiltered = appState.allQuestions.filter { appState.bookmarkedQuestionIds.contains($0.id) }
        var seen = Set<UUID>()
        return allFiltered.filter { seen.insert($0.id).inserted }
    }
    
    var bookmarksByTopic: [(topic: String, count: Int)] {
        let grouped = Dictionary(grouping: uniqueBookmarkedQuestions) { $0.topic }
        return grouped.map { (topic: $0.key, count: $0.value.count) }
            .sorted { $0.count > $1.count }
    }
    
    var body: some View {
        if bookmarksByTopic.isEmpty {
            ContentUnavailableView(
                "No Bookmarks Yet",
                systemImage: "star.slash",
                description: Text("Star questions while practicing to review them later.")
            )
        } else {
            List(bookmarksByTopic, id: \.topic) { item in
                Button {
                    selectedTopic = item.topic
                    showQuiz = true
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(item.topic)
                                .font(.headline)
                        }
                        Spacer()
                        Badge(item.count)
                    }
                }
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showQuiz) {
                if let topic = selectedTopic {
                    NavigationStack {
                        List {
                            ForEach(uniqueBookmarkedQuestions.filter { $0.topic == topic }) { question in
                                NavigationLink(destination: LazyView(BookmarkQuizView(question: question).environmentObject(appState))) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(question.text.prefix(60))...")
                                            .font(.subheadline)
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                        .navigationTitle(topic)
                        .toolbar {
                            ToolbarItem(placement: .cancellationAction) {
                                Button("Done") { showQuiz = false }
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Tab 3: Session History
struct SessionHistoryTab: View {
    @EnvironmentObject var appState: AppState
    
    var fullTests: [PracticeSession] {
        appState.sessions.filter { session in
            if case .fullTest = session.sessionType { return true }
            return false
        }
    }
    
    var body: some View {
        if fullTests.isEmpty {
            ContentUnavailableView(
                "No Tests Yet",
                systemImage: "clock.fill",
                description: Text("Take a full test to review your performance.")
            )
        } else {
            List {
                ForEach(fullTests.sorted { $0.date > $1.date }) { session in
                    let correct = session.attempts.filter(\.isCorrect).count
                    let total = session.attempts.count
                    let pct = total == 0 ? 0 : Double(correct) / Double(total)
                    
                    NavigationLink(destination: TestDetailView(session: session)) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                    .font(.headline)
                                Text("\(correct)/\(total) Correct")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text(String(format: "%.0f%%", pct * 100))
                                .font(.title3.bold())
                                .foregroundStyle(pct >= 0.8 ? .green : pct >= 0.6 ? .orange : .red)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct BookmarkQuizView: View {
    let question: Question
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedOption: Int?
    @State private var showExplanation = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        LaTeXView(question.text, fontSize: 16)
                            .frame(minHeight: 100)
                        
                        ForEach(question.options.indices, id: \.self) { i in
                            OptionButton(
                                label: ["A","B","C","D"][i],
                                text: question.options[i],
                                state: selectedOption == i ? .selected : 
                                       (selectedOption != nil && i == question.correctIndex ? .correct : .normal),
                                isDisabled: showExplanation
                            ) {
                                selectedOption = i
                                showExplanation = true
                            }
                        }
                        
                        if showExplanation {
                            ExplanationCard(
                                isCorrect: selectedOption == question.correctIndex,
                                explanation: question.explanation
                            )
                        }
                    }
                    .padding()
                }
                
                Button("Done", action: { dismiss() })
                    .buttonStyle(.borderedProminent)
                    .padding()
            }
            .navigationTitle("Review Question")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct TestDetailView: View {
    let session: PracticeSession
    @EnvironmentObject var appState: AppState
    
    var questions: [Question] {
        let ids = Set(session.attempts.map { $0.questionId })
        return appState.allQuestions.filter { ids.contains($0.id) }
    }
    
    var body: some View {
        List {
            Section("Test Details") {
                let correct = session.attempts.filter(\.isCorrect).count
                HStack {
                    Text("Score")
                    Spacer()
                    Text("\(correct)/\(session.attempts.count)")
                        .bold()
                }
                
                HStack {
                    Text("Date")
                    Spacer()
                    Text(session.date.formatted())
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Questions") {
                ForEach(questions) { question in
                    if let attempt = session.attempts.first(where: { $0.questionId == question.id }) {
                        NavigationLink(destination: LazyView(BookmarkQuizView(question: question).environmentObject(appState))) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(question.text.prefix(60))...")
                                    .font(.subheadline)
                                    .lineLimit(2)
                                
                                HStack {
                                    Text(attempt.isCorrect ? "✓ Correct" : "✗ Wrong")
                                        .font(.caption)
                                        .foregroundStyle(attempt.isCorrect ? .green : .red)
                                    
                                    Spacer()
                                    
                                    Text(question.subject.rawValue)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Test Review")
    }
}

// MARK: - UI Components

struct Badge: View {
    let count: Int
    
    init(_ count: Int) {
        self.count = count
    }
    
    var body: some View {
        Text("\(count)")
            .font(.caption.bold())
            .foregroundStyle(.white)
            .frame(minWidth: 24, minHeight: 24)
            .background(Circle().fill(.blue))
    }
}

#Preview {
    BookmarkReviewView()
        .environmentObject(AppState())
}
