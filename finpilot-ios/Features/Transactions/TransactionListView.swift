//
//  TransactionListView.swift
//  FinPilot
//

import SwiftUI

public struct TransactionListView: View {
    @Bindable public var viewModel: TransactionListViewModel
    @State private var showingAddTransaction = false
    @State private var selectedTransactionForEdit: Transaction?
    @State private var selectedTransactionForDetail: Transaction?

    public init(viewModel: TransactionListViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filters Header
                    headerFilters

                    if viewModel.isLoading && viewModel.transactions.isEmpty {
                        FPLoadingView(message: "Loading transactions...")
                    } else if viewModel.filteredTransactions.isEmpty {
                        FPEmptyStateView(
                            icon: "tray.fill",
                            title: "No Transactions Found",
                            message: viewModel.searchQuery.isEmpty ? "No transactions in this category." : "No results matching '\(viewModel.searchQuery)'.",
                            actionTitle: "Add Transaction"
                        ) {
                            showingAddTransaction = true
                        }
                    } else {
                        transactionList
                    }
                }
            }
            .navigationTitle("Transactions")
            .searchable(text: $viewModel.searchQuery, prompt: "Search title, merchant, notes...")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        FPHaptics.light()
                        showingAddTransaction = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(FPTheme.Colors.primaryAccent)
                    }
                }
            }
            .sheet(isPresented: $showingAddTransaction) {
                AddEditTransactionView(
                    repository: SwiftDataStack.shared.makeTransactionRepository(),
                    budgetRepository: SwiftDataStack.shared.makeBudgetRepository(),
                    onSaveSuccess: {
                        Task {
                            await viewModel.loadTransactions()
                        }
                    }
                )
            }
            .sheet(item: $selectedTransactionForDetail) { tx in
                NavigationStack {
                    TransactionDetailView(transaction: tx) {
                        Task {
                            await viewModel.deleteTransaction(id: tx.id)
                        }
                    }
                }
            }
            .task {
                await viewModel.loadTransactions()
            }
            .refreshable {
                await viewModel.loadTransactions()
            }
        }
    }

    // MARK: - Subviews
    private var headerFilters: some View {
        VStack(spacing: 12) {
            // Type Segmented Picker
            Picker("Filter Type", selection: $viewModel.selectedFilter) {
                ForEach(TransactionFilterType.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            // Category Chips ScrollView
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    // "All" chip
                    Button {
                        FPHaptics.light()
                        viewModel.selectedCategory = nil
                    } label: {
                        Text("All Categories")
                            .font(.system(size: 13, weight: viewModel.selectedCategory == nil ? .bold : .medium))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(viewModel.selectedCategory == nil ? FPTheme.Colors.primaryAccent : FPTheme.Colors.secondaryBackground)
                            .foregroundColor(viewModel.selectedCategory == nil ? .white : .primary)
                            .clipShape(Capsule())
                    }

                    ForEach(TransactionCategory.allCases) { cat in
                        Button {
                            FPHaptics.light()
                            viewModel.selectedCategory = (viewModel.selectedCategory == cat ? nil : cat)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: cat.iconName)
                                    .font(.system(size: 12))
                                Text(cat.displayName)
                                    .font(.system(size: 13, weight: viewModel.selectedCategory == cat ? .bold : .medium))
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(viewModel.selectedCategory == cat ? cat.color : cat.color.opacity(0.12))
                            .foregroundColor(viewModel.selectedCategory == cat ? .white : cat.color)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
            .padding(.bottom, 8)
        }
        .padding(.top, 4)
        .background(FPTheme.Colors.background)
    }

    private var transactionList: some View {
        List {
            ForEach(viewModel.filteredTransactions) { tx in
                Button {
                    selectedTransactionForDetail = tx
                } label: {
                    transactionRow(tx: tx)
                }
                .listRowBackground(FPTheme.Colors.cardBackground)
                .listRowSeparatorTint(FPTheme.Colors.cardBorder)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        Task {
                            await viewModel.deleteTransaction(id: tx.id)
                        }
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
    }

    private func transactionRow(tx: Transaction) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(tx.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: tx.category.iconName)
                    .font(.system(size: 18))
                    .foregroundColor(tx.category.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(tx.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(AppDateFormatters.shortDate.string(from: tx.date))
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                    Text(tx.paymentMethod.rawValue)
                        .font(.caption2)
                        .foregroundColor(FPTheme.Colors.subtleText)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(CurrencyFormatter.string(from: tx.amount, currencyCode: "INR", showSign: true))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(tx.type == .income ? FPTheme.Colors.mint : .primary)

                if !tx.isSynced {
                    HStack(spacing: 3) {
                        Image(systemName: "icloud.slash")
                            .font(.system(size: 9))
                        Text("Local")
                            .font(.system(size: 9, weight: .medium))
                    }
                    .foregroundColor(FPTheme.Colors.subtleText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
