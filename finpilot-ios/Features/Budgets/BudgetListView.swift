//
//  BudgetListView.swift
//  FinPilot
//

import SwiftUI

public struct BudgetListView: View {
    @Bindable public var viewModel: BudgetViewModel
    @State private var showingAddBudget = false
    @State private var editingBudget: Budget?

    public init(viewModel: BudgetViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Month Overview Card
                        overallBudgetCard

                        if viewModel.isLoading && viewModel.budgets.isEmpty {
                            FPLoadingView(message: "Calculating budgets...")
                        } else if viewModel.budgets.isEmpty {
                            FPEmptyStateView(
                                icon: "chart.bar.xaxis",
                                title: "No Budgets Set",
                                message: "Set category spending limits to track your outflow and receive AI threshold alerts.",
                                actionTitle: "Set Budget"
                            ) {
                                showingAddBudget = true
                            }
                        } else {
                            categoryBudgetsList
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                }
                .refreshable {
                    await viewModel.loadData()
                }
            }
            .navigationTitle("Budgets")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        FPHaptics.light()
                        showingAddBudget = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddBudget) {
                AddEditBudgetView(
                    repository: SwiftDataStack.shared.makeBudgetRepository(),
                    onSaveSuccess: {
                        Task {
                            await viewModel.loadData()
                        }
                    }
                )
            }
            .sheet(item: $editingBudget) { budget in
                AddEditBudgetView(
                    repository: SwiftDataStack.shared.makeBudgetRepository(),
                    existingBudget: budget,
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
    private var overallBudgetCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("OVERALL MONTHLY BUDGET")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(FPTheme.Colors.subtleText)

                    Text(CurrencyFormatter.string(from: viewModel.totalBudgetLimit))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                }
                Spacer()
                ZStack {
                    Circle()
                        .stroke(FPTheme.Colors.cardBorder, lineWidth: 6)
                        .frame(width: 54, height: 54)
                    Circle()
                        .trim(from: 0, to: min(1.0, CGFloat(viewModel.overallUtilization)))
                        .stroke(
                            viewModel.overallUtilization > 1.0 ? FPTheme.Colors.coral :
                            (viewModel.overallUtilization >= 0.85 ? FPTheme.Colors.amber : FPTheme.Colors.mint),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 54, height: 54)

                    Text("\(Int(viewModel.overallUtilization * 100))%")
                        .font(.system(size: 12, weight: .bold))
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Spent So Far")
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                    Text(CurrencyFormatter.string(from: viewModel.totalBudgetSpent))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(viewModel.overallUtilization > 1.0 ? FPTheme.Colors.coral : .primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Remaining")
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                    let remaining = max(0, viewModel.totalBudgetLimit - viewModel.totalBudgetSpent)
                    Text(CurrencyFormatter.string(from: remaining))
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(FPTheme.Colors.mint)
                }
            }
        }
        .fpCard()
    }

    private var categoryBudgetsList: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.budgetProgressList) { item in
                categoryBudgetRow(item: item)
            }
        }
    }

    private func categoryBudgetRow(item: CategoryBudgetProgress) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(item.budget.category.color.opacity(0.15))
                        .frame(width: 38, height: 38)
                    Image(systemName: item.budget.category.iconName)
                        .font(.system(size: 15))
                        .foregroundColor(item.budget.category.color)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(item.budget.category.displayName)
                        .font(.system(size: 16, weight: .semibold))
                    Text("\(CurrencyFormatter.string(from: item.spentAmount)) of \(CurrencyFormatter.string(from: item.budget.limitAmount))")
                        .font(.caption)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }

                Spacer()

                statusBadge(item: item)
            }

            // Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FPTheme.Colors.secondaryBackground)
                        .frame(height: 8)

                    Capsule()
                        .fill(progressColor(for: item.status))
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(item.utilizationPercentage)), height: 8)
                }
            }
            .frame(height: 8)

            HStack {
                Text("\(Int(item.utilizationPercentage * 100))% used")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(progressColor(for: item.status))

                Spacer()

                if item.spentAmount > item.budget.limitAmount {
                    Text("Over by \(CurrencyFormatter.string(from: item.spentAmount - item.budget.limitAmount))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(FPTheme.Colors.coral)
                } else {
                    Text("\(CurrencyFormatter.string(from: item.remainingAmount)) left")
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
            }
        }
        .fpCard()
        .contextMenu {
            Button {
                editingBudget = item.budget
            } label: {
                Label("Edit Budget", systemImage: "pencil")
            }

            Button(role: .destructive) {
                Task {
                    await viewModel.deleteBudget(id: item.budget.id)
                }
            } label: {
                Label("Delete Budget", systemImage: "trash")
            }
        }
    }

    private func statusBadge(item: CategoryBudgetProgress) -> some View {
        let (color, icon, text) = badgeConfig(status: item.status)
        return HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(text)
                .font(.caption2)
                .fontWeight(.bold)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.12))
        .foregroundColor(color)
        .clipShape(Capsule())
    }

    private func badgeConfig(status: BudgetHealthState) -> (Color, String, String) {
        switch status {
        case .onTrack:
            return (FPTheme.Colors.mint, "checkmark.circle.fill", "On Track")
        case .warning:
            return (FPTheme.Colors.amber, "exclamationmark.triangle.fill", "85%+ Used")
        case .overBudget:
            return (FPTheme.Colors.coral, "exclamationmark.octagon.fill", "Over Budget")
        }
    }

    private func progressColor(for status: BudgetHealthState) -> Color {
        switch status {
        case .onTrack: return FPTheme.Colors.mint
        case .warning: return FPTheme.Colors.amber
        case .overBudget: return FPTheme.Colors.coral
        }
    }
}
