//
//  SwiftDataStack.swift
//  FinPilot
//

import Foundation
import SwiftData

@MainActor
public final class SwiftDataStack {
    public static let shared = SwiftDataStack()

    public let container: ModelContainer
    public var context: ModelContext {
        container.mainContext
    }

    public init(inMemory: Bool = false) {
        let schema = Schema([
            SDTransaction.self,
            SDBudget.self,
            SDFinancialProfile.self,
            SDAIInsight.self,
            SDSyncQueueItem.self
        ])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )
        do {
            self.container = try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to initialize SwiftData ModelContainer: \(error.localizedDescription)")
        }
    }

    public func makeLocalDataSource() -> LocalDataSourceProtocol {
        LocalDataSource(context: context)
    }

    public func makeTransactionRepository() -> TransactionRepositoryProtocol {
        TransactionRepository(localDataSource: makeLocalDataSource())
    }

    public func makeBudgetRepository() -> BudgetRepositoryProtocol {
        BudgetRepository(localDataSource: makeLocalDataSource())
    }

    public func makeProfileRepository() -> FinancialProfileRepositoryProtocol {
        FinancialProfileRepository(localDataSource: makeLocalDataSource())
    }

    public func makeAICoachRepository() -> AICoachRepositoryProtocol {
        AICoachRepository(localDataSource: makeLocalDataSource())
    }
}
