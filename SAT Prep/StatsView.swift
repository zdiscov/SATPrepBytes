// StatsView.swift

import SwiftUI
import Charts

struct StatsView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 12) {
                        SummaryCard(title: "Sessions",  value: "\(appState.sessions.count)",
                                    icon: "pencil.circle.fill",       color: .blue)
                        SummaryCard(title: "Questions", value: "\(totalQuestions)",
                                    icon: "questionmark.circle.fill", color: .purple)
                        SummaryCard(title: "Accuracy",  value: "\(accuracyPct)%",
                                    icon: "target",                   color: .green)
                    }
                    .padding(.horizontal)

                    if !scoreTrend.isEmpty {
                        ScoreTrendChart(data: scoreTrend).padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Topic Proficiency").font(.headline).padding(.horizontal)
                        let topics = QuestionBank.allTopics
                        let withData = topics.filter { appState.proficiency(for: $0.topic) > 0 }
                        if withData.isEmpty {
                            EmptyStateCard(icon: "chart.bar", title: "No data yet",
                                           subtitle: "Complete practice sessions to see your topic breakdown.")
                                .padding(.horizontal)
                        } else {
                            ForEach(withData, id: \.topic) { pair in
                                TopicProficiencyRow(topic: pair.topic, subject: pair.subject,
                                                    proficiency: appState.proficiency(for: pair.topic))
                                    .padding(.horizontal)
                            }
                        }
                    }

                    let recent = appState.recentSessions(limit: 10)
                    if !recent.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Session History").font(.headline).padding(.horizontal)
                            ForEach(recent) { SessionHistoryRow(session: $0).padding(.horizontal) }
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Progress")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: AISettingsView()) {
                        Label("AI Features", systemImage: "sparkles")
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if appState.openSATLoaded {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.blue)
                        Text("\(appState.openSATQuestions.count) Official CB questions loaded")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                    .padding(.horizontal).padding(.bottom, 8)
                } else {
                    HStack {
                        ProgressView().scaleEffect(0.7)
                        Text("Loading official questions…").font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 8)
                }
            }
        }
    }

    private var totalQuestions: Int { appState.sessions.flatMap(\.attempts).count }

    private var accuracyPct: Int {
        let all = appState.sessions.flatMap(\.attempts)
        guard !all.isEmpty else { return 0 }
        return Int(Double(all.filter(\.isCorrect).count) / Double(all.count) * 100)
    }

    private var scoreTrend: [(date: Date, score: Int)] {
        appState.sessions.filter(\.isFullTest).sorted { $0.date < $1.date }.map { s in
            let total = s.attempts.count, correct = s.attempts.filter(\.isCorrect).count
            return (s.date, AppState.scaleScore(correct: correct, total: total, range: 400...1600))
        }
    }
}

// MARK: - Chart

private struct ScoreTrendChart: View {
    let data: [(date: Date, score: Int)]
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Score Trend (Full Tests)").font(.headline)
            Chart(data.indices, id: \.self) { i in
                LineMark(x: .value("Date", data[i].date), y: .value("Score", data[i].score))
                    .foregroundStyle(.blue)
                PointMark(x: .value("Date", data[i].date), y: .value("Score", data[i].score))
                    .foregroundStyle(.blue)
            }
            .chartYScale(domain: 400...1600)
            .frame(height: 160)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

// MARK: - Sub-components

private struct SummaryCard: View {
    let title: String; let value: String; let icon: String; let color: Color
    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct TopicProficiencyRow: View {
    let topic: String; let subject: Subject; let proficiency: Double
    private var color: Color { proficiency >= 0.7 ? .green : proficiency >= 0.4 ? .orange : .red }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(topic).font(.subheadline)
                Spacer()
                Text(String(format: "%.0f%%", proficiency * 100))
                    .font(.subheadline.bold()).foregroundStyle(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4).fill(Color.cardBackground).frame(height: 8)
                    RoundedRectangle(cornerRadius: 4).fill(color)
                        .frame(width: geo.size.width * proficiency, height: 8)
                }
            }
            .frame(height: 8)
        }
        .padding(.vertical, 4)
    }
}

private struct SessionHistoryRow: View {
    let session: PracticeSession
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: session.isFullTest ? "doc.text.fill" : "pencil.circle.fill")
                .foregroundStyle(session.subject == .math ? .blue : .green).frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.topic).font(.subheadline.bold())
                Text(session.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(session.score)/\(session.total)")
                    .font(.subheadline.bold())
                    .foregroundStyle(session.percentCorrect >= 70 ? .green : .orange)
                Text(String(format: "%.0f%%", session.percentCorrect))
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
