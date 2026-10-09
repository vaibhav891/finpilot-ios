//
//  AuthViewModel.swift
//  FinPilot
//

import SwiftUI

@Observable
@MainActor
public final class AuthViewModel {
    public var email: String = ""
    public var password: String = ""
    public var displayName: String = ""
    public var isSignUp: Bool = false
    public var isLoading: Bool = false
    public var errorMessage: String?
    public var isAuthenticated: Bool = false

    private let profileRepository: FinancialProfileRepositoryProtocol

    public init(profileRepository: FinancialProfileRepositoryProtocol) {
        self.profileRepository = profileRepository
        checkExistingAuth()
    }

    public func checkExistingAuth() {
        if let token = try? KeychainHelper.shared.readString(key: "auth_token"), !token.isEmpty {
            isAuthenticated = true
        }
    }

    public func authenticate() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter both email and password."
            return
        }

        isLoading = true
        errorMessage = nil

        // Simulate network auth or Firebase Auth
        try? await Task.sleep(nanoseconds: 500_000_000)

        do {
            let token = "token_\(UUID().uuidString)"
            try KeychainHelper.shared.save(key: "auth_token", string: token)

            if isSignUp {
                let name = displayName.isEmpty ? "FinPilot User" : displayName
                let profile = FinancialProfile(
                    userId: "user_\(UUID().uuidString.prefix(8))",
                    displayName: name,
                    email: email,
                    currencyCode: "INR",
                    monthlyIncomeTarget: 150000,
                    monthlySavingsTarget: 45000
                )
                try await profileRepository.updateProfile(profile)
            }

            isAuthenticated = true
            FPHaptics.success()
        } catch {
            errorMessage = "Authentication failed: \(error.localizedDescription)"
            FPHaptics.error()
        }

        isLoading = false
    }

    public func signInWithDemoAccount() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 300_000_000)
        try? KeychainHelper.shared.save(key: "auth_token", string: "demo_token_authenticated")
        isAuthenticated = true
        isLoading = false
        FPHaptics.success()
    }

    public func signOut() {
        KeychainHelper.shared.delete(key: "auth_token")
        isAuthenticated = false
        email = ""
        password = ""
        displayName = ""
        FPHaptics.light()
    }
}
