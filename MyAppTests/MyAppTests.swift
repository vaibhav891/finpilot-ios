//
//  MyAppTests.swift
//  MyAppTests
//
//  FinPilot Unit Tests Suite using Swift Testing
//

import Testing
import Foundation
@testable import MyApp

struct FinPilotCoreTests {

    // MARK: - Currency & Formatting Tests
    @Test func currencyFormattingINR() {
        let amount = 150000.0
        let formatted = CurrencyFormatter.string(from: amount, currencyCode: "INR")
        #expect(formatted.contains("1,50,000") || formatted.contains("150,000"))

        let negativeAmount = -3500.0
        let signedExpense = CurrencyFormatter.string(from: negativeAmount, currencyCode: "INR", showSign: true)
        #expect(signedExpense.hasPrefix("-"))

        let positiveIncome = CurrencyFormatter.string(from: 25000.0, currencyCode: "INR", showSign: true)
        #expect(positiveIncome.hasPrefix("+"))
    }

    @Test func compactCurrencyFormatting() {
        let lakh = CurrencyFormatter.compactString(from: 250000.0)
        #expect(lakh.contains("L"))

        let crore = CurrencyFormatter.compactString(from: 15000000.0)
        #expect(crore.contains("Cr"))

        let thousand = CurrencyFormatter.compactString(from: 5000.0)
        #expect(thousand.contains("k"))
    }

    // MARK: - Date Calculation Tests
    @Test func dateExtensionCalculations() {
        let now = Date()
        let start = now.startOfMonth
        let calendar = Calendar.current
        #expect(calendar.component(.day, from: start) == 1)

        let prev = now.previousMonthStart
        #expect(!prev.isSameMonth(as: now))
    }

    // MARK: - Analytics Calculator Tests
    @Test func analyticsMonthlySummary() {
        let now = Date()
        let sampleTransactions = [
            Transaction(title: "Salary", amount: 100000, type: .income, category: .salary, date: now),
            Transaction(title: "Rent", amount: 30000, type: .expense, category: .rent, date: now),
            Transaction(title: "Groceries", amount: 10000, type: .expense, category: .groceries, date: now),
            Transaction(title: "Dining", amount: 5000, type: .expense, category: .dining, date: now)
        ]

        let summary = AnalyticsCalculator.calculateMonthlySummary(transactions: sampleTransactions, for: now)
        #expect(summary.totalIncome == 100000)
        #expect(summary.totalExpense == 45000)
        #expect(summary.netSavings == 55000)
        #expect(summary.savingsRate == 0.55)
    }

    @Test func analyticsCategoryBreakdown() {
        let now = Date()
        let sampleTransactions = [
            Transaction(title: "Rent", amount: 30000, type: .expense, category: .rent, date: now),
            Transaction(title: "Groceries", amount: 10000, type: .expense, category: .groceries, date: now),
            Transaction(title: "Dining", amount: 10000, type: .expense, category: .dining, date: now)
        ]

        let breakdown = AnalyticsCalculator.calculateCategoryBreakdown(transactions: sampleTransactions, for: now)
        #expect(breakdown.count == 3)
        #expect(breakdown[0].category == .rent)
        #expect(breakdown[0].totalAmount == 30000)
        #expect(breakdown[0].percentage == 0.60)
    }

    @Test func analyticsMonthOverMonthComparison() {
        let now = Date()
        let prev = now.previousMonthStart

        let transactions = [
            // Current month: 50,000 expense
            Transaction(title: "Rent", amount: 50000, type: .expense, category: .rent, date: now),
            // Previous month: 40,000 expense
            Transaction(title: "Rent", amount: 40000, type: .expense, category: .rent, date: prev)
        ]

        let mom = AnalyticsCalculator.compareMonthOverMonth(transactions: transactions, referenceDate: now)
        #expect(mom.difference == 10000)
        #expect(mom.percentageChange == 25.0)
        #expect(mom.isIncrease == true)
    }

