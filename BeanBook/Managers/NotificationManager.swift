import Foundation
import UserNotifications

@MainActor
@Observable
final class NotificationManager {
    private let dailyReminderID = "daily_coffee_reminder"

    /// Schedules a repeating local notification every day at the given time.
    /// Requests authorization first; silently no-ops if the user denies.
    func scheduleDailyCoffeeReminder(hour: Int = 8, minute: Int = 0) async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }
        } catch {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Log Your Coffee"
        content.body = "Don't forget to track your morning brew in BeanBook!"
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: dailyReminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelDailyCoffeeReminder() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [dailyReminderID])
    }
}
