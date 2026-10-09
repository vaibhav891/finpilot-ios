//
//  BudgetViewModel.swift
//  FinPilot
//

import SwiftUI

public struct CategoryBudgetProgress: Identifiable, Equatable {
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
    public var status: BudgetHealthState {
        if utilizationPercentage > 1.0 {
            return .overBudget
        } else if utilizationPercentage >= 0.85 {
            return .warning
        } else {
            return .onTrack
        }
    }
}

@Observable
@MainActor
public final class BudgetViewModel {
    public var budgets: [Budget] = []
    public var transactions: [Transaction] = []
    public var selectedMonth: Int = Date().month
    public var selectedYear: Int = Date().year
    public var isLoading: Bool = false
    public var errorMessage: String?

    public var budgetProgressList: [CategoryBudgetProgress] {
        let calendar = Calendar.current
        return budgets.map { b in
            let spent = transactions
                .filter { $0.category == b.category && $0.type == .expense && calendar.component(.month, from: $0.date) == selectedMonth && calendar.component(.year, from: $0.date) == selectedYear }
                .reduce(0.0) { $0 + $1.amount }
            return CategoryBudgetProgress(budget: b, spentAmount: spent)
        }
        .sorted { $0.utilizationPercentage > $1.utilizationPercentage }
    }

    public var totalBudgetLimit: Double {
        budgets.reduce(0.0) { $0 + $1.limitAmount }
    }

    public var totalBudgetSpent: Double {
        budgetProgressList.reduce(0.0) { $0 + $1.spentAmount }
    }

    public var overallUtilization: Double {
        guard totalBudgetLimit > 0 else { return 0 }
        return totalBudgetSpent / totalBudgetLimit
    }

    private let budgetRepository: BudgetRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol

    public init(
        budgetRepository: BudgetRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol
    ) {
        self.budgetRepository = budgetRepository
        self.transactionRepository = transactionRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil
        do {
            async let b = budgetRepository.getBudgets(month: selectedMonth, year: selectedYear)
            async let t = transactionRepository.getTransactions()
            self.budgets = try await b
            self.transactions = try await t
        } catch {
            errorMessage = "Failed to load budgets: \(error.localizedDescription)"
        }
        isLoading = false
    }

    public func deleteBudget(id: UUID) async {
        do {
            try await budgetRepository.deleteBudget(id: id)
            budgets.removeAll { $0.id == id }
            FPHaptics.light()
        } catch {
            errorMessage = "Failed to delete budget."
        }
    }
}
