//
//  Theme.swift
//  FinPilot
//

import SwiftUI
import UIKit

public enum FPTheme {
    // MARK: - Color Palette
    public enum Colors {
        public static let primary = Color(hex: "#0F172A") // Deep Slate 900
        public static let primaryAccent = Color(hex: "#6366F1") // Indigo
        public static let secondaryAccent = Color(hex: "#06B6D4") // Cyan
        public static let mint = Color(hex: "#10B981") // Mint Green (Income/Growth)
        public static let coral = Color(hex: "#EF4444") // Coral Red (Expense/Alert)
        public static let amber = Color(hex: "#F59E0B") // Amber Warning
        public static let purple = Color(hex: "#8B5CF6") // AI Coach Violet

        // Semantic Backgrounds
        public static let background = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.05, green: 0.07, blue: 0.11, alpha: 1.0) : UIColor(red: 0.98, green: 0.98, blue: 0.99, alpha: 1.0)
        })

        public static let secondaryBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.09, green: 0.12, blue: 0.18, alpha: 1.0) : UIColor(red: 0.94, green: 0.95, blue: 0.97, alpha: 1.0)
        })

        public static let cardBackground = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(red: 0.11, green: 0.14, blue: 0.22, alpha: 1.0) : UIColor.white
        })

        public static let cardBorder = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 1.0, alpha: 0.08) : UIColor(white: 0.0, alpha: 0.06)
        })

        public static let subtleText = Color(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark ? UIColor(white: 0.65, alpha: 1.0) : UIColor(white: 0.45, alpha: 1.0)
        })
    }

    // MARK: - Corner Radii
    public enum CornerRadius {
        public static let small: CGFloat = 8
        public static let medium: CGFloat = 14
        public static let large: CGFloat = 20
        public static let xLarge: CGFloat = 26
        public static let pill: CGFloat = 999
    }

    // MARK: - Spacing
    public enum Spacing {
        public static let xxs: CGFloat = 4
        public static let xs: CGFloat = 8
        public static let sm: CGFloat = 12
        public static let md: CGFloat = 16
        public static let lg: CGFloat = 24
        public static let xl: CGFloat = 32
    }

    // MARK: - Gradients
    public enum Gradients {
        public static let primaryHero = LinearGradient(
            colors: [Color(hex: "#1E1B4B"), Color(hex: "#0F172A")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let aiAccent = LinearGradient(
            colors: [Color(hex: "#6366F1"), Color(hex: "#8B5CF6"), Color(hex: "#EC4899")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        public static let mintCard = LinearGradient(
            colors: [Color(hex: "#065F46"), Color(hex: "#047857")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

public enum FPHaptics {
    public static func light() {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
    }

    public static func medium() {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
    }

    public static func heavy() {
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    public static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    public static func warning() {
        UINotificationFeedbackGenerator().notificationOccurred(.warning)
    }

    public static func error() {
        UINotificationFeedbackGenerator().notificationOccurred(.error)
    }
}
