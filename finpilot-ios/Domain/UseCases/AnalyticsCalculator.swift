//
//  AnalyticsCalculator.swift
//  FinPilot
//

import Foundation

public struct MonthlySummary: Equatable {
    public let month: Int
    public let year: Int
    public let totalIncome: Double
    public let totalExpense: Double
    public var netSavings: Double {
        totalIncome - totalExpense
    }
    public var savingsRate: Double {
        guard totalIncome > 0 else { return 0 }
        return max(0, netSavings / totalIncome)
    }

    public init(month: Int, year: Int, totalIncome: Double, totalExpense: Double) {
        self.month = month
        self.year = year
        self.totalIncome = totalIncome
        self.totalExpense = totalExpense
    }
}

public struct CategorySpending: Identifiable, Equatable {
    public var id: String { category.rawValue }
    public let category: TransactionCategory
    public let totalAmount: Double
    public let transactionCount: Int
    public var percentage: Double // 0.0 to 1.0

    public init(category: TransactionCategory, totalAmount: Double, transactionCount: Int, percentage: Double) {
        self.category = category
        self.totalAmount = totalAmount
        self.transactionCount = transactionCount
        self.percentage = percentage
    }
}

public struct DailySpendingPoint: Identifiable, Equatable {
    public var id: Date { date }
    public let date: Date
    public let dayNumber: Int
    public let amount: Double

    public init(date: Date, dayNumber: Int, amount: Double) {
        self.date = date
        self.dayNumber = dayNumber
        self.amount = amount
    }
}

public struct MonthOverMonthComparison: Equatable {
    public let currentMonthTotal: Double
    public let previousMonthTotal: Double
    public var difference: Double {
        currentMonthTotal - previousMonthTotal
    }
    public var percentageChange: Double {
        guard previousMonthTotal > 0 else {
            return currentMonthTotal > 0 ? 100.0 : 0.0
        }
        return ((currentMonthTotal - previousMonthTotal) / previousMonthTotal) * 100.0
    }
    public var isIncrease: Bool {
        difference > 0
    }

    public init(currentMonthTotal: Double, previousMonthTotal: Double) {
        self.currentMonthTotal = currentMonthTotal
        self.previousMonthTotal = previousMonthTotal
    }
}

public enum AnalyticsCalculator {
    public static func calculateMonthlySummary(transactions: [Transaction], for date: Date = Date()) -> MonthlySummary {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        let targetYear = calendar.component(.year, from: date)

        let monthlyTransactions = transactions.filter { tx in
            calendar.component(.month, from: tx.date) == targetMonth &&
            calendar.component(.year, from: tx.date) == targetYear
        }

        var totalIncome: Double = 0
        var totalExpense: Double = 0

        for tx in monthlyTransactions {
            switch tx.type {
            case .income:
                totalIncome += tx.amount
            case .expense:
                totalExpense += tx.amount
            }
        }

        return MonthlySummary(
            month: targetMonth,
            year: targetYear,
            totalIncome: totalIncome,
            totalExpense: totalExpense
        )
    }

    public static func calculateCategoryBreakdown(transactions: [Transaction], for date: Date = Date()) -> [CategorySpending] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        let targetYear = calendar.component(.year, from: date)

        let monthlyExpenses = transactions.filter { tx in
            tx.type == .expense &&
            calendar.component(.month, from: tx.date) == targetMonth &&
            calendar.component(.year, from: tx.date) == targetYear
        }

        let totalExpense = monthlyExpenses.reduce(0.0) { $0 + $1.amount }

        var grouped: [TransactionCategory: (amount: Double, count: Int)] = [:]
        for tx in monthlyExpenses {
            let current = grouped[tx.category] ?? (amount: 0.0, count: 0)
            grouped[tx.category] = (amount: current.amount + tx.amount, count: current.count + 1)
        }

        let list = grouped.map { (cat, val) -> CategorySpending in
            let pct = totalExpense > 0 ? (val.amount / totalExpense) : 0
            return CategorySpending(
                category: cat,
                totalAmount: val.amount,
                transactionCount: val.count,
                percentage: pct
            )
        }

        return list.sorted { $0.totalAmount > $1.totalAmount }
    }

    public static func calculateDailySpendingTrend(transactions: [Transaction], for date: Date = Date()) -> [DailySpendingPoint] {
        let calendar = Calendar.current
        let targetMonth = calendar.component(.month, from: date)
        let targetYear = calendar.component(.year, from: date)

        let monthlyExpenses = transactions.filter { tx in
            tx.type == .expense &&
            calendar.component(.month, from: tx.date) == targetMonth &&
            calendar.component(.year, from: tx.date) == targetYear
        }

        guard let monthInterval = calendar.dateInterval(of: .month, for: date) else {
            return []
        }

        let range = calendar.range(of: .day, in: .month, for: date) ?? 1..<31
        let numberOfDays = range.count

        var points: [DailySpendingPoint] = []
        var dayMap: [Int: Double] = [:]

        for tx in monthlyExpenses {
            let day = calendar.component(.day, from: tx.date)
            dayMap[day, default: 0.0] += tx.amount
        }

        for day in 1...numberOfDays {
            if let dayDate = calendar.date(byAdding: .day, value: day - 1, to: monthInterval.start) {
                let amount = dayMap[day] ?? 0.0
                points.append(DailySpendingPoint(date: dayDate, dayNumber: day, amount: amount))
            }
        }

        return points
    }

    public static func compareMonthOverMonth(transactions: [Transaction], referenceDate: Date = Date()) -> MonthOverMonthComparison {
        let currentSummary = calculateMonthlySummary(transactions: transactions, for: referenceDate)
        let previousMonthDate = referenceDate.previousMonthStart
        let prevSummary = calculateMonthlySummary(transactions: transactions, for: previousMonthDate)

        return MonthOverMonthComparison(
            currentMonthTotal: currentSummary.totalExpense,
            previousMonthTotal: prevSummary.totalExpense
        )
    }

    public static func calculateCategoryMonthOverMonth(
        transactions: [Transaction],
        category: TransactionCategory,
        referenceDate: Date = Date()
    ) -> MonthOverMonthComparison {
        let calendar = Calendar.current
        let curMonth = calendar.component(.month, from: referenceDate)
        let curYear = calendar.component(.year, from: referenceDate)

        let prevDate = referenceDate.previousMonthStart
        let prevMonth = calendar.component(.month, from: prevDate)
        let prevYear = calendar.component(.year, from: prevDate)

        let curTotal = transactions
            .filter { $0.category == category && $0.type == .expense && calendar.component(.month, from: $0.date) == curMonth && calendar.component(.year, from: $0.date) == curYear }
            .reduce(0.0) { $0 + $1.amount }

        let prevTotal = transactions
            .filter { $0.category == category && $0.type == .expense && calendar.component(.month, from: $0.date) == prevMonth && calendar.component(.year, from: $0.date) == prevYear }
            .reduce(0.0) { $0 + $1.amount }

        return MonthOverMonthComparison(
            currentMonthTotal: curTotal,
            previousMonthTotal: prevTotal
        )
    }
}
