//
//  AddEditTransactionView.swift
//  FinPilot
//

import SwiftUI

public struct AddEditTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    private let repository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private let existingTransaction: Transaction?
    private let onSaveSuccess: (() -> Void)?

    @State private var title: String = ""
    @State private var amountString: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: TransactionCategory = .dining
    @State private var date: Date = Date()
    @State private var merchant: String = ""
    @State private var paymentMethod: PaymentMethod = .upi
    @State private var notes: String = ""
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false

    public init(
        repository: TransactionRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        existingTransaction: Transaction? = nil,
        onSaveSuccess: (() -> Void)? = nil
    ) {
        self.repository = repository
        self.budgetRepository = budgetRepository
        self.existingTransaction = existingTransaction
        self.onSaveSuccess = onSaveSuccess

        if let tx = existingTransaction {
            _title = State(initialValue: tx.title)
            _amountString = State(initialValue: String(format: "%.0f", tx.amount))
            _type = State(initialValue: tx.type)
            _category = State(initialValue: tx.category)
            _date = State(initialValue: tx.date)
            _merchant = State(initialValue: tx.merchant ?? "")
            _paymentMethod = State(initialValue: tx.paymentMethod)
            _notes = State(initialValue: tx.notes ?? "")
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Type Selector
                        Picker("Type", selection: $type) {
                            Text("Expense").tag(TransactionType.expense)
                            Text("Income").tag(TransactionType.income)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Amount Card
                        VStack(spacing: 8) {
                            Text("AMOUNT (₹)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(FPTheme.Colors.subtleText)

                            HStack(alignment: .center, spacing: 4) {
                                Text("₹")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(type == .income ? FPTheme.Colors.mint : FPTheme.Colors.coral)

                                TextField("0", text: $amountString)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.decimalPad)
                                    .foregroundColor(type == .income ? FPTheme.Colors.mint : .primary)
                                    .frame(maxWidth: 220)
                            }
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(FPTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large)
                                .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)

                        // Details Form
                        VStack(alignment: .leading, spacing: 16) {
                            // Title
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Description / Title")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)
                                TextField("e.g. Swiggy Gourmet, Rent", text: $title)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(FPTheme.Colors.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                            }

                            // Category Selector
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)

                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 10) {
                                        ForEach(availableCategories) { cat in
                                            categoryChip(cat: cat)
                                        }
                                    }
                                }
                            }

                            // Payment Method
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Payment Method")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)

                                Picker("Payment Method", selection: $paymentMethod) {
                                    ForEach(PaymentMethod.allCases) { method in
                                        Text(method.rawValue).tag(method)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(10)
                                .background(FPTheme.Colors.secondaryBackground)
                                .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                            }

                            // Merchant
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Merchant (Optional)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)
                                TextField("e.g. Zomato, Amazon, Uber", text: $merchant)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(FPTheme.Colors.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                            }

                            // Date
                            DatePicker("Transaction Date", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.compact)

                            // Notes
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Notes (Optional)")
                                    .font(.caption)
                                    .fontWeight(.medium)
                                    .foregroundColor(FPTheme.Colors.subtleText)
                                TextField("Additional details", text: $notes)
                                    .textFieldStyle(.plain)
                                    .padding(12)
                                    .background(FPTheme.Colors.secondaryBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                            }
                        }
                        .fpCard()
                        .padding(.horizontal, 16)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(FPTheme.Colors.coral)
                                .padding(.horizontal, 16)
                        }

                        // Save Button
                        FPButton(
                            title: existingTransaction == nil ? "Add Transaction" : "Save Changes",
                            icon: "checkmark",
                            isLoading: isSaving
                        ) {
                            Task {
                                await saveTransaction()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(existingTransaction == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var availableCategories: [TransactionCategory] {
        if type == .expense {
            return TransactionCategory.allCases.filter { $0 != .salary && $0 != .freelance }
        } else {
            return [.salary, .freelance, .investments, .other]
        }
    }

    private func categoryChip(cat: TransactionCategory) -> some View {
        let isSelected = category == cat
        return Button {
            FPHaptics.light()
            category = cat
        } label: {
            HStack(spacing: 6) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 13))
                Text(cat.displayName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? cat.color : cat.color.opacity(0.12))
            .foregroundColor(isSelected ? .white : cat.color)
            .clipShape(Capsule())
        }
    }

    private func saveTransaction() async {
        guard let amount = Double(amountString), amount > 0 else {
            errorMessage = "Please enter a valid amount greater than 0."
            return
        }

        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = "Please enter a description for this transaction."
            return
        }

        isSaving = true
        errorMessage = nil

        let transaction = Transaction(
            id: existingTransaction?.id ?? UUID(),
            title: cleanTitle,
            amount: amount,
            type: type,
            category: category,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            merchant: merchant.isEmpty ? nil : merchant,
            paymentMethod: paymentMethod,
            createdAt: existingTransaction?.createdAt ?? Date(),
            updatedAt: Date(),
            isSynced: false
        )

        do {
            if existingTransaction != nil {
                try await repository.updateTransaction(transaction)
            } else {
                try await repository.addTransaction(transaction)
            }

            // Check if this expense triggers a budget warning
            if type == .expense {
                checkBudgetThreshold(for: category, additionalAmount: amount)
            }

            FPHaptics.success()
            onSaveSuccess?()
            dismiss()
        } catch {
            errorMessage = "Failed to save: \(error.localizedDescription)"
        }

        isSaving = false
    }

    private func checkBudgetThreshold(for category: TransactionCategory, additionalAmount: Double) {
        Task {
            let calendar = Calendar.current
            let curMonth = calendar.component(.month, from: date)
            let curYear = calendar.component(.year, from: date)

            if let budgets = try? await budgetRepository.getBudgets(month: curMonth, year: curYear),
               let budget = budgets.first(where: { $0.category == category }) {
                let transactions = (try? await repository.getTransactions()) ?? []
                let spent = transactions
                    .filter { $0.category == category && $0.type == .expense && calendar.component(.month, from: $0.date) == curMonth && calendar.component(.year, from: $0.date) == curYear }
                    .reduce(0.0) { $0 + $1.amount }

                let utilization = budget.limitAmount > 0 ? (spent / budget.limitAmount) : 0
                if utilization >= 0.85 {
                    let remaining = max(0, budget.limitAmount - spent)
                    NotificationManager.shared.sendBudgetWarning(
                        category: category,
                        utilizationPercentage: utilization,
                        remainingAmount: remaining
                    )
                }
            }
        }
    }
}
