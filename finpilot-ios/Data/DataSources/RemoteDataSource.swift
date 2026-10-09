//
//  RemoteDataSource.swift
//  FinPilot
//

import Foundation

public protocol RemoteDataSourceProtocol: Sendable {
    // Transactions
    func uploadTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: UUID) async throws
    func fetchRemoteTransactions(userId: String) async throws -> [Transaction]

    // Budgets
    func uploadBudget(_ budget: Budget) async throws
    func deleteBudget(id: UUID) async throws
    func fetchRemoteBudgets(userId: String) async throws -> [Budget]

    // Profile
    func uploadProfile(_ profile: FinancialProfile) async throws
    func fetchRemoteProfile(userId: String) async throws -> FinancialProfile?

    // AI Coach
    func sendAICoachRequest(request: AICoachRequestPayload) async throws -> AICoachResponsePayload
}

public final class MockRemoteDataSource: RemoteDataSourceProtocol, @unchecked Sendable {
    public static let shared = MockRemoteDataSource()

    private let aiUseCase = AICoachUseCase()
    private var simulatedRemoteTransactions: [Transaction] = []
    private var simulatedRemoteBudgets: [Budget] = []

    public init() {}

    public func uploadTransaction(_ transaction: Transaction) async throws {
        // Simulate network latency
        try await Task.sleep(nanoseconds: 150_000_000)
        simulatedRemoteTransactions.removeAll { $0.id == transaction.id }
        simulatedRemoteTransactions.append(transaction)
    }

    public func deleteTransaction(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        simulatedRemoteTransactions.removeAll { $0.id == id }
    }

    public func fetchRemoteTransactions(userId: String) async throws -> [Transaction] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return simulatedRemoteTransactions
    }

    public func uploadBudget(_ budget: Budget) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        simulatedRemoteBudgets.removeAll { $0.id == budget.id }
        simulatedRemoteBudgets.append(budget)
    }

    public func deleteBudget(id: UUID) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        simulatedRemoteBudgets.removeAll { $0.id == id }
    }

    public func fetchRemoteBudgets(userId: String) async throws -> [Budget] {
        try await Task.sleep(nanoseconds: 150_000_000)
        return simulatedRemoteBudgets
    }

    public func uploadProfile(_ profile: FinancialProfile) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
    }

    public func fetchRemoteProfile(userId: String) async throws -> FinancialProfile? {
        try await Task.sleep(nanoseconds: 100_000_000)
        return nil
    }

    public func sendAICoachRequest(request: AICoachRequestPayload) async throws -> AICoachResponsePayload {
        try await Task.sleep(nanoseconds: 400_000_000)
        // If Firebase Cloud Functions URL is configured and network is reachable, use FirebaseFunctionClient
        let networkMonitor = NetworkMonitor.shared
        if networkMonitor.isConnected && !FirebaseFunctionClient.shared.cloudFunctionBaseURL.contains("finpilot-ai.cloudfunctions.net") {
            do {
                return try await FirebaseFunctionClient.shared.callAICoach(request: request)
            } catch {
                // Graceful fallback to local heuristic engine
            }
        }

        // Default to smart offline heuristic response
        return aiUseCase.generateSmartHeuristicResponse(
            prompt: request.userPrompt,
            transactions: [],
            budgets: [],
            profile: FinancialProfile()
        )
    }
}
