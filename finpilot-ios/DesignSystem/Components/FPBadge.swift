//
//  FPBadge.swift
//  FinPilot
//

import SwiftUI

public struct FPBadge: View {
    public let text: String
    public var icon: String?
    public var color: Color

    public init(text: String, icon: String? = nil, color: Color = FPTheme.Colors.primaryAccent) {
        self.text = text
        self.icon = icon
        self.color = color
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .bold))
            }
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }
}
