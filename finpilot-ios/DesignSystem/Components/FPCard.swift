//
//  FPCard.swift
//  FinPilot
//

import SwiftUI

public struct FPCardModifier: ViewModifier {
    public var padding: CGFloat
    public var cornerRadius: CGFloat

    public init(padding: CGFloat = FPTheme.Spacing.md, cornerRadius: CGFloat = FPTheme.CornerRadius.large) {
        self.padding = padding
        self.cornerRadius = cornerRadius
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(FPTheme.Colors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.04), radius: 10, x: 0, y: 4)
    }
}

public extension View {
    func fpCard(padding: CGFloat = FPTheme.Spacing.md, cornerRadius: CGFloat = FPTheme.CornerRadius.large) -> some View {
        modifier(FPCardModifier(padding: padding, cornerRadius: cornerRadius))
    }
}

public struct FPCard<Content: View>: View {
    private let padding: CGFloat
    private let cornerRadius: CGFloat
    private let content: Content

    public init(
        padding: CGFloat = FPTheme.Spacing.md,
        cornerRadius: CGFloat = FPTheme.CornerRadius.large,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public var body: some View {
        content
            .fpCard(padding: padding, cornerRadius: cornerRadius)
    }
}
