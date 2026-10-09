//
//  LocalDataSource.swift
//  FinPilot
//

import Foundation
import SwiftData

@MainActor
public protocol LocalDataSourceProtocol {
    // Transactions
    func fetchTransactions() throws -> [Transaction]
    func saveTransaction(_ transaction: Transaction) throws
    func deleteTransaction(id: UUID) throws

    // Budgets
    func fetchBudgets(month: Int, year: Int) throws -> [Budget]
    func saveBudget(_ budget: Budget) throws
    func deleteBudget(id: UUID) throws

    // Profile
    func fetchProfile() throws -> FinancialProfile?
    func saveProfile(_ profile: FinancialProfile) throws

    // Insights
    func fetchInsights() throws -> [AIInsight]
    func saveInsight(_ insight: AIInsight) throws

    // Sync Queue
    func enqueueSyncItem(entityType: String, entityId: String, action: String, payloadJSON: String) throws
    func fetchPendingSyncItems() throws -> [SDSyncQueueItem]
    func removeSyncItem(id: UUID) throws
}

@MainActor
public final class LocalDataSource: LocalDataSourceProtocol {
    private let context: ModelContext

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - Transactions
    public func fetchTransactions() throws -> [Transaction] {
        var descriptor = FetchDescriptor<SDTransaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.includePendingChanges = true
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    public func saveTransaction(_ transaction: Transaction) throws {
        let id = transaction.id
        var descriptor = FetchDescriptor<SDTransaction>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.title = transaction.title
            existing.amount = transaction.amount
            existing.typeRaw = transaction.type.rawValue
            existing.categoryRaw = transaction.category.rawValue
            existing.date = transaction.date
            existing.notes = transaction.notes
            existing.merchant = transaction.merchant
            existing.paymentMethodRaw = transaction.paymentMethod.rawValue
            existing.updatedAt = Date()
            existing.isSynced = transaction.isSynced
        } else {
            let newModel = SDTransaction(from: transaction)
            context.insert(newModel)
        }
        try context.save()
    }

    public func deleteTransaction(id: UUID) throws {
        var descriptor = FetchDescriptor<SDTransaction>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let item = try context.fetch(descriptor).first {
            context.delete(item)
            try context.save()
        }
    }

    // MARK: - Budgets
    public func fetchBudgets(month: Int, year: Int) throws -> [Budget] {
        let descriptor = FetchDescriptor<SDBudget>(
            predicate: #Predicate { $0.month == month && $0.year == year }
        )
        let results = try context.fetch(descriptor)
        return results.map { $0.toDomain() }
    }

    public func saveBudget(_ budget: Budget) throws {
        let id = budget.id
        var descriptor = FetchDescriptor<SDBudget>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.limitAmount = budget.limitAmount
            existing.categoryRaw = budget.category.rawValue
            existing.month = budget.month
            existing.year = budget.year
            existing.updatedAt = Date()
        } else {
            let model = SDBudget(from: budget)
            context.insert(model)
        }
        try context.save()
    }

    public func deleteBudget(id: UUID) throws {
        var descriptor = FetchDescriptor<SDBudget>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let item = try context.fetch(descriptor).first {
            context.delete(item)
            try context.save()
        }
    }

    // MARK: - Profile
    public func fetchProfile() throws -> FinancialProfile? {
        let descriptor = FetchDescriptor<SDFinancialProfile>()
        return try context.fetch(descriptor).first?.toDomain()
    }

    public func saveProfile(_ profile: FinancialProfile) throws {
        let userId = profile.userId
        var descriptor = FetchDescriptor<SDFinancialProfile>(
            predicate: #Predicate { $0.userId == userId }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.displayName = profile.displayName
            existing.email = profile.email
            existing.currencyCode = profile.currencyCode
            existing.monthlyIncomeTarget = profile.monthlyIncomeTarget
            existing.monthlySavingsTarget = profile.monthlySavingsTarget
            existing.isBiometricEnabled = profile.isBiometricEnabled
            existing.isPushNotificationsEnabled = profile.isPushNotificationsEnabled
            existing.budgetWarningThreshold = profile.budgetWarningThreshold
            existing.lastSyncedAt = profile.lastSyncedAt
        } else {
            let model = SDFinancialProfile(from: profile)
            context.insert(model)
        }
        try context.save()
    }

    // MARK: - Insights
    public func fetchInsights() throws -> [AIInsight] {
        let descriptor = FetchDescriptor<SDAIInsight>(
            sortBy: [SortDescriptor(\.generatedAt, order: .reverse)]
        )
        return try context.fetch(descriptor).map { $0.toDomain() }
    }

    public func saveInsight(_ insight: AIInsight) throws {
        let id = insight.id
        var descriptor = FetchDescriptor<SDAIInsight>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1

        if let existing = try context.fetch(descriptor).first {
            existing.title = insight.title
            existing.summary = insight.summary
            existing.typeRaw = insight.type.rawValue
            existing.severityRaw = insight.severity.rawValue
            existing.recommendations = insight.recommendations
            existing.categoryRaw = insight.category?.rawValue
            existing.impactAmount = insight.impactAmount
            existing.generatedAt = insight.generatedAt
        } else {
            let model = SDAIInsight(from: insight)
            context.insert(model)
        }
        try context.save()
    }

    // MARK: - Sync Queue
    public func enqueueSyncItem(entityType: String, entityId: String, action: String, payloadJSON: String) throws {
        let item = SDSyncQueueItem(
            entityType: entityType,
            entityId: entityId,
            action: action,
            payloadJSON: payloadJSON
        )
        context.insert(item)
        try context.save()
    }

    public func fetchPendingSyncItems() throws -> [SDSyncQueueItem] {
        let descriptor = FetchDescriptor<SDSyncQueueItem>(
            sortBy: [SortDescriptor(\.createdAt, order: .forward)]
        )
        return try context.fetch(descriptor)
    }

    public func removeSyncItem(id: UUID) throws {
        var descriptor = FetchDescriptor<SDSyncQueueItem>(
            predicate: #Predicate { $0.id == id }
        )
        descriptor.fetchLimit = 1
        if let item = try context.fetch(descriptor).first {
            context.delete(item)
            try context.save()
        }
    }
}
