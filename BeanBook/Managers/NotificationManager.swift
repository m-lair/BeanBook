//
//  NotificationManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/24/25.
//


import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private init() {}
    
    /// Schedules a repeating local notification every day at 8:00 AM.
    /// Requests alert/sound authorization first so the toggle flow prompts the user on first enable.
    func scheduleDailyCoffeeReminder(hour: Int = 8, minute: Int = 0) async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound])
            guard granted else { return }
        } catch {
            print("Notification authorization error: \(error)")
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Time to Log Your Coffee"
        content.body = "Don't forget to track your morning brew in BeanBook!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily_coffee_reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
        } catch {
            print("Error scheduling daily coffee reminder: \(error)")
        }
    }
}
