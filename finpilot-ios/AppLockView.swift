//
//  AppLockView.swift
//  FinPilot
//

import SwiftUI

public struct AppLockView: View {
    @State private var isAuthenticating: Bool = false
    @State private var authFailed: Bool = false

    public init() {}

    public var body: some View {
        ZStack {
            FPTheme.Colors.background.ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(FPTheme.Gradients.primaryHero)
                        .frame(width: 90, height: 90)

                    Image(systemName: BiometricAuthManager.shared.biometryType.systemIcon)
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.white)
                }

                VStack(spacing: 8) {
                    Text("FinPilot is Locked")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)

                    Text("Authenticate with \(BiometricAuthManager.shared.biometryType.title) to access your portfolio.")
                        .font(.subheadline)
                        .foregroundColor(FPTheme.Colors.subtleText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                if authFailed {
                    Text("Authentication was cancelled or failed. Tap below to retry.")
                        .font(.caption)
                        .foregroundColor(FPTheme.Colors.coral)
                }

                Spacer()

                FPButton(
                    title: "Unlock with \(BiometricAuthManager.shared.biometryType.title)",
                    icon: BiometricAuthManager.shared.biometryType.systemIcon,
                    isLoading: isAuthenticating
                ) {
                    Task {
                        await triggerAuth()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            }
        }
        .task {
            await triggerAuth()
        }
    }

    private func triggerAuth() async {
        isAuthenticating = true
        authFailed = false
        let success = await BiometricAuthManager.shared.authenticate()
        if !success {
            authFailed = true
            FPHaptics.error()
        } else {
            FPHaptics.success()
        }
        isAuthenticating = false
    }
}
