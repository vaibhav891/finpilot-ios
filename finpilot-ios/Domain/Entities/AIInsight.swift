//
//  AIInsight.swift
//  FinPilot
//

import Foundation

public enum InsightSeverity: String, Codable {
    case low = "low"
    case medium = "medium"
    case high = "high"
    case tip = "tip"

    public var badgeTitle: String {
        switch self {
        case .low: return "Note"
        case .medium: return "Attention"
        case .high: return "Alert"
        case .tip: return "Tip"
        }
    }

    public var systemIcon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .medium: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.octagon.fill"
        case .tip: return "lightbulb.fill"
        }
    }
}

public enum InsightType: String, Codable {
    case spendingTrend = "spending_trend"
    case budgetAlert = "budget_alert"
    case savingOpportunity = "saving_opportunity"
    case anomaly = "anomaly"
    case general = "general"
}

public struct AIInsight: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var type: InsightType
    public var title: String
    public var summary: String
    public var severity: InsightSeverity
    public var recommendations: [String]
    public var category: TransactionCategory?
    public var impactAmount: Double?
    public var generatedAt: Date

    public init(
        id: UUID = UUID(),
        type: InsightType,
        title: String,
        summary: String,
        severity: InsightSeverity = .medium,
        recommendations: [String] = [],
        category: TransactionCategory? = nil,
        impactAmount: Double? = nil,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.title = title
        self.summary = summary
        self.severity = severity
        self.recommendations = recommendations
        self.category = category
        self.impactAmount = impactAmount
        self.generatedAt = generatedAt
    }
}
