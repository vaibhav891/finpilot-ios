//
//  DashboardViewModel.swift
//  FinPilot
//

import SwiftUI

@Observable
@MainActor
public final class DashboardViewModel {
    public var transactions: [Transaction] = []
    public var budgets: [Budget] = []
    public var profile: FinancialProfile = FinancialProfile()
    public var featuredInsight: AIInsight?
    public var isLoading: Bool = false
    public var errorMessage: String?

    // Calculated Properties
    public var currentMonthSummary: MonthlySummary {
        AnalyticsCalculator.calculateMonthlySummary(transactions: transactions)
    }

    public var totalBalance: Double {
        // Net balance across all transactions
        transactions.reduce(0.0) { sum, tx in
            tx.type == .income ? sum + tx.amount : sum - tx.amount
        }
    }

    public var budgetUtilization: Double {
        let currentBudgets = budgets.filter { $0.month == Date().month && $0.year == Date().year }
        let totalLimit = currentBudgets.reduce(0.0) { $0 + $1.limitAmount }
        guard totalLimit > 0 else { return 0 }
        return currentMonthSummary.totalExpense / totalLimit
    }

    public var topSpendingCategories: [CategorySpending] {
        Array(AnalyticsCalculator.calculateCategoryBreakdown(transactions: transactions).prefix(4))
    }

    public var recentTransactions: [Transaction] {
        Array(transactions.prefix(5))
    }

    public var dailySpendingTrend: [DailySpendingPoint] {
        AnalyticsCalculator.calculateDailySpendingTrend(transactions: transactions)
    }

    private let transactionRepository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private let profileRepository: FinancialProfileRepositoryProtocol
    private let aiCoachRepository: AICoachRepositoryProtocol

    public init(
        transactionRepository: TransactionRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        profileRepository: FinancialProfileRepositoryProtocol,
        aiCoachRepository: AICoachRepositoryProtocol
    ) {
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.profileRepository = profileRepository
        self.aiCoachRepository = aiCoachRepository
    }

    public func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            async let txs = transactionRepository.getTransactions()
            async let bgts = budgetRepository.getBudgets(month: Date().month, year: Date().year)
            async let prof = profileRepository.getProfile()
            async let insights = aiCoachRepository.getSavedInsights()

            self.transactions = try await txs
            self.budgets = try await bgts
            self.profile = try await prof
            let loadedInsights = try await insights
            self.featuredInsight = loadedInsights.first

            // If no featured insight exists, construct one
            if self.featuredInsight == nil && !self.transactions.isEmpty {
                let context = AICoachUseCase().buildFinancialContext(
                    transactions: self.transactions,
                    budgets: self.budgets,
                    profile: self.profile
                )
                let response = try? await aiCoachRepository.askQuestion(
                    prompt: "Provide an insightful overview of my highest spending category this month.",
                    context: context,
                    history: []
                )
                if let newInsight = response?.structuredInsight {
                    self.featuredInsight = AIInsight(
                        type: InsightType(rawValue: newInsight.type) ?? .spendingTrend,
                        title: newInsight.title,
                        summary: newInsight.summary,
                        severity: InsightSeverity(rawValue: newInsight.severity) ?? .medium,
                        recommendations: newInsight.recommendations,
                        category: newInsight.category.flatMap { TransactionCategory(rawValue: $0) },
                        impactAmount: newInsight.impactAmount,
                        generatedAt: Date()
                    )
                }
            }
        } catch {
            self.errorMessage = "Failed to load dashboard: \(error.localizedDescription)"
        }

        isLoading = false
    }

    public func deleteTransaction(id: UUID) async {
        do {
            try await transactionRepository.deleteTransaction(id: id)
            await loadData()
            FPHaptics.light()
        } catch {
            errorMessage = "Failed to delete transaction."
        }
    }
}
