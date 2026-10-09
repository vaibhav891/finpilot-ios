//
//  AICoachUseCase.swift
//  FinPilot
//

import Foundation

public final class AICoachUseCase {
    public static let disclaimerText = "FinPilot provides informational insights based on your activity and is not financial, investment, tax, or legal advice."

    public init() {}

    public func buildFinancialContext(
        transactions: [Transaction],
        budgets: [Budget],
        profile: FinancialProfile,
        referenceDate: Date = Date()
    ) -> FinancialContextPayload {
        let summary = AnalyticsCalculator.calculateMonthlySummary(transactions: transactions, for: referenceDate)
        let categoryBreakdown = AnalyticsCalculator.calculateCategoryBreakdown(transactions: transactions, for: referenceDate)

        let topCategoriesDTO = categoryBreakdown.prefix(5).map { item in
            CategorySpendingDTO(
                category: item.category.displayName,
                amount: item.totalAmount,
                percentage: item.percentage
            )
        }

        let recentTxDTO = transactions.prefix(10).map { tx in
            TransactionSummaryDTO(
                title: tx.title,
                amount: tx.amount,
                category: tx.category.displayName,
                date: AppDateFormatters.shortDate.string(from: tx.date)
            )
        }

        let calendar = Calendar.current
        let curMonth = calendar.component(.month, from: referenceDate)
        let curYear = calendar.component(.year, from: referenceDate)

        let activeBudgetsDTO = budgets.filter { $0.month == curMonth && $0.year == curYear }.map { b in
            let spent = transactions
                .filter { $0.category == b.category && $0.type == .expense && calendar.component(.month, from: $0.date) == curMonth && calendar.component(.year, from: $0.date) == curYear }
                .reduce(0.0) { $0 + $1.amount }
            let utilization = b.limitAmount > 0 ? (spent / b.limitAmount) : 0
            return BudgetStatusDTO(
                category: b.category.displayName,
                limitAmount: b.limitAmount,
                spentAmount: spent,
                utilizationPercentage: utilization
            )
        }

        let goal = "Income Target: ₹\(Int(profile.monthlyIncomeTarget)), Savings Target: ₹\(Int(profile.monthlySavingsTarget))"

        return FinancialContextPayload(
            currencyCode: profile.currencyCode,
            currentMonthTotalIncome: summary.totalIncome,
            currentMonthTotalExpense: summary.totalExpense,
            currentMonthSavings: summary.netSavings,
            topSpendingCategories: topCategoriesDTO,
            recentTransactions: recentTxDTO,
            activeBudgets: activeBudgetsDTO,
            userGoalSummary: goal
        )
    }

