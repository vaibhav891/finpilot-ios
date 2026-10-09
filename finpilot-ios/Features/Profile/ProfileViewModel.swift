//
//  ProfileViewModel.swift
//  FinPilot
//

import SwiftUI
import SwiftData

@Observable
@MainActor
public final class ProfileViewModel {
    public var profile: FinancialProfile = FinancialProfile()
    public var incomeTargetString: String = ""
    public var savingsTargetString: String = ""
    public var selectedCurrency: String = "INR"
    public var isBiometricEnabled: Bool = false
    public var isPushNotificationsEnabled: Bool = true
    public var isSaving: Bool = false
    public var statusMessage: String?
    public var showResetConfirmation: Bool = false

    private let profileRepository: FinancialProfileRepositoryProtocol
    private let context: ModelContext

    public init(profileRepository: FinancialProfileRepositoryProtocol, context: ModelContext) {
        self.profileRepository = profileRepository
        self.context = context
    }

    public func loadProfile() async {
        do {
            let prof = try await profileRepository.getProfile()
            self.profile = prof
            self.incomeTargetString = String(format: "%.0f", prof.monthlyIncomeTarget)
            self.savingsTargetString = String(format: "%.0f", prof.monthlySavingsTarget)
            self.selectedCurrency = prof.currencyCode
            self.isBiometricEnabled = prof.isBiometricEnabled
            self.isPushNotificationsEnabled = prof.isPushNotificationsEnabled
        } catch {
            print("Failed to load profile: \(error)")
        }
    }

    public func saveSettings() async {
        isSaving = true
        var updated = profile
        if let income = Double(incomeTargetString) {
            updated.monthlyIncomeTarget = income
        }
        if let savings = Double(savingsTargetString) {
            updated.monthlySavingsTarget = savings
        }
        updated.currencyCode = selectedCurrency
        updated.isBiometricEnabled = isBiometricEnabled
        updated.isPushNotificationsEnabled = isPushNotificationsEnabled

        // Update BiometricAuthManager state
        BiometricAuthManager.shared.isBiometricEnabled = isBiometricEnabled

        do {
            try await profileRepository.updateProfile(updated)
            self.profile = updated
            statusMessage = "Settings saved successfully."
            FPHaptics.success()
        } catch {
            statusMessage = "Failed to save: \(error.localizedDescription)"
        }
        isSaving = false
    }

    public func toggleBiometrics(_ enabled: Bool) async {
        if enabled {
            // Test authentication before enabling
            let authenticated = await BiometricAuthManager.shared.authenticate()
            if authenticated {
                isBiometricEnabled = true
                await saveSettings()
            } else {
                isBiometricEnabled = false
            }
        } else {
            isBiometricEnabled = false
            await saveSettings()
        }
    }

    public func reseedDemoData() {
        DemoDataSeeder.shared.resetAndReseed(context: context)
        Task {
            await loadProfile()
        }
        statusMessage = "Demo Indian financial portfolio reseeded successfully."
        FPHaptics.success()
    }
}
