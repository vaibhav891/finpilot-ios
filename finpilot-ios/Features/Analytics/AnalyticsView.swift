//
//  AnalyticsView.swift
//  FinPilot
//

import SwiftUI
import Charts

public struct AnalyticsView: View {
    @Bindable public var viewModel: AnalyticsViewModel

    public init(viewModel: AnalyticsViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Month Navigator
                        monthNavigator

                        // Income vs Expenses KPI Card
                        incomeVsExpenseCard

                        // Month-over-Month Comparison Card
                        monthOverMonthCard

                        // Category Breakdown Donut Chart
                        categoryBreakdownChartCard

                        // Daily Trend Chart
                        dailySpendingTrendCard

                        // Category List Detail
                        categoryRankedList

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable {
                    await viewModel.loadData()
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ShareLink(item: viewModel.shareableSummaryText) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 15))
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                    }
                    .accessibilityLabel("Export Financial Summary")
                }
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Subviews
    private var monthNavigator: some View {
        HStack {
            Button(action: viewModel.previousMonth) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .bold))
                    .padding(10)
                    .background(FPTheme.Colors.cardBackground)
                    .clipShape(Circle())
            }

            Spacer()

            Text(AppDateFormatters.fullMonthYear.string(from: viewModel.referenceDate))
                .font(.headline)
                .fontWeight(.bold)

            Spacer()

            Button(action: viewModel.nextMonth) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .padding(10)
                    .background(FPTheme.Colors.cardBackground)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 8)
    }

    private var incomeVsExpenseCard: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.down.left")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FPTheme.Colors.mint)
                        Text("Total Inflow")
                            .font(.caption2)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    Text(CurrencyFormatter.string(from: viewModel.monthlySummary.totalIncome))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(FPTheme.Colors.mint)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(FPTheme.Colors.coral)
                        Text("Total Outflow")
                            .font(.caption2)
                            .foregroundColor(FPTheme.Colors.subtleText)
                    }
                    Text(CurrencyFormatter.string(from: viewModel.monthlySummary.totalExpense))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(FPTheme.Colors.coral)
                }
            }

            Divider()

            HStack {
                Text("Savings Rate")
                    .font(.subheadline)
                    .foregroundColor(FPTheme.Colors.subtleText)
                Spacer()
                Text("\(Int(viewModel.monthlySummary.savingsRate * 100))% (\(CurrencyFormatter.string(from: viewModel.monthlySummary.netSavings)) saved)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(viewModel.monthlySummary.netSavings >= 0 ? FPTheme.Colors.mint : FPTheme.Colors.coral)
            }
        }
        .fpCard()
    }

    private var monthOverMonthCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill((viewModel.monthOverMonth.isIncrease ? FPTheme.Colors.coral : FPTheme.Colors.mint).opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: viewModel.monthOverMonth.isIncrease ? "arrow.trend.up.fill" : "arrow.trend.down.fill")
                    .font(.system(size: 18))
                    .foregroundColor(viewModel.monthOverMonth.isIncrease ? FPTheme.Colors.coral : FPTheme.Colors.mint)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Month-over-Month Comparison")
                    .font(.system(size: 15, weight: .semibold))
                Text(
                    viewModel.monthOverMonth.isIncrease
                    ? "Spending is \(Int(abs(viewModel.monthOverMonth.percentageChange)))% higher than last month"
                    : "Spending is \(Int(abs(viewModel.monthOverMonth.percentageChange)))% lower than last month"
                )
                .font(.caption)
                .foregroundColor(FPTheme.Colors.subtleText)
            }

            Spacer()

            Text(
                "\(viewModel.monthOverMonth.isIncrease ? "+" : "-")\(Int(abs(viewModel.monthOverMonth.percentageChange)))%"
            )
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .foregroundColor(viewModel.monthOverMonth.isIncrease ? FPTheme.Colors.coral : FPTheme.Colors.mint)
        }
        .fpCard()
    }

    private var categoryBreakdownChartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Category Breakdown")
                .font(.headline)
                .fontWeight(.bold)

            if viewModel.categoryBreakdown.isEmpty {
                Text("No expense data recorded this month.")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .frame(height: 160)
            } else {
                Chart(viewModel.categoryBreakdown) { item in
                    SectorMark(
                        angle: .value("Amount", item.totalAmount),
                        innerRadius: .ratio(0.60),
                        angularInset: 1.5
                    )
                    .foregroundStyle(item.category.color)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .chartLegend(position: .bottom, alignment: .center, spacing: 12)
            }
        }
        .fpCard()
    }

    private var dailySpendingTrendCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Daily Outflow Trend")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
                Text("Timeline")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
            }

            if viewModel.dailyTrend.isEmpty {
                Text("No data available.")
                    .font(.caption)
                    .foregroundColor(FPTheme.Colors.subtleText)
            } else {
                Chart(viewModel.dailyTrend) { point in
                    BarMark(
                        x: .value("Day", point.dayNumber),
                        y: .value("Amount", point.amount)
                    )
                    .foregroundStyle(FPTheme.Colors.primaryAccent.gradient)
                    .cornerRadius(2)
                }
                .frame(height: 140)
                .chartXAxis {
                    AxisMarks(values: [1, 5, 10, 15, 20, 25, 30])
                }
            }
        }
        .fpCard()
    }

    private var categoryRankedList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Expenses by Category")
                .font(.headline)
                .fontWeight(.bold)

            VStack(spacing: 12) {
                ForEach(viewModel.categoryBreakdown) { item in
                    VStack(spacing: 6) {
                        HStack {
                            ZStack {
                                Circle()
                                    .fill(item.category.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: item.category.iconName)
                                    .font(.system(size: 13))
                                    .foregroundColor(item.category.color)
                            }

                            Text(item.category.displayName)
                                .font(.system(size: 14, weight: .semibold))

                            Spacer()

                            Text(CurrencyFormatter.string(from: item.totalAmount))
                                .font(.system(size: 14, weight: .bold, design: .rounded))

                            Text("(\(Int(item.percentage * 100))%)")
                                .font(.caption2)
                                .foregroundColor(FPTheme.Colors.subtleText)
                        }

                        // Percentage bar
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(FPTheme.Colors.secondaryBackground)
                                    .frame(height: 4)
                                Capsule()
                                    .fill(item.category.color)
                                    .frame(width: max(4, geo.size.width * CGFloat(item.percentage)), height: 4)
                            }
                        }
                        .frame(height: 4)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .fpCard()
    }
}
