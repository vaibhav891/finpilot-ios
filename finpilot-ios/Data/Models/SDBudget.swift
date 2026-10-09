//
//  SDBudget.swift
//  FinPilot
//

import Foundation
import SwiftData

@Model
public final class SDBudget {
    @Attribute(.unique) public var id: UUID
    public var categoryRaw: String
    public var limitAmount: Double
    public var month: Int
    public var year: Int
    public var userId: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        categoryRaw: String,
        limitAmount: Double,
        month: Int,
        year: Int,
        userId: String = "local_user",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.categoryRaw = categoryRaw
        self.limitAmount = limitAmount
        self.month = month
        self.year = year
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    public convenience init(from domain: Budget) {
        self.init(
            id: domain.id,
            categoryRaw: domain.category.rawValue,
            limitAmount: domain.limitAmount,
            month: domain.month,
            year: domain.year,
            userId: domain.userId,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt
        )
    }

    public func toDomain() -> Budget {
        Budget(
            id: id,
            category: TransactionCategory(rawValue: categoryRaw) ?? .other,
            limitAmount: limitAmount,
            month: month,
            year: year,
            userId: userId,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}
