//
//  Budget.swift
//  FinPilot
//

import Foundation

public enum BudgetHealthState: String, Codable, Equatable {
    case onTrack = "On Track"
    case warning = "Near Limit"
    case overBudget = "Over Budget"
}

public struct Budget: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var category: TransactionCategory
    public var limitAmount: Double
    public var month: Int
    public var year: Int
    public var userId: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: UUID = UUID(),
        category: TransactionCategory,
        limitAmount: Double,
        month: Int = Calendar.current.component(.month, from: Date()),
        year: Int = Calendar.current.component(.year, from: Date()),
        userId: String = "local_user",
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.category = category
        self.limitAmount = limitAmount
        self.month = month
        self.year = year
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct BudgetStatus: Identifiable, Equatable {
    public var id: UUID { budget.id }
    public let budget: Budget
    public let spentAmount: Double
    public var remainingAmount: Double {
        max(0, budget.limitAmount - spentAmount)
    }
    public var utilizationPercentage: Double {
        guard budget.limitAmount > 0 else { return 0 }
        return spentAmount / budget.limitAmount
    }
    public var isOverBudget: Bool {
        spentAmount > budget.limitAmount
    }
    public var isWarning: Bool {
        utilizationPercentage >= 0.85 && !isOverBudget
    }
    public var healthState: BudgetHealthState {
        if isOverBudget {
            return .overBudget
        } else if isWarning {
            return .warning
        } else {
            return .onTrack
        }
    }

    public init(budget: Budget, spentAmount: Double) {
        self.budget = budget
        self.spentAmount = spentAmount
    }
}
