// SessionDebugger.swift – Debug logging for practice/test sessions (no-op in Release)

import Foundation

enum SessionDebugger {

#if DEBUG
    static var isEnabled: Bool = false
#endif

    static func log(_ message: String, tag: String = "Session") {
#if DEBUG
        guard isEnabled else { return }
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        print("[\(timestamp)] [\(tag)] \(message)")
#endif
    }

    static func logQuestion(_ question: Question, index: Int, total: Int) {
#if DEBUG
        guard isEnabled else { return }
        log("Q\(index + 1)/\(total) [\(question.aiTopicCategory ?? "bank")] \(question.topic) (\(question.difficulty.rawValue))")
#endif
    }

    static func logAnswer(question: Question, selectedIndex: Int, correct: Bool) {
#if DEBUG
        guard isEnabled else { return }
        let mark = correct ? "✅" : "❌"
        log("\(mark) Selected: \(question.options[safe: selectedIndex] ?? "?") | Correct: \(question.correctAnswer)")
#endif
    }

    static func logSessionComplete(score: Int, total: Int, duration: TimeInterval) {
#if DEBUG
        guard isEnabled else { return }
        let mins = Int(duration) / 60
        let secs = Int(duration) % 60
        log("Session done: \(score)/\(total) in \(mins)m \(secs)s")
#endif
    }
}

// MARK: - Safe array subscript used by debugger

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
