//
//  DemoDataSeeder.swift
//  FinPilot
//

import Foundation
import SwiftData

@MainActor
public final class DemoDataSeeder {
    public static let shared = DemoDataSeeder()

    private init() {}

    public func seedInitialDataIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<SDTransaction>()
        do {
            let existingCount = try context.fetchCount(descriptor)
            if existingCount > 0 {
                return // Already seeded
            }
            seedData(context: context)
        } catch {
            print("Error checking seed state: \(error.localizedDescription)")
        }
    }

    public func resetAndReseed(context: ModelContext) {
        do {
            try context.delete(model: SDTransaction.self)
            try context.delete(model: SDBudget.self)
            try context.delete(model: SDFinancialProfile.self)
            try context.delete(model: SDAIInsight.self)
            try context.delete(model: SDSyncQueueItem.self)
            try context.save()
            seedData(context: context)
        } catch {
            print("Failed to reset and reseed: \(error.localizedDescription)")
        }
    }

    public func seedData(context: ModelContext) {
        let now = Date()
        let calendar = Calendar.current
        let curMonth = calendar.component(.month, from: now)
        let curYear = calendar.component(.year, from: now)

        // 1. Profile
        let profile = SDFinancialProfile(
            userId: "user_demo_01",
            displayName: "Vaibhav Sultania",
            email: "vaibhav@finpilot.io",
            currencyCode: "INR",
            monthlyIncomeTarget: 175000,
            monthlySavingsTarget: 50000,
            isBiometricEnabled: false,
            isPushNotificationsEnabled: true,
            budgetWarningThreshold: 0.85,
            lastSyncedAt: now
        )
        context.insert(profile)

        // 2. Budgets for Current Month
        let budgets: [SDBudget] = [
            SDBudget(categoryRaw: TransactionCategory.dining.rawValue, limitAmount: 10000, month: curMonth, year: curYear),
            SDBudget(categoryRaw: TransactionCategory.groceries.rawValue, limitAmount: 12000, month: curMonth, year: curYear),
            SDBudget(categoryRaw: TransactionCategory.shopping.rawValue, limitAmount: 8000, month: curMonth, year: curYear),
            SDBudget(categoryRaw: TransactionCategory.entertainment.rawValue, limitAmount: 4000, month: curMonth, year: curYear),
            SDBudget(categoryRaw: TransactionCategory.transport.rawValue, limitAmount: 5000, month: curMonth, year: curYear),
            SDBudget(categoryRaw: TransactionCategory.utilities.rawValue, limitAmount: 6000, month: curMonth, year: curYear)
        ]
        budgets.forEach { context.insert($0) }

        // 3. Transactions: Current Month
        var sampleTransactions: [SDTransaction] = [
            // Income
            SDTransaction(
                title: "Tech Lead Salary",
                amount: 150000,
                typeRaw: TransactionType.income.rawValue,
                categoryRaw: TransactionCategory.salary.rawValue,
                date: now.startOfMonth.dateByAdding(days: 1),
                merchant: "Acme Corp Ltd",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "iOS Architecture Consulting",
                amount: 25000,
                typeRaw: TransactionType.income.rawValue,
                categoryRaw: TransactionCategory.freelance.rawValue,
                date: now.startOfMonth.dateByAdding(days: 4),
                merchant: "Fintech Client",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),

            // Fixed Expenses
            SDTransaction(
                title: "Apartment Rent",
                amount: 35000,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.rent.rawValue,
                date: now.startOfMonth.dateByAdding(days: 2),
                merchant: "Landlord",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Zerodha Nifty 50 Index SIP",
                amount: 25000,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.investments.rawValue,
                date: now.startOfMonth.dateByAdding(days: 5),
                merchant: "Zerodha Broking",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),

            // Dining (High spending: ₹7,850 total so far)
            SDTransaction(
                title: "Swiggy Gourmet Dinner",
                amount: 2450,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: now.dateByAdding(days: -1),
                notes: "Dinner with team",
                merchant: "Swiggy",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Zomato Weekend Treat",
                amount: 1850,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: now.dateByAdding(days: -3),
                merchant: "Zomato",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Bombay Canteen Lunch",
                amount: 2850,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: now.dateByAdding(days: -6),
                merchant: "The Bombay Canteen",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Blue Tokai Coffee & Croissant",
                amount: 700,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: now.dateByAdding(days: -8),
                merchant: "Blue Tokai Coffee Roasters",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),

            // Groceries (₹6,320)
            SDTransaction(
                title: "Nature's Basket Organic Groceries",
                amount: 3800,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.groceries.rawValue,
                date: now.dateByAdding(days: -4),
                merchant: "Nature's Basket",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Blinkit Quick Essentials",
                amount: 1420,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.groceries.rawValue,
                date: now.dateByAdding(days: -2),
                merchant: "Blinkit",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Zepto Fresh Dairy & Fruits",
                amount: 1100,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.groceries.rawValue,
                date: now.dateByAdding(days: -7),
                merchant: "Zepto",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),

            // Transport (₹2,850)
            SDTransaction(
                title: "Uber Premier to BKC",
                amount: 850,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.transport.rawValue,
                date: now.dateByAdding(days: -1),
                merchant: "Uber India",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Airport Cab Ride",
                amount: 1500,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.transport.rawValue,
                date: now.dateByAdding(days: -5),
                merchant: "Uber India",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Metro Smartcard Auto-Topup",
                amount: 500,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.transport.rawValue,
                date: now.dateByAdding(days: -9),
                merchant: "Metro Transit",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),

            // Shopping (₹6,490)
            SDTransaction(
                title: "Zara Autumn Jacket",
                amount: 5490,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.shopping.rawValue,
                date: now.dateByAdding(days: -5),
                merchant: "Zara Retail",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Amazon Kindle Book Purchase",
                amount: 1000,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.shopping.rawValue,
                date: now.dateByAdding(days: -7),
                merchant: "Amazon India",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),

            // Utilities (₹4,950)
            SDTransaction(
                title: "Tata Power Electricity Bill",
                amount: 3450,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.utilities.rawValue,
                date: now.startOfMonth.dateByAdding(days: 3),
                merchant: "Tata Power",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Airtel Xstream Fiber",
                amount: 1500,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.utilities.rawValue,
                date: now.startOfMonth.dateByAdding(days: 4),
                merchant: "Airtel Telecommunications",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),

            // Entertainment (₹2,798)
            SDTransaction(
                title: "PVR INOX IMAX Tickets",
                amount: 1600,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.entertainment.rawValue,
                date: now.dateByAdding(days: -3),
                merchant: "PVR Cinemas",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Netflix & Apple One Subscriptions",
                amount: 1198,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.entertainment.rawValue,
                date: now.startOfMonth.dateByAdding(days: 2),
                merchant: "Apple Services",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),

            // Healthcare (₹2,100)
            SDTransaction(
                title: "Apollo Pharmacy Health Supplements",
                amount: 2100,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.healthcare.rawValue,
                date: now.dateByAdding(days: -4),
                merchant: "Apollo 24|7",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            )
        ]

        // 4. Previous Month Transactions (for Month-over-Month comparison)
        let prevStart = now.previousMonthStart
        sampleTransactions.append(contentsOf: [
            SDTransaction(
                title: "Tech Lead Salary",
                amount: 150000,
                typeRaw: TransactionType.income.rawValue,
                categoryRaw: TransactionCategory.salary.rawValue,
                date: prevStart.dateByAdding(days: 1),
                merchant: "Acme Corp Ltd",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Apartment Rent",
                amount: 35000,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.rent.rawValue,
                date: prevStart.dateByAdding(days: 2),
                merchant: "Landlord",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Zerodha SIP",
                amount: 25000,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.investments.rawValue,
                date: prevStart.dateByAdding(days: 5),
                merchant: "Zerodha",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            ),
            // Previous month dining total was ₹6,330 (current month ₹7,850 is exactly 24% higher!)
            SDTransaction(
                title: "Swiggy Orders",
                amount: 3100,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: prevStart.dateByAdding(days: 8),
                merchant: "Swiggy",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Dining Out",
                amount: 3230,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.dining.rawValue,
                date: prevStart.dateByAdding(days: 15),
                merchant: "Indigo Deli",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Supermarket Groceries",
                amount: 9800,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.groceries.rawValue,
                date: prevStart.dateByAdding(days: 10),
                merchant: "D-Mart",
                paymentMethodRaw: PaymentMethod.creditCard.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Transport Cabs",
                amount: 3400,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.transport.rawValue,
                date: prevStart.dateByAdding(days: 12),
                merchant: "Uber India",
                paymentMethodRaw: PaymentMethod.upi.rawValue,
                isSynced: true
            ),
            SDTransaction(
                title: "Utilities",
                amount: 4500,
                typeRaw: TransactionType.expense.rawValue,
                categoryRaw: TransactionCategory.utilities.rawValue,
                date: prevStart.dateByAdding(days: 4),
                merchant: "Tata Power",
                paymentMethodRaw: PaymentMethod.netBanking.rawValue,
                isSynced: true
            )
        ])

        sampleTransactions.forEach { context.insert($0) }

        // 5. Featured AI Insight
        let insight = SDAIInsight(
            typeRaw: InsightType.spendingTrend.rawValue,
            title: "Dining Expenses Surge (+24%)",
            summary: "Your dining expenses are 24% higher than last month. You have spent ₹7,850 so far.",
            severityRaw: InsightSeverity.medium.rawValue,
            recommendations: [
                "You're at 78% of your ₹10,000 monthly dining budget.",
                "Swapping two weekend deliveries with cooking can save ~₹2,200.",
                "Consider setting a daily food delivery cap on weekdays."
            ],
            categoryRaw: TransactionCategory.dining.rawValue,
            impactAmount: 7850,
            generatedAt: now
        )
        context.insert(insight)

        do {
            try context.save()
        } catch {
            print("Failed to save seeded data: \(error.localizedDescription)")
        }
    }
}
