//
//  FinancialProfile.swift
//  FinPilot
//

import Foundation

public struct FinancialProfile: Identifiable, Codable, Equatable {
    public var id: String { userId }
    public var userId: String
    public var displayName: String
    public var email: String
    public var currencyCode: String
    public var monthlyIncomeTarget: Double
    public var monthlySavingsTarget: Double
    public var isBiometricEnabled: Bool
    public var isPushNotificationsEnabled: Bool
    public var budgetWarningThreshold: Double
    public var lastSyncedAt: Date?

    public init(
        userId: String = "local_user",
        displayName: String = "Vaibhav Sultania",
        email: String = "vaibhav@example.com",
        currencyCode: String = "INR",
        monthlyIncomeTarget: Double = 150000,
        monthlySavingsTarget: Double = 45000,
        isBiometricEnabled: Bool = false,
        isPushNotificationsEnabled: Bool = true,
        budgetWarningThreshold: Double = 0.85,
        lastSyncedAt: Date? = nil
    ) {
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.currencyCode = currencyCode
        self.monthlyIncomeTarget = monthlyIncomeTarget
        self.monthlySavingsTarget = monthlySavingsTarget
        self.isBiometricEnabled = isBiometricEnabled
        self.isPushNotificationsEnabled = isPushNotificationsEnabled
        self.budgetWarningThreshold = budgetWarningThreshold
        self.lastSyncedAt = lastSyncedAt
    }
}
