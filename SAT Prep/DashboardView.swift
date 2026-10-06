// DashboardView.swift

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var appState: AppState
    @State private var activeQuiz: PracticeView.QuizConfig? = nil
    
    // Interactive sheet triggers
    @State private var showStreakSheet = false
    @State private var showScoreSheet = false
    @State private var showTargetSheet = false
    @State private var showPaywall = false

    private var motivationalMessage: (title: String, subtitle: String) {
        let streak = appState.currentUser.streakDays
        let estScore = appState.estimatedScore
        let target = appState.currentUser.targetScore
        
        if estScore >= target {
            return ("Target Achieved! 🏆", "You've reached your target of \(target). Keep practicing to maintain your edge!")
        }
        
        if streak > 0 {
            if streak >= 7 {
                return ("🔥 \(streak)-Day Streak!", "Fantastic discipline! You are charging toward your target of \(target).")
            } else {
                return ("Keep it up! 🔥", "You're on a \(streak)-day streak. Practice today to keep it alive!")
            }
        } else {
            if estScore > 400 {
                return ("Ready to study? 📚", "Your estimated score is \(estScore). Let's do a quick drill to reach \(target)!")
            } else {
                return ("Welcome to SAT Prep! 🚀", "Let's start by doing a practice drill or taking a full test.")
            }
        }
    }

    private var daysUntilSAT: Int? {
        guard let testDate = appState.currentUser.testDate else { return nil }
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let startOfTestDate = calendar.startOfDay(for: testDate)
        let components = calendar.dateComponents([.day], from: startOfToday, to: startOfTestDate)
        return components.day
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Welcome & Dynamic Motivation
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Hi, \(appState.currentUser.name.isEmpty ? "Student" : appState.currentUser.name) 👋")
                            .font(.title2.bold())
                        let msg = motivationalMessage
                        Text(msg.title)
                            .font(.headline)
                            .foregroundStyle(.blue)
                        Text(msg.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)

                    // Countdown Banner
                    if let days = daysUntilSAT {
                        HStack(spacing: 12) {
                            Image(systemName: "calendar")
                                .font(.title)
                                .foregroundStyle(.purple)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.purple.opacity(0.12)))
                            
                            VStack(alignment: .leading, spacing: 2) {
                                if days > 0 {
                                    Text("\(days) days until your SAT")
                                        .font(.subheadline.bold())
                                    Text(appState.currentUser.testDate?.formatted(date: .long, time: .omitted) ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else if days == 0 {
                                    Text("Today is SAT Day! 🎯")
                                        .font(.subheadline.bold())
                                    Text("Good luck, you've got this!")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                } else {
                                    Text("SAT Completed! 🎉")
                                        .font(.subheadline.bold())
                                    Text("Excellent job finishing your prep.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
                        .padding(.horizontal)
                        .onTapGesture {
                            showTargetSheet = true
                        }
                    }

                    // Premium Upgrade Card
                    if !appState.currentUser.isPremium {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Upgrade to SAT Prep Max 🚀")
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.white)
                                    Text("Unlock 1,200+ mock questions, unlimited timed practice tests, and weak-topic study plans.")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.85))
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundStyle(.white)
                            }
                            .padding()
                            .background(
                                LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }

                    // Stat Cards Row
                    HStack(spacing: 12) {
                        Button {
                            showStreakSheet = true
                        } label: {
                            StatCard(title: "Day Streak", value: "\(appState.currentUser.streakDays)",
                                     icon: "flame.fill", color: .orange)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showScoreSheet = true
                        } label: {
                            StatCard(title: "Est. Score", value: "\(appState.estimatedScore)",
                                     icon: "star.fill", color: .blue)
                        }
                        .buttonStyle(.plain)

                        Button {
                            showTargetSheet = true
                        } label: {
                            StatCard(title: "Target", value: "\(appState.currentUser.targetScore)",
                                     icon: "target", color: .green)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)

                    // Recommendation Card
                    if let weakest = appState.weakestTopics(limit: 1).first {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recommended Next Study").font(.headline)
                            HStack(spacing: 12) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(weakest.topic)
                                        .font(.subheadline.bold())
                                    Text("Strengthen your weakest area to boost your score.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button("Start Drill") {
                                    activeQuiz = PracticeView.QuizConfig(topic: weakest.topic, subject: weakest.subject)
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.blue.opacity(0.08)))
                        }
                        .padding(.horizontal)
                    }

                    ScoreProgressBar(current: appState.estimatedScore,
                                     target: appState.currentUser.targetScore)
                        .padding(.horizontal)
                        .onTapGesture {
                            showScoreSheet = true
                        }

                    if let plan = appState.studyPlan, !plan.milestones.isEmpty {
                        StudyPlanCard(plan: plan).padding(.horizontal)
                    }

                    let recent = appState.recentSessions(limit: 5)
                    if !recent.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Recent Sessions").font(.headline)
                            ForEach(recent) { SessionRow(session: $0) }
                        }
                        .padding(.horizontal)
                    } else {
                        EmptyStateCard(icon: "pencil.circle", title: "No sessions yet",
                                       subtitle: "Head to Practice to start your first quiz!")
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Dashboard")
            .sheet(item: $activeQuiz) { config in
                QuizView(topic: config.topic, subject: config.subject, appState: appState) { session in
                    appState.recordSession(session)
                }
                .environmentObject(appState)
            }
            .sheet(isPresented: $showStreakSheet) {
                StreakCalendarSheet()
                    .environmentObject(appState)
                    .presentationDetents([.fraction(0.4)])
            }
            .sheet(isPresented: $showScoreSheet) {
                ScoreBreakdownSheet()
                    .environmentObject(appState)
                    .presentationDetents([.medium])
            }
            .sheet(isPresented: $showTargetSheet) {
                TargetPickerSheet(initialScore: appState.currentUser.targetScore, initialDate: appState.currentUser.testDate)
                    .environmentObject(appState)
                    .presentationDetents([.medium, .large])
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
                    .environmentObject(appState)
            }
        }
    }
}

