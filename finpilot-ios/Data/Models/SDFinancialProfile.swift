//
//  SDFinancialProfile.swift
//  FinPilot
//

import Foundation
import SwiftData

@Model
public final class SDFinancialProfile {
    @Attribute(.unique) public var userId: String
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

    public convenience init(from domain: FinancialProfile) {
        self.init(
            userId: domain.userId,
            displayName: domain.displayName,
            email: domain.email,
            currencyCode: domain.currencyCode,
            monthlyIncomeTarget: domain.monthlyIncomeTarget,
            monthlySavingsTarget: domain.monthlySavingsTarget,
            isBiometricEnabled: domain.isBiometricEnabled,
            isPushNotificationsEnabled: domain.isPushNotificationsEnabled,
            budgetWarningThreshold: domain.budgetWarningThreshold,
            lastSyncedAt: domain.lastSyncedAt
        )
    }

    public func toDomain() -> FinancialProfile {
        FinancialProfile(
            userId: userId,
            displayName: displayName,
            email: email,
            currencyCode: currencyCode,
            monthlyIncomeTarget: monthlyIncomeTarget,
            monthlySavingsTarget: monthlySavingsTarget,
            isBiometricEnabled: isBiometricEnabled,
            isPushNotificationsEnabled: isPushNotificationsEnabled,
            budgetWarningThreshold: budgetWarningThreshold,
            lastSyncedAt: lastSyncedAt
        )
    }
}
