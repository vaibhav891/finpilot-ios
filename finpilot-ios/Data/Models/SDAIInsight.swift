//
//  SDAIInsight.swift
//  FinPilot
//

import Foundation
import SwiftData

@Model
public final class SDAIInsight {
    @Attribute(.unique) public var id: UUID
    public var typeRaw: String
    public var title: String
    public var summary: String
    public var severityRaw: String
    public var recommendations: [String]
    public var categoryRaw: String?
    public var impactAmount: Double?
    public var generatedAt: Date

    public init(
        id: UUID = UUID(),
        typeRaw: String,
        title: String,
        summary: String,
        severityRaw: String,
        recommendations: [String],
        categoryRaw: String? = nil,
        impactAmount: Double? = nil,
        generatedAt: Date = Date()
    ) {
        self.id = id
        self.typeRaw = typeRaw
        self.title = title
        self.summary = summary
        self.severityRaw = severityRaw
        self.recommendations = recommendations
        self.categoryRaw = categoryRaw
        self.impactAmount = impactAmount
        self.generatedAt = generatedAt
    }

    public convenience init(from domain: AIInsight) {
        self.init(
            id: domain.id,
            typeRaw: domain.type.rawValue,
            title: domain.title,
            summary: domain.summary,
            severityRaw: domain.severity.rawValue,
            recommendations: domain.recommendations,
            categoryRaw: domain.category?.rawValue,
            impactAmount: domain.impactAmount,
            generatedAt: domain.generatedAt
        )
    }

    public func toDomain() -> AIInsight {
        AIInsight(
            id: id,
            type: InsightType(rawValue: typeRaw) ?? .general,
            title: title,
            summary: summary,
            severity: InsightSeverity(rawValue: severityRaw) ?? .medium,
            recommendations: recommendations,
            category: categoryRaw.flatMap { TransactionCategory(rawValue: $0) },
            impactAmount: impactAmount,
            generatedAt: generatedAt
        )
    }
}
