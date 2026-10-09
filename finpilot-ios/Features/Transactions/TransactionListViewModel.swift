//
//  TransactionListViewModel.swift
//  FinPilot
//

import SwiftUI

public enum TransactionFilterType: String, CaseIterable, Identifiable {
    case all = "All"
    case expense = "Expenses"
    case income = "Income"

    public var id: String { rawValue }
}

@Observable
@MainActor
public final class TransactionListViewModel {
    public var transactions: [Transaction] = []
    public var selectedFilter: TransactionFilterType = .all
    public var selectedCategory: TransactionCategory? = nil
    public var searchQuery: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?

    public var filteredTransactions: [Transaction] {
        transactions.filter { tx in
            // Filter by type
            switch selectedFilter {
            case .all:
                break
            case .expense:
                if tx.type != .expense { return false }
            case .income:
                if tx.type != .income { return false }
            }

            // Filter by category
            if let cat = selectedCategory, tx.category != cat {
                return false
            }

            // Filter by search query
            if !searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                let q = searchQuery.lowercased()
                let titleMatch = tx.title.lowercased().contains(q)
                let merchantMatch = tx.merchant?.lowercased().contains(q) ?? false
                let categoryMatch = tx.category.displayName.lowercased().contains(q)
                let notesMatch = tx.notes?.lowercased().contains(q) ?? false
                if !(titleMatch || merchantMatch || categoryMatch || notesMatch) {
                    return false
                }
            }

            return true
        }
    }

    private let repository: TransactionRepositoryProtocol

    public init(repository: TransactionRepositoryProtocol) {
        self.repository = repository
    }

    public func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        do {
            self.transactions = try await repository.getTransactions()
        } catch {
            self.errorMessage = "Failed to load transactions: \(error.localizedDescription)"
        }
        isLoading = false
    }

    public func deleteTransaction(id: UUID) async {
        do {
            try await repository.deleteTransaction(id: id)
            transactions.removeAll { $0.id == id }
            FPHaptics.medium()
        } catch {
            errorMessage = "Failed to delete: \(error.localizedDescription)"
        }
    }
}
