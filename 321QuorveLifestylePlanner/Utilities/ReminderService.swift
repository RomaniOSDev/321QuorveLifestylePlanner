import Foundation
import UserNotifications

enum ReminderService {
    static let notificationID = "quorve_daily_journal"
    static let enabledKey = "quorve_reminder_enabled"
    static let hourKey = "quorve_reminder_hour"

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    static var reminderHour: Int {
        let stored = UserDefaults.standard.object(forKey: hourKey) as? Int
        return stored ?? 20
    }

    static func setEnabled(_ enabled: Bool, hour: Int = reminderHour) async {
        UserDefaults.standard.set(enabled, forKey: enabledKey)
        UserDefaults.standard.set(hour, forKey: hourKey)

        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [notificationID])

        guard enabled else { return }

        let granted = await requestAuthorization()
        guard granted else {
            UserDefaults.standard.set(false, forKey: enabledKey)
            return
        }

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Quorve Check-in"
        content.body = "Take a moment to log your mood and habits."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: notificationID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    private static func requestAuthorization() async -> Bool {
        let center = UNUserNotificationCenter.current()
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }
}