    public func generateSmartHeuristicResponse(
        prompt: String,
        transactions: [Transaction],
        budgets: [Budget],
        profile: FinancialProfile,
        referenceDate: Date = Date()
    ) -> AICoachResponsePayload {
        let lower = prompt.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        let summary = AnalyticsCalculator.calculateMonthlySummary(transactions: transactions, for: referenceDate)
        let breakdown = AnalyticsCalculator.calculateCategoryBreakdown(transactions: transactions, for: referenceDate)
        let mom = AnalyticsCalculator.compareMonthOverMonth(transactions: transactions, referenceDate: referenceDate)

        // 1. "Where am I spending the most?"
        if lower.contains("where") && lower.contains("spending") || lower.contains("top spending") || lower.contains("highest spending") {
            if let top = breakdown.first {
                let formattedAmt = CurrencyFormatter.string(from: top.totalAmount, currencyCode: profile.currencyCode)
                let pct = Int(top.percentage * 100)
                let insight = AIInsightDTO(
                    type: "spending_trend",
                    title: "Highest Expense: \(top.category.displayName)",
                    summary: "You have spent \(formattedAmt) on \(top.category.displayName), accounting for \(pct)% of your total outflow this month.",
                    severity: "medium",
                    recommendations: [
                        "Consider setting a category budget for \(top.category.displayName).",
                        "Review recurring subscriptions or merchants in this category."
                    ],
                    category: top.category.rawValue,
                    impactAmount: top.totalAmount
                )
                return AICoachResponsePayload(
                    replyText: "Your highest spending category this month is **\(top.category.displayName)** at **\(formattedAmt)** (\(pct)% of all expenses). Next is \(breakdown.dropFirst().first?.category.displayName ?? "others").",
                    structuredInsight: insight
                )
            }
        }

        // 2. "Why did I spend more this month?"
        if lower.contains("why") && (lower.contains("more") || lower.contains("increase") || lower.contains("higher")) {
            let diffStr = CurrencyFormatter.string(from: abs(mom.difference), currencyCode: profile.currencyCode)
            if mom.isIncrease {
                // Find category with biggest increase
                var topIncreasedCat: (category: TransactionCategory, diff: Double)?
                for item in breakdown {
                    let catMom = AnalyticsCalculator.calculateCategoryMonthOverMonth(transactions: transactions, category: item.category, referenceDate: referenceDate)
                    if catMom.isIncrease {
                        if let currentMax = topIncreasedCat {
                            if catMom.difference > currentMax.diff {
                                topIncreasedCat = (item.category, catMom.difference)
                            }
                        } else {
                            topIncreasedCat = (item.category, catMom.difference)
                        }
                    }
                }

                let reasonCat = topIncreasedCat?.category.displayName ?? "Dining & Shopping"
                let insight = AIInsightDTO(
                    type: "spending_trend",
                    title: "Spending Increase Detected",
                    summary: "Your total spending is up by \(Int(mom.percentageChange))% (\(diffStr)) compared to last month, driven largely by \(reasonCat).",
                    severity: "high",
                    recommendations: [
                        "Review recent transactions in \(reasonCat).",
                        "Postpone non-essential shopping purchases until next month."
                    ],
                    category: topIncreasedCat?.category.rawValue,
                    impactAmount: mom.difference
                )
                return AICoachResponsePayload(
                    replyText: "Your expenses are up by **\(Int(mom.percentageChange))%** (\(diffStr)) compared to last month. The biggest driver is higher spending in **\(reasonCat)**.",
                    structuredInsight: insight
                )
            } else {
                return AICoachResponsePayload(
                    replyText: "Great news! Your total spending is actually down by **\(Int(abs(mom.percentageChange)))%** compared to last month. You're doing a great job managing cash flow.",
                    structuredInsight: nil
                )
            }
        }

        // 3. "How much can I save if I reduce dining expenses by 20%?"
        if lower.contains("reduce") || lower.contains("save") && lower.contains("20") || lower.contains("20%") {
            let diningSpent = transactions
                .filter { ($0.category == .dining || $0.category == .food) && $0.type == .expense && $0.date.isSameMonth(as: referenceDate) }
                .reduce(0.0) { $0 + $1.amount }
            let potentialSavings = diningSpent * 0.20
            let annualSavings = potentialSavings * 12
            let savedStr = CurrencyFormatter.string(from: potentialSavings, currencyCode: profile.currencyCode)
            let annualStr = CurrencyFormatter.string(from: annualSavings, currencyCode: profile.currencyCode)

            let insight = AIInsightDTO(
                type: "saving_opportunity",
                title: "20% Dining Cut = \(savedStr)/mo",
                summary: "Cutting 20% of current dining out saves \(savedStr) monthly or \(annualStr) annually toward your investments.",
                severity: "tip",
                recommendations: [
                    "Swap 2 restaurant delivery orders per week with home-cooked meals.",
                    "Auto-invest the \(savedStr) difference into a recurring deposit or index SIP."
                ],
                category: TransactionCategory.dining.rawValue,
                impactAmount: potentialSavings
            )

            return AICoachResponsePayload(
                replyText: "If you trim your dining and food delivery expenses by 20%, you will save **\(savedStr) this month** and **\(annualStr) over a year**!",
                structuredInsight: insight
            )
        }

        // 4. "How much did I spend on food / dining last month?"
        if lower.contains("food") || lower.contains("dining") {
            let diningTx = transactions.filter { ($0.category == .food || $0.category == .dining) && $0.type == .expense }
            let thisMonthDining = diningTx.filter { $0.date.isSameMonth(as: referenceDate) }.reduce(0.0) { $0 + $1.amount }
            let prevMonthDining = diningTx.filter { $0.date.isSameMonth(as: referenceDate.previousMonthStart) }.reduce(0.0) { $0 + $1.amount }
            let formattedCur = CurrencyFormatter.string(from: thisMonthDining, currencyCode: profile.currencyCode)
            let formattedPrev = CurrencyFormatter.string(from: prevMonthDining, currencyCode: profile.currencyCode)

            let diffPct = prevMonthDining > 0 ? Int(((thisMonthDining - prevMonthDining) / prevMonthDining) * 100) : 0
            let insight = AIInsightDTO(
                type: "spending_trend",
                title: "Dining Spending Analysis",
                summary: diffPct > 0 ? "Your dining expenses are \(diffPct)% higher than last month. You have spent \(formattedCur) so far." : "Your dining expenses are well managed at \(formattedCur).",
                severity: diffPct > 20 ? "medium" : "low",
                recommendations: [
                    "Target home cooking during weekdays.",
                    "Set a weekly dining cap to avoid month-end budget pressure."
                ],
                category: TransactionCategory.dining.rawValue,
                impactAmount: thisMonthDining
            )

            return AICoachResponsePayload(
                replyText: "You have spent **\(formattedCur)** on food & dining this month (compared to \(formattedPrev) last month). That represents an change of **\(diffPct)%**.",
                structuredInsight: insight
            )
        }

        // 5. "Give me three suggestions to reduce my expenses" / "suggestions"
        if lower.contains("suggestion") || lower.contains("reduce") || lower.contains("tips") {
            let insight = AIInsightDTO(
                type: "saving_opportunity",
                title: "3 Actionable Expense Reductions",
                summary: "Targeting your highest discretionary categories can immediately boost your monthly savings rate.",
                severity: "tip",
                recommendations: [
                    "1. Consolidate food deliveries and dining out into planned weekend treats.",
                    "2. Audit active digital streaming and utility subscriptions for unused plans.",
                    "3. Pay credit card balances in full before the billing cycle to eliminate interest."
                ],
                category: nil,
                impactAmount: 5000
            )

            return AICoachResponsePayload(
                replyText: "Here are 3 tailored recommendations for your profile:\n\n1. **Food & Dining**: Cap weekend deliveries with a ₹2,000 weekly budget.\n2. **Subscription Audit**: Check recurring OTT and app subscriptions.\n3. **UPI Quick-Pay Awareness**: Track micro-transactions under ₹200 which quietly accumulate.",
                structuredInsight: insight
            )
        }

        // Generic intelligent fallback
        let netSavingsStr = CurrencyFormatter.string(from: summary.netSavings, currencyCode: profile.currencyCode)
        let rateStr = "\(Int(summary.savingsRate * 100))%"
        return AICoachResponsePayload(
            replyText: "Looking at your records for this month: You have logged **\(CurrencyFormatter.string(from: summary.totalIncome, currencyCode: profile.currencyCode))** in income and **\(CurrencyFormatter.string(from: summary.totalExpense, currencyCode: profile.currencyCode))** in expenses. Your net savings stand at **\(netSavingsStr)** (\(rateStr) savings rate).\n\nAsk me anything specific like *'Where am I spending the most?'* or *'How can I save 15% more?'*",
            structuredInsight: nil
        )
    }
}
