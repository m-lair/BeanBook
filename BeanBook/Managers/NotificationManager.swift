//
//  NotificationManager.swift
//  BeanBook
//
//  Created by Marcus Lair on 1/24/25.
//


import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}
    
    /// Schedules a repeating local notification every day at 8:00 AM.
    func scheduleDailyCoffeeReminder(hour: Int = 8, minute: Int = 0) {
        // 1) Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Time to Log Your Coffee"
        content.body = "Don't forget to track your morning brew in BeanBook!"
        content.sound = .default
        
        // 2) Configure the recurring date
        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        
        // 3) Create the trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // 4) Create a request
        let request = UNNotificationRequest(identifier: "daily_coffee_reminder",
                                            content: content,
                                            trigger: trigger)
        
        // 5) Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling daily coffee reminder: \(error)")
            } else {
                print("Scheduled daily coffee reminder at \(hour):\(minute).")
            }
        }
    }
}
