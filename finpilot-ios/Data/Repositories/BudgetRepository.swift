//
//  BudgetRepository.swift
//  FinPilot
//

import Foundation

@MainActor
public protocol BudgetRepositoryProtocol {
    func getBudgets(month: Int, year: Int) async throws -> [Budget]
    func setBudget(_ budget: Budget) async throws
    func deleteBudget(id: UUID) async throws
}

@MainActor
public final class BudgetRepository: BudgetRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol

    public init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol = MockRemoteDataSource.shared
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    public func getBudgets(month: Int, year: Int) async throws -> [Budget] {
        try localDataSource.fetchBudgets(month: month, year: year)
    }

    public func setBudget(_ budget: Budget) async throws {
        try localDataSource.saveBudget(budget)
        if NetworkMonitor.shared.isConnected {
            try? await remoteDataSource.uploadBudget(budget)
        }
    }

    public func deleteBudget(id: UUID) async throws {
        try localDataSource.deleteBudget(id: id)
        if NetworkMonitor.shared.isConnected {
            try? await remoteDataSource.deleteBudget(id: id)
        }
    }
}
