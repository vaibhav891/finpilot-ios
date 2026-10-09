//
//  FPEmptyStateView.swift
//  FinPilot
//

import SwiftUI

public struct FPEmptyStateView: View {
    public let icon: String
    public let title: String
    public let message: String
    public var actionTitle: String?
    public var action: (() -> Void)?

    public init(
        icon: String,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(FPTheme.Colors.primaryAccent.opacity(0.1))
                    .frame(width: 72, height: 72)
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(FPTheme.Colors.primaryAccent)
            }

            VStack(spacing: 6) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            if let actionTitle = actionTitle, let action = action {
                Button(action: action) {
                    Text(actionTitle)
                        .font(.system(size: 14, weight: .semibold))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(FPTheme.Colors.primaryAccent)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
    }
}