    // MARK: - Budget Status Tests
    @Test func budgetStatusCalculations() {
        let budget = Budget(category: .dining, limitAmount: 10000)

        // Under 85%: On Track
        let statusOnTrack = BudgetStatus(budget: budget, spentAmount: 6000)
        #expect(statusOnTrack.utilizationPercentage == 0.60)
        #expect(statusOnTrack.remainingAmount == 4000)
        #expect(statusOnTrack.healthState == .onTrack)
        #expect(!statusOnTrack.isWarning)
        #expect(!statusOnTrack.isOverBudget)

        // At 85%: Warning
        let statusWarning = BudgetStatus(budget: budget, spentAmount: 8500)
        #expect(statusWarning.utilizationPercentage == 0.85)
        #expect(statusWarning.remainingAmount == 1500)
        #expect(statusWarning.healthState == .warning)
        #expect(statusWarning.isWarning)
        #expect(!statusWarning.isOverBudget)

        // Over 100%: Over Budget
        let statusOver = BudgetStatus(budget: budget, spentAmount: 12000)
        #expect(statusOver.utilizationPercentage == 1.20)
        #expect(statusOver.remainingAmount == 0)
        #expect(statusOver.healthState == .overBudget)
        #expect(statusOver.isOverBudget)
    }

    // MARK: - AI Coach UseCase Tests
    @Test func aiCoachFinancialContextAssembly() {
        let now = Date()
        let transactions = [
            Transaction(title: "Salary", amount: 150000, type: .income, category: .salary, date: now),
            Transaction(title: "Rent", amount: 35000, type: .expense, category: .rent, date: now),
            Transaction(title: "Dining", amount: 7850, type: .expense, category: .dining, date: now)
        ]
        let budgets = [
            Budget(category: .dining, limitAmount: 10000, month: now.month, year: now.year)
        ]
        let profile = FinancialProfile(currencyCode: "INR", monthlyIncomeTarget: 150000, monthlySavingsTarget: 45000)

        let useCase = AICoachUseCase()
        let context = useCase.buildFinancialContext(transactions: transactions, budgets: budgets, profile: profile, referenceDate: now)

        #expect(context.currencyCode == "INR")
        #expect(context.currentMonthTotalIncome == 150000)
        #expect(context.currentMonthTotalExpense == 42850)
        #expect(context.currentMonthSavings == 107150)
        #expect(context.topSpendingCategories.count == 2)
        #expect(context.activeBudgets.count == 1)
    }

    @Test func aiCoachHeuristicDiningResponse() {
        let now = Date()
        let prev = now.previousMonthStart
        let transactions = [
            Transaction(title: "Swiggy", amount: 7850, type: .expense, category: .dining, date: now),
            Transaction(title: "Swiggy", amount: 6330, type: .expense, category: .dining, date: prev)
        ]
        let profile = FinancialProfile()
        let useCase = AICoachUseCase()

        let response = useCase.generateSmartHeuristicResponse(
            prompt: "How much did I spend on dining out?",
            transactions: transactions,
            budgets: [],
            profile: profile,
            referenceDate: now
        )

        #expect(response.replyText.contains("7,850") || response.replyText.contains("7850"))
        #expect(response.structuredInsight != nil)
        #expect(response.structuredInsight?.type == "spending_trend")
        #expect(response.structuredInsight?.category == "dining")
    }

    @Test func aiCoachHeuristic20PercentReduction() {
        let now = Date()
        let transactions = [
            Transaction(title: "Dining", amount: 10000, type: .expense, category: .dining, date: now)
        ]
        let profile = FinancialProfile()
        let useCase = AICoachUseCase()

        let response = useCase.generateSmartHeuristicResponse(
            prompt: "How much can I save if I reduce dining expenses by 20%?",
            transactions: transactions,
            budgets: [],
            profile: profile,
            referenceDate: now
        )

        #expect(response.replyText.contains("2,000") || response.replyText.contains("2000"))
        #expect(response.structuredInsight?.impactAmount == 2000.0)
    }
}
