//
//  TransactionRepository.swift
//  FinPilot
//

import Foundation

@MainActor
public protocol TransactionRepositoryProtocol {
    func getTransactions() async throws -> [Transaction]
    func addTransaction(_ transaction: Transaction) async throws
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: UUID) async throws
    func syncPendingTransactions() async throws
}

@MainActor
public final class TransactionRepository: TransactionRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol

    public init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol = MockRemoteDataSource.shared
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    public func getTransactions() async throws -> [Transaction] {
        try localDataSource.fetchTransactions()
    }

    public func addTransaction(_ transaction: Transaction) async throws {
        var tx = transaction
        tx.isSynced = false
        try localDataSource.saveTransaction(tx)

        // Try immediate remote sync if connected
        if NetworkMonitor.shared.isConnected {
            do {
                try await remoteDataSource.uploadTransaction(tx)
                tx.isSynced = true
                try localDataSource.saveTransaction(tx)
            } catch {
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(tx), let str = String(data: data, encoding: .utf8) {
                    try? localDataSource.enqueueSyncItem(
                        entityType: "transaction",
                        entityId: tx.id.uuidString,
                        action: "create",
                        payloadJSON: str
                    )
                }
            }
        } else {
            let encoder = JSONEncoder()
            if let data = try? encoder.encode(tx), let str = String(data: data, encoding: .utf8) {
                try? localDataSource.enqueueSyncItem(
                    entityType: "transaction",
                    entityId: tx.id.uuidString,
                    action: "create",
                    payloadJSON: str
                )
            }
        }
    }

    public func updateTransaction(_ transaction: Transaction) async throws {
        var tx = transaction
        tx.updatedAt = Date()
        tx.isSynced = false
        try localDataSource.saveTransaction(tx)

        if NetworkMonitor.shared.isConnected {
            do {
                try await remoteDataSource.uploadTransaction(tx)
                tx.isSynced = true
                try localDataSource.saveTransaction(tx)
            } catch {
                let encoder = JSONEncoder()
                if let data = try? encoder.encode(tx), let str = String(data: data, encoding: .utf8) {
                    try? localDataSource.enqueueSyncItem(
                        entityType: "transaction",
                        entityId: tx.id.uuidString,
                        action: "update",
                        payloadJSON: str
                    )
                }
            }
        }
    }

    public func deleteTransaction(id: UUID) async throws {
        try localDataSource.deleteTransaction(id: id)

        if NetworkMonitor.shared.isConnected {
            do {
                try await remoteDataSource.deleteTransaction(id: id)
            } catch {
                try? localDataSource.enqueueSyncItem(
                    entityType: "transaction",
                    entityId: id.uuidString,
                    action: "delete",
                    payloadJSON: "{}"
                )
            }
        } else {
            try? localDataSource.enqueueSyncItem(
                entityType: "transaction",
                entityId: id.uuidString,
                action: "delete",
                payloadJSON: "{}"
            )
        }
    }

    public func syncPendingTransactions() async throws {
        guard NetworkMonitor.shared.isConnected else { return }
        let queueItems = try localDataSource.fetchPendingSyncItems()

        for item in queueItems where item.entityType == "transaction" {
            let decoder = JSONDecoder()
            if item.action == "create" || item.action == "update" {
                if let data = item.payloadJSON.data(using: .utf8),
                   let tx = try? decoder.decode(Transaction.self, from: data) {
                    do {
                        try await remoteDataSource.uploadTransaction(tx)
                        try localDataSource.removeSyncItem(id: item.id)
                    } catch {
                        // Keep in queue for next cycle
                    }
                }
            } else if item.action == "delete" {
                if let uuid = UUID(uuidString: item.entityId) {
                    do {
                        try await remoteDataSource.deleteTransaction(id: uuid)
                        try localDataSource.removeSyncItem(id: item.id)
                    } catch {
                        // Keep in queue
                    }
                }
            }
        }
    }
}
