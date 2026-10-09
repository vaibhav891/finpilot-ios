//
//  DashboardView.swift
//  FinPilot
//

import SwiftUI
import Charts

public struct DashboardView: View {
    @Bindable public var viewModel: DashboardViewModel
    public var onNavigateToAICoach: (() -> Void)?
    public var onNavigateToTransactions: (() -> Void)?
    public var onNavigateToBudgets: (() -> Void)?
    @State private var showingAddTransaction = false

    public init(
        viewModel: DashboardViewModel,
        onNavigateToAICoach: (() -> Void)? = nil,
        onNavigateToTransactions: (() -> Void)? = nil,
        onNavigateToBudgets: (() -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onNavigateToAICoach = onNavigateToAICoach
        self.onNavigateToTransactions = onNavigateToTransactions
        self.onNavigateToBudgets = onNavigateToBudgets
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Hero Net Balance Card
                        heroBalanceCard

                        // 2. Featured AI Insight Card
                        if let insight = viewModel.featuredInsight {
                            InsightCardView(insight: insight) {
                                onNavigateToAICoach?()
                            }
                        }

                        // 3. Monthly Metrics Grid
                        monthlyMetricsGrid

                        // 4. Budget Utilization Card
                        budgetUtilizationCard

                        // 5. Spending Trend Chart Teaser
                        spendingTrendCard

                        // 6. Top Categories Breakdown
                        topCategoriesSection

                        // 7. Recent Transactions List
                        recentTransactionsSection

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable {
                    await viewModel.loadData()
                }
            }
            .navigationTitle("FinPilot")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        FPHaptics.light()
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(FPTheme.Colors.primaryAccent)
                    }
                    .accessibilityLabel("Add Transaction")
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                // Will present AddEditTransactionView
                AddEditTransactionView(
                    repository: SwiftDataStack.shared.makeTransactionRepository(),
                    budgetRepository: SwiftDataStack.shared.makeBudgetRepository(),
                    onSaveSuccess: {
                        Task {
                            await viewModel.loadData()
                        }
                    }
                )
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Subviews
    private var heroBalanceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("TOTAL NET BALANCE")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(.white.opacity(0.7))
                    Text(CurrencyFormatter.string(from: viewModel.totalBalance, currencyCode: viewModel.profile.currencyCode))
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "shield.lefthalf.filled")
                    .font(.system(size: 28))
                    .foregroundColor(FPTheme.Colors.mint.opacity(0.8))
            }

            Divider().background(Color.white.opacity(0.15))

            HStack {
                HStack(spacing: 6) {
                    Circle().fill(FPTheme.Colors.mint).frame(width: 8, height: 8)
                    Text("Income: \(CurrencyFormatter.string(from: viewModel.currentMonthSummary.totalIncome, currencyCode: viewModel.profile.currencyCode))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
                Spacer()
                HStack(spacing: 6) {
                    Circle().fill(FPTheme.Colors.coral).frame(width: 8, height: 8)
                    Text("Spent: \(CurrencyFormatter.string(from: viewModel.currentMonthSummary.totalExpense, currencyCode: viewModel.profile.currencyCode))")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
        }
        .padding(20)
        .background(FPTheme.Gradients.primaryHero)
        .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large, style: .continuous))
        .shadow(color: Color.black.opacity(0.12), radius: 14, x: 0, y: 6)
    }

    private var monthlyMetricsGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            FPStatCard(
                title: "Income this month",
                amount: viewModel.currentMonthSummary.totalIncome,
                currencyCode: viewModel.profile.currencyCode,
                icon: "arrow.down.left",
                iconColor: FPTheme.Colors.mint,
                subtitle: "Monthly"
            )

            FPStatCard(
                title: "Spent this month",
                amount: viewModel.currentMonthSummary.totalExpense,
                currencyCode: viewModel.profile.currencyCode,
                icon: "arrow.up.right",
                iconColor: FPTheme.Colors.coral,
                subtitle: "\(AppDateFormatters.shortMonth.string(from: Date()))"
            )

            FPStatCard(
                title: "Net Savings",
                amount: viewModel.currentMonthSummary.netSavings,
                currencyCode: viewModel.profile.currencyCode,
                icon: "banknote",
                iconColor: FPTheme.Colors.primaryAccent,
                subtitle: "\(Int(viewModel.currentMonthSummary.savingsRate * 100))% saved"
            )

            FPStatCard(
                title: "Savings Target",
                amount: viewModel.profile.monthlySavingsTarget,
                currencyCode: viewModel.profile.currencyCode,
                icon: "target",
                iconColor: FPTheme.Colors.secondaryAccent,
                subtitle: "Goal"
            )
        }
    }

    private var budgetUtilizationCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Budget Utilization")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("\(Int(viewModel.budgetUtilization * 100))% of overall monthly budget used")
                        .font(.caption)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
                Spacer()
                Button("View All") {
                    onNavigateToBudgets?()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(FPTheme.Colors.primaryAccent)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FPTheme.Colors.secondaryBackground)
                        .frame(height: 10)

                    Capsule()
                        .fill(
                            viewModel.budgetUtilization > 1.0 ? FPTheme.Colors.coral :
                            (viewModel.budgetUtilization >= 0.85 ? FPTheme.Colors.amber : FPTheme.Colors.mint)
                        )
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(viewModel.budgetUtilization)), height: 10)
                }
            }
            .frame(height: 10)
        }
        .fpCard()
    }

    private var spendingTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Spending Trend")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Daily Outflow")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
            }

            if viewModel.dailySpendingTrend.isEmpty {
                Text("No spending data logged for this month.")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .frame(height: 100)
            } else {
                Chart(viewModel.dailySpendingTrend) { point in
                    BarMark(
                        x: .value("Day", point.dayNumber),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(FPTheme.Colors.primaryAccent.gradient)
                    .cornerRadius(2)
                }
                .frame(height: 120)
                .chartXAxis {
                    AxisMarks(values: [1, 5, 10, 15, 20, 25, 30])
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let doubleVal = value.as(Double.self) {
                                Text("₹\(Int(doubleVal / 1000))k")
                                    .font(.caption2)
                            }
                        }
                    }
                }
            }
        }
        .fpCard()
    }

    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Top Spending Categories")
                .font(.headline)
                .fontWeight(.bold)

            if viewModel.topSpendingCategories.isEmpty {
                Text("No expenses logged yet.")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.topSpendingCategories) { item in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(item.category.color.opacity(0.15))
                                    .frame(width: 38, height: 38)
                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 15))
                                    .foregroundColor(item.category.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.category.displayName)
                                    .font(.system(size: 14, weight: .semibold))
                                Text("\(item.transactionCount) transactions • \(Int(item.percentage * 100))%")
                                    .font(.caption2)
                                    .foregroundColor(FPTheme.Colors.subtleText)
                            }

                            Spacer()

                            Text(CurrencyFormatter.string(from: item.totalAmount, currencyCode: viewModel.profile.currencyCode))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                    }
                }
            }
        }
        .fpCard()
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Transactions")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Button("See All") {
                    onNavigateToTransactions?()
                }
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(FPTheme.Colors.primaryAccent)
            }

            if viewModel.recentTransactions.isEmpty {
                Text("No recent transactions.")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recentTransactions) { tx in
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(tx.category.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                Image(systemName: tx.category.iconName)
                                    .font(.system(size: 16))
                                    .foregroundColor(tx.category.color)
                            }

                            VStack(alignment: .leading, spacing: 3) {
                                Text(tx.title)
                                    .font(.system(size: 15, weight: .semibold))
                                    .lineLimit(1)
                                Text("\(AppDateFormatters.shortDate.string(from: tx.date)) • \(tx.paymentMethod.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(FPTheme.Colors.subtleText)
                            }

                            Spacer()

                            Text(CurrencyFormatter.string(from: tx.amount, currencyCode: viewModel.profile.currencyCode, showSign: true))
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(tx.type == .income ? FPTheme.Colors.mint : .primary)
                        }
                    }
                }
            }
        }
        .fpCard()
    }
}
