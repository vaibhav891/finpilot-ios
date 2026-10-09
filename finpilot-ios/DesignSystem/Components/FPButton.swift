//
//  FPButton.swift
//  FinPilot
//

import SwiftUI

public enum FPButtonStyleType {
    case primary
    case secondary
    case outline
    case destructive
}

public struct FPButton: View {
    public let title: String
    public var icon: String?
    public var style: FPButtonStyleType
    public var isLoading: Bool
    public var isFullWidth: Bool
    public let action: () -> Void

    public init(
        title: String,
        icon: String? = nil,
        style: FPButtonStyleType = .primary,
        isLoading: Bool = false,
        isFullWidth: Bool = true,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.style = style
        self.isLoading = isLoading
        self.isFullWidth = isFullWidth
        self.action = action
    }

    public var body: some View {
        Button(action: {
            FPHaptics.light()
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .tint(textColor)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 15, weight: .semibold))
                    }
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .frame(maxWidth: isFullWidth ? .infinity : nil)
            .padding(.vertical, 14)
            .padding(.horizontal, 20)
            .background(backgroundColor)
            .foregroundColor(textColor)
            .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .outline ? 1.5 : 0)
            )
        }
        .disabled(isLoading)
        .accessibilityLabel(title)
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return FPTheme.Colors.primaryAccent
        case .secondary:
            return FPTheme.Colors.secondaryBackground
        case .outline:
            return Color.clear
        case .destructive:
            return FPTheme.Colors.coral
        }
    }

    private var textColor: Color {
        switch style {
        case .primary, .destructive:
            return .white
        case .secondary:
            return .primary
        case .outline:
            return FPTheme.Colors.primaryAccent
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return FPTheme.Colors.primaryAccent
        default:
            return Color.clear
        }
    }
}
