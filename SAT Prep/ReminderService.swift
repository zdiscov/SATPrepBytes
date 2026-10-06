// ReminderService.swift – Daily study reminder notifications

import Foundation
import UserNotifications

final class ReminderService {

    static let shared = ReminderService()
    private let center = UNUserNotificationCenter.current()
    private let identifierPrefix = "satprep_daily_"
    private let refillThreshold = 8

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    var isAuthorized: Bool {
        get async {
            let settings = await center.notificationSettings()
            return settings.authorizationStatus == .authorized
        }
    }

    // MARK: - Schedule

    /// Call on app launch to refill the notification queue when it runs low.
    func scheduleIfNeeded(hour: Int = 9, minute: Int = 0) async {
        let pending = await center.pendingNotificationRequests()
        let ours = pending.filter { $0.identifier.hasPrefix(identifierPrefix) }
        guard ours.count < refillThreshold else { return }
        await reschedule(hour: hour, minute: minute)
    }

    func reschedule(hour: Int, minute: Int) async {
        // Clear existing
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending
            .filter { $0.identifier.hasPrefix(identifierPrefix) }
            .map { $0.identifier }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)

        // Schedule 64 days
        let startDate = Calendar.current.startOfDay(
            for: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        )

        let messages: [(String, String)] = [
            ("Time to practice! 📚", "A quick 5-minute drill keeps your score climbing."),
            ("Your study streak is waiting.", "Don't break the chain — open SAT Prep Bytes now."),
            ("Quick question for you:", "Can you answer one SAT question before breakfast?"),
            ("Your test date is coming.", "Every session gets you closer. Start with just one drill."),
            ("5 minutes, real results.", "Your weakest topic is waiting for you in SAT Prep Bytes."),
            ("Keep the momentum going.", "Yesterday's practice is paying off. Add to it today."),
            ("Your estimated score can improve today.", "Open SAT Prep Bytes for a quick session."),
            ("Don't let yesterday's effort go to waste.", "One drill keeps the knowledge fresh."),
        ]

        for dayOffset in 0..<64 {
            guard let fireDate = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) else { continue }
            let msg = messages[dayOffset % messages.count]
            let content = UNMutableNotificationContent()
            content.title = msg.0
            content.body  = msg.1
            content.sound = .default

            var components = Calendar.current.dateComponents([.year, .month, .day], from: fireDate)
            components.hour   = hour
            components.minute = minute

            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "\(identifierPrefix)\(dayOffset)",
                content: content,
                trigger: trigger
            )
            try? await center.add(request)
        }
    }

    // MARK: - Cancel

    func cancelAll() {
        Task {
            let pending = await center.pendingNotificationRequests()
            let toRemove = pending
                .filter { $0.identifier.hasPrefix(identifierPrefix) }
                .map { $0.identifier }
            center.removePendingNotificationRequests(withIdentifiers: toRemove)
        }
    }

    func clearBadge() {
        UNUserNotificationCenter.current().setBadgeCount(0) { _ in }
    }
}