// MARK: - Sub-Components

private struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon).font(.title2).foregroundStyle(color)
            Text(value).font(.title.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct ScoreProgressBar: View {
    let current: Int
    let target: Int

    private var progress: Double {
        guard target > 400 else { return 0 }
        return min(max(Double(current - 400) / Double(target - 400), 0), 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("Score Progress").font(.headline)
                Spacer()
                Text("\(current) → \(target)").font(.caption).foregroundStyle(.secondary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.cardBackground)
                        .frame(height: 14)
                    RoundedRectangle(cornerRadius: 8)
                        .fill(LinearGradient(colors: [.blue, .purple],
                                             startPoint: .leading, endPoint: .trailing))
                        .frame(width: geo.size.width * progress, height: 14)
                }
            }
            .frame(height: 14)
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct StudyPlanCard: View {
    let plan: StudyPlan
    private var upcoming: [StudyMilestone] {
        plan.milestones.filter { !$0.isCompleted }.prefix(3).map { $0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Study Plan").font(.headline)
            if upcoming.isEmpty {
                Text("All milestones complete! 🎉").foregroundStyle(.secondary)
            } else {
                ForEach(upcoming) { milestone in
                    HStack {
                        Image(systemName: "checkmark.square").foregroundStyle(.blue)
                        VStack(alignment: .leading) {
                            Text(milestone.topic).font(.subheadline)
                            Text(milestone.subject.rawValue).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(milestone.targetDate.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

private struct SessionRow: View {
    let session: PracticeSession
    var body: some View {
        HStack {
            Image(systemName: session.subject == .math ? "function" : "book.fill")
                .frame(width: 32, height: 32)
                .background(Circle().fill(
                    session.subject == .math ? Color.blue.opacity(0.15) : Color.green.opacity(0.15)
                ))
                .foregroundStyle(session.subject == .math ? .blue : .green)
            VStack(alignment: .leading, spacing: 2) {
                Text(session.topic).font(.subheadline.bold())
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Text("\(session.score)/\(session.total)")
                .font(.subheadline.bold())
                .foregroundStyle(session.percentCorrect >= 70 ? .green : .orange)
        }
        .padding(.vertical, 4)
    }
}

struct EmptyStateCard: View {
    let icon: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon).font(.system(size: 44)).foregroundStyle(.blue.opacity(0.6))
            Text(title).font(.headline)
            Text(subtitle).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(28)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.cardBackground))
    }
}

// MARK: - Interactive Detail Sheets

struct StreakCalendarSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    private var weekdays: [String] { ["S", "M", "T", "W", "T", "F", "S"] }
    
    private var activeDays: Set<Int> {
        let calendar = Calendar.current
        let today = Date()
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)) else { return [] }
        
        var days = Set<Int>()
        for session in appState.sessions {
            let diff = calendar.dateComponents([.day], from: startOfWeek, to: session.date).day ?? 0
            if diff >= 0 && diff < 7 {
                days.insert(diff)
            }
        }
        return days
    }

    var body: some View {
        VStack(spacing: 20) {
            Text("Your Study Streak")
                .font(.title2.bold())
                .padding(.top)
            
            Text("Practice every day to keep your streak active and reinforce your learning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            HStack(spacing: 12) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 8) {
                        Text(weekdays[index])
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                        
                        ZStack {
                            Circle()
                                .fill(activeDays.contains(index) ? Color.orange : Color.primary.opacity(0.06))
                                .frame(width: 36, height: 36)
                            
                            if activeDays.contains(index) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.white)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 14).fill(Color.primary.opacity(0.03)))
            
            Spacer()
            
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .padding()
    }
}

struct ScoreBreakdownSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let mathScore = appState.mathEstimatedScore
        let ebrwScore = appState.ebrwEstimatedScore
        VStack(spacing: 24) {
            Text("Score Analysis")
                .font(.title2.bold())
                .padding(.top)

            VStack(spacing: 4) {
                Text("Current Estimate").font(.subheadline).foregroundStyle(.secondary)
                Text("\(mathScore + ebrwScore)")
                    .font(.system(size: 64, weight: .bold))
                    .foregroundStyle(.blue)
                Text("/ 1600").font(.caption).foregroundStyle(.secondary)
            }

            VStack(spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Mathematics")
                            .font(.headline)
                        Text("Algebra, geometry, and advanced functions")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(mathScore)")
                        .font(.title2.bold())
                        .foregroundStyle(.blue)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Reading & Writing")
                            .font(.headline)
                        Text("Analysis, vocabulary, and grammar conventions")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(ebrwScore)")
                        .font(.title2.bold())
                        .foregroundStyle(.green)
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))
            }
            .padding(.horizontal)

            Text("This score is calculated scaling your correct answers from all practice sessions and tests using standard SAT exam score conversion tables.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            Spacer()

            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.horizontal)
                .padding(.bottom)
        }
        .padding()
    }
}

struct TargetPickerSheet: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    @State private var targetScore: Double
    @State private var testDate: Date

    init(initialScore: Int, initialDate: Date?) {
        _targetScore = State(initialValue: Double(initialScore))
        _testDate = State(initialValue: initialDate ?? Date().addingTimeInterval(30*24*60*60))
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("Set Your Goals")
                .font(.title2.bold())
                .padding(.top)

            VStack(alignment: .leading, spacing: 10) {
                Text("Target SAT Score: \(Int(targetScore))")
                    .font(.headline)
                
                Slider(value: $targetScore, in: 400...1600, step: 10)
                    .tint(.blue)
                
                HStack {
                    Text("400").font(.caption).foregroundStyle(.secondary)
                    Spacer()
                    Text("1600").font(.caption).foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

            DatePicker("SAT Test Date", selection: $testDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.primary.opacity(0.04)))

            Spacer()

            Button("Save Goals") {
                var user = appState.currentUser
                user.targetScore = Int(targetScore)
                user.testDate = testDate
                appState.saveUser(user)
                dismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .padding()
    }
}
