//
//  InsightCardView.swift
//  FinPilot
//

import SwiftUI

public struct InsightCardView: View {
    public let insight: AIInsight
    public var onDiscuss: (() -> Void)?

    public init(insight: AIInsight, onDiscuss: (() -> Void)? = nil) {
        self.insight = insight
        self.onDiscuss = onDiscuss
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(FPTheme.Gradients.aiAccent)
                    Text("AI FINANCIAL INSIGHT")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundStyle(FPTheme.Gradients.aiAccent)
                }

                Spacer()

                severityBadge
            }

            Text(insight.title)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.primary)

            Text(insight.summary)
                .font(.subheadline)
                .foregroundColor(FPTheme.Colors.subtleText)
                .lineSpacing(3)

            if !insight.recommendations.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(insight.recommendations.prefix(2), id: \.self) { tip in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(FPTheme.Colors.mint)
                                .padding(.top, 2)
                            Text(tip)
                                .font(.caption)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }

            if let onDiscuss = onDiscuss {
                Button(action: {
                    FPHaptics.light()
                    onDiscuss()
                }) {
                    HStack(spacing: 6) {
                        Text("Discuss with AI Coach")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(FPTheme.Colors.primaryAccent)
                }
                .padding(.top, 4)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large, style: .continuous)
                .fill(FPTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [FPTheme.Colors.primaryAccent.opacity(0.4), FPTheme.Colors.cardBorder],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: FPTheme.Colors.primaryAccent.opacity(0.06), radius: 12, x: 0, y: 6)
    }

    private var severityBadge: some View {
        let (color, icon, text) = badgeDetails
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .bold))
            Text(text)
                .font(.caption2)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private var badgeDetails: (Color, String, String) {
        switch insight.severity {
        case .high:
            return (FPTheme.Colors.coral, "exclamationmark.octagon.fill", "Alert")
        case .medium:
            return (FPTheme.Colors.amber, "exclamationmark.triangle.fill", "Attention")
        case .low:
            return (FPTheme.Colors.secondaryAccent, "info.circle.fill", "Note")
        case .tip:
            return (FPTheme.Colors.mint, "lightbulb.fill", "Tip")
        }
    }
}
