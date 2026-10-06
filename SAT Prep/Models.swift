// Models.swift – SAT Prep data models

import Foundation

// MARK: - Enums

enum Subject: String, Codable, CaseIterable {
    case math = "Math"
    case ebrw = "Reading & Writing"
}

enum MathTopic: String, Codable, CaseIterable {
    case algebra = "Algebra"
    case advancedMath = "Advanced Math"
    case problemSolving = "Problem Solving & Data Analysis"
    case geometry = "Geometry & Trigonometry"
}

enum EBRWTopic: String, Codable, CaseIterable {
    case craftStructure = "Craft and Structure"
    case expressionIdeas = "Expression of Ideas"
    case standardEnglish = "Standard English Conventions"
    case informationIdeas = "Information and Ideas"
}

enum Difficulty: String, Codable, CaseIterable {
    case easy = "Easy"
    case medium = "Medium"
    case hard = "Hard"
}

// MARK: - Question

struct Question: Identifiable, Codable {
    let id: UUID
    let text: String
    let options: [String]          // A, B, C, D
    let correctIndex: Int
    let explanation: String
    let subject: Subject
    let topic: String
    let difficulty: Difficulty
    var isAIGenerated: Bool = false
    var aiTopicCategory: String? = nil  // "experimental" | "ebrw"

    var correctAnswer: String { options[correctIndex] }

    var isTestOnly: Bool {
        let asciiSum = id.uuidString.utf8.reduce(0) { $0 + Int($1) }
        return asciiSum % 5 == 0 // ~20% of questions are reserved exclusively for mock tests
    }
}

// MARK: - AI Feedback

struct AIQuestionFeedback: Identifiable, Codable {
    let id: UUID
    let topic: String
    let subject: Subject
    let date: Date
    let aiAnswerIndex: Int        // what AI said was correct
    let userAnswerIndex: Int      // what user selected
    let verificationAgreed: Bool  // did re-verification match original AI answer
    let hardcodedAnswerIndex: Int // ground truth from hardcoded bank (-1 if no match)
}

// MARK: - User

struct User: Codable {
    var id: UUID
    var name: String
    var email: String
    var grade: Int                  // 9–12
    var targetScore: Int            // 400–1600
    var testDate: Date?
    var streakDays: Int
    var lastActiveDate: Date?
    var hasCompletedOnboarding: Bool
    var hasCompletedDiagnostic: Bool
    var isPremium: Bool = false

    static let empty = User(
        id: UUID(), name: "", email: "", grade: 11,
        targetScore: 1200, testDate: nil, streakDays: 0,
        lastActiveDate: nil, hasCompletedOnboarding: false,
        hasCompletedDiagnostic: false, isPremium: false
    )
}

enum SessionType: Codable, Equatable {
    case practice(topic: String, subject: Subject)
    case fullTest
}

// MARK: - Practice Session

struct QuestionAttempt: Codable {
    let questionId: UUID
    let selectedIndex: Int
    let isCorrect: Bool
    let timeSpent: TimeInterval
}

struct PracticeSession: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let date: Date
    let attempts: [QuestionAttempt]
    let sessionType: SessionType

    var topic: String {
        switch sessionType {
        case .practice(let topicName, _): return topicName
        case .fullTest: return "Full Test"
        }
    }

    var subject: Subject {
        switch sessionType {
        case .practice(_, let subj): return subj
        case .fullTest: return .math // Full test covers both, but fallback to .math
        }
    }

    var isFullTest: Bool {
        switch sessionType {
        case .practice: return false
        case .fullTest: return true
        }
    }

    var score: Int { attempts.filter(\.isCorrect).count }
    var total: Int { attempts.count }
    var percentCorrect: Double { total == 0 ? 0 : Double(score) / Double(total) * 100 }

    enum CodingKeys: String, CodingKey {
        case id, userId, date, topic, subject, attempts, isFullTest, sessionType
    }

    init(id: UUID, userId: UUID, date: Date, attempts: [QuestionAttempt], sessionType: SessionType) {
        self.id = id
        self.userId = userId
        self.date = date
        self.attempts = attempts
        self.sessionType = sessionType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.userId = try container.decode(UUID.self, forKey: .userId)
        self.date = try container.decode(Date.self, forKey: .date)
        self.attempts = try container.decode([QuestionAttempt].self, forKey: .attempts)
        
        if let type = try container.decodeIfPresent(SessionType.self, forKey: .sessionType) {
            self.sessionType = type
        } else {
            let isFull = try container.decodeIfPresent(Bool.self, forKey: .isFullTest) ?? false
            if isFull {
                self.sessionType = .fullTest
            } else {
                let topicName = try container.decodeIfPresent(String.self, forKey: .topic) ?? "General"
                let subj = try container.decodeIfPresent(Subject.self, forKey: .subject) ?? .math
                self.sessionType = .practice(topic: topicName, subject: subj)
            }
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(date, forKey: .date)
        try container.encode(attempts, forKey: .attempts)
        try container.encode(sessionType, forKey: .sessionType)
        try container.encode(topic, forKey: .topic)
        try container.encode(subject, forKey: .subject)
        try container.encode(isFullTest, forKey: .isFullTest)
    }
}

// MARK: - Performance Record

struct PerformanceRecord: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let topic: String
    let subject: Subject
    let date: Date
    let proficiency: Double         // 0.0 – 1.0
    let questionsAttempted: Int
    let questionsCorrect: Int
}

// MARK: - Study Plan

struct StudyMilestone: Identifiable, Codable {
    let id: UUID
    let topic: String
    let subject: Subject
    let targetDate: Date
    var isCompleted: Bool
}

struct StudyPlan: Identifiable, Codable {
    let id: UUID
    let userId: UUID
    let startDate: Date
    var milestones: [StudyMilestone]
}
