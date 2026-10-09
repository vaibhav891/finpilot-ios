//
//  FPStatCard.swift
//  FinPilot
//

import SwiftUI

public struct FPStatCard: View {
    public let title: String
    public let amount: Double
    public var currencyCode: String = "INR"
    public var icon: String
    public var iconColor: Color
    public var subtitle: String?
    public var isPositive: Bool?

    public init(
        title: String,
        amount: Double,
        currencyCode: String = "INR",
        icon: String,
        iconColor: Color,
        subtitle: String? = nil,
        isPositive: Bool? = nil
    ) {
        self.title = title
        self.amount = amount
        self.currencyCode = currencyCode
        self.icon = icon
        self.iconColor = iconColor
        self.subtitle = subtitle
        self.isPositive = isPositive
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(iconColor)
                }
                Spacer()
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
            }

            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(FPTheme.Colors.subtleText)

            Text(CurrencyFormatter.string(from: amount, currencyCode: currencyCode))
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.8)
                .lineLimit(1)
        }
        .padding(14)
        .background(FPTheme.Colors.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium, style: .continuous)
                .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
        )
    }
}
