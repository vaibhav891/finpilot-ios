//
//  NotificationManager.swift
//  FinPilot
//

import Foundation
import UserNotifications

public final class NotificationManager {
    public static let shared = NotificationManager()

    private init() {}

    public func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .badge, .sound]
            )
            return granted
        } catch {
            return false
        }
    }

    public func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    public func sendBudgetWarning(category: TransactionCategory, utilizationPercentage: Double, remainingAmount: Double) {
        let content = UNMutableNotificationContent()
        content.title = "Budget Alert: \(category.displayName)"
        content.body = "You're at \(Int(utilizationPercentage * 100))% of your \(category.displayName) budget. ₹\(Int(remainingAmount)) remaining."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: "budget_warning_\(category.rawValue)_\(Date().timeIntervalSince1970)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    public func scheduleMonthlyReportNotification() {
        let content = UNMutableNotificationContent()
        content.title = "Monthly Spending Report"
        content.body = "Your monthly spending summary and AI financial review are ready."
        content.sound = .default

        // Schedule for the 1st of each month at 10:00 AM
        var dateComponents = DateComponents()
        dateComponents.day = 1
        dateComponents.hour = 10
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "monthly_spending_report",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }

    public func sendInstantTestNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request)
    }
}
