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

// MARK: - Tab 1: Bookmarked Questions
struct BookmarkedQuestionsTab: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedQuestion: Question?
    
    var bookmarkedQuestions: [Question] {
        var seen = Set<UUID>()
        return appState.bookmarkedQuestionIds.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return appState.questionsById[id]
        }
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
                            }
                        }
                    }
                }
            }
            .sheet(item: $selectedQuestion) { question in
                NavigationStack {
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
    
    var uniqueBookmarkedQuestions: [Question] {
        var seen = Set<UUID>()
        return appState.bookmarkedQuestionIds.compactMap { id in
            guard seen.insert(id).inserted else { return nil }
            return appState.questionsById[id]
        }
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
                NavigationLink {
                    TopicBookmarkListView(topic: item.topic)
                        .environmentObject(appState)
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
            }
        }
    }
}

struct TopicBookmarkListView: View {
    let topic: String
    @EnvironmentObject var appState: AppState
    @State private var selectedQuestion: Question?
    
    var questionsInTopic: [Question] {
        var seen = Set<UUID>()
        return appState.bookmarkedQuestionIds.compactMap { id -> Question? in
            guard seen.insert(id).inserted,
                  let q = appState.questionsById[id],
                  q.topic == topic else { return nil }
            return q
        }
    }
    
    var body: some View {
        List {
            ForEach(questionsInTopic) { question in
                Button {
                    selectedQuestion = question
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(question.text.prefix(60))...")
                            .font(.subheadline)
                            .lineLimit(2)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .navigationTitle(topic)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedQuestion) { question in
            NavigationStack {
                BookmarkQuizView(question: question)
                    .environmentObject(appState)
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
    @State private var showReportSheet = false
    @State private var showShareSheet = false
    
    var body: some View {
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
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                // Share question
                Button {
                    showShareSheet = true
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
                // Report question
                Button {
                    showReportSheet = true
                } label: {
                    Image(systemName: "exclamationmark.bubble")
                }
                // Bookmark toggle
                Button {
                    appState.toggleBookmark(for: question.id)
                } label: {
                    Image(systemName: appState.isBookmarked(question.id) ? "star.fill" : "star")
                        .foregroundStyle(.yellow)
                }
            }
        }
        .sheet(isPresented: $showReportSheet) {
            QuestionReportView(question: question)
        }
        .sheet(isPresented: $showShareSheet) {
            let letters = ["A","B","C","D"]
            let optionsText = question.options.enumerated()
                .map { i -> String in
                    let letter = i.offset < letters.count ? letters[i.offset] : "?"
                    return "\(letter). \(i.element)"
                }
                .joined(separator: "\n")
            let shareText = """
            SAT Prep Question (\(question.topic)):

            \(question.text)

            \(optionsText)

            Practice with SAT Prep Bytes – free on the App Store!
            """
            ShareSheet(activityItems: [shareText])
        }
    }
}

struct TestDetailView: View {
    let session: PracticeSession
    @EnvironmentObject var appState: AppState
    
    var questions: [Question] {
        session.attempts.compactMap { appState.questionsById[$0.questionId] }
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
                        NavigationLink {
                            BookmarkQuizView(question: question)
                                        .environmentObject(appState)
                        } label: {
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
