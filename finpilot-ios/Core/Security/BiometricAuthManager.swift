//
//  BiometricAuthManager.swift
//  FinPilot
//

import Foundation
import LocalAuthentication
import SwiftUI

public enum BiometricType {
    case none
    case touchID
    case faceID
    case opticID

    public var title: String {
        switch self {
        case .none: return "Passcode"
        case .touchID: return "Touch ID"
        case .faceID: return "Face ID"
        case .opticID: return "Optic ID"
        }
    }

    public var systemIcon: String {
        switch self {
        case .none: return "lock.fill"
        case .touchID: return "touchid"
        case .faceID: return "faceid"
        case .opticID: return "opticid"
        }
    }
}

@Observable
@MainActor
public final class BiometricAuthManager {
    public static let shared = BiometricAuthManager()

    public var isLocked: Bool = false
    public var isBiometricEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isBiometricEnabled, forKey: "finpilot_biometric_enabled")
        }
    }
    public var lastBackgroundTime: Date?

    public init() {
        self.isBiometricEnabled = UserDefaults.standard.bool(forKey: "finpilot_biometric_enabled")
        if isBiometricEnabled {
            self.isLocked = true
        }
    }

    public var biometryType: BiometricType {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }

        switch context.biometryType {
        case .faceID:
            return .faceID
        case .touchID:
            return .touchID
        case .opticID:
            return .opticID
        @unknown default:
            return .none
        }
    }

    public func authenticate() async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = "Cancel"
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            // Biometrics not available, try passcode fallback
            return await authenticateWithPasscode(context: context)
        }

        let reason = "Unlock FinPilot to access your financial insights and accounts."

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            if success {
                self.isLocked = false
                return true
            }
            return false
        } catch {
            // Fallback to passcode if biometric evaluation fails or is canceled
            return await authenticateWithPasscode(context: context)
        }
    }

    private func authenticateWithPasscode(context: LAContext) async -> Bool {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // In simulator or when no passcode is set, unlock
            self.isLocked = false
            return true
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Enter device passcode to unlock FinPilot."
            )
            if success {
                self.isLocked = false
                return true
            }
            return false
        } catch {
            return false
        }
    }

    public func handleAppDidEnterBackground() {
        if isBiometricEnabled {
            lastBackgroundTime = Date()
        }
    }

    public func handleAppWillEnterForeground() {
        guard isBiometricEnabled else { return }
        if let lastBackgroundTime = lastBackgroundTime {
            // Lock immediately if sent to background for more than 5 seconds
            if Date().timeIntervalSince(lastBackgroundTime) > 5 {
                self.isLocked = true
            }
        } else {
            self.isLocked = true
        }
    }

    public func lockManually() {
        if isBiometricEnabled {
            self.isLocked = true
        }
    }
}
