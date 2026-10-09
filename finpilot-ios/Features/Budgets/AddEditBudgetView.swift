//
//  AddEditBudgetView.swift
//  FinPilot
//

import SwiftUI

public struct AddEditBudgetView: View {
    @Environment(\.dismiss) private var dismiss

    private let repository: BudgetRepositoryProtocol
    private let existingBudget: Budget?
    private let onSaveSuccess: (() -> Void)?

    @State private var category: TransactionCategory = .dining
    @State private var limitAmountString: String = ""
    @State private var month: Int = Date().month
    @State private var year: Int = Date().year
    @State private var errorMessage: String?
    @State private var isSaving: Bool = false

    public init(
        repository: BudgetRepositoryProtocol,
        existingBudget: Budget? = nil,
        onSaveSuccess: (() -> Void)? = nil
    ) {
        self.repository = repository
        self.existingBudget = existingBudget
        self.onSaveSuccess = onSaveSuccess

        if let b = existingBudget {
            _category = State(initialValue: b.category)
            _limitAmountString = State(initialValue: String(format: "%.0f", b.limitAmount))
            _month = State(initialValue: b.month)
            _year = State(initialValue: b.year)
        }
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                FPTheme.Colors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Limit Amount Card
                        VStack(spacing: 8) {
                            Text("MONTHLY BUDGET LIMIT (₹)")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(FPTheme.Colors.subtleText)

                            HStack(spacing: 4) {
                                Text("₹")
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .foregroundColor(FPTheme.Colors.primaryAccent)

                                TextField("10000", text: $limitAmountString)
                                    .font(.system(size: 40, weight: .bold, design: .rounded))
                                    .keyboardType(.numberPad)
                                    .frame(maxWidth: 220)
                            }
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(FPTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large))
                        .overlay(
                            RoundedRectangle(cornerRadius: FPTheme.CornerRadius.large)
                                .stroke(FPTheme.Colors.cardBorder, lineWidth: 1)
                        )
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                        // Category Selector
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Select Category")
                                .font(.headline)
                                .foregroundColor(.primary)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(selectableCategories) { cat in
                                    categorySelectionButton(cat: cat)
                                }
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

                        FPButton(
                            title: existingBudget == nil ? "Create Budget" : "Update Budget",
                            icon: "checkmark",
                            isLoading: isSaving
                        ) {
                            Task {
                                await saveBudget()
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .navigationTitle(existingBudget == nil ? "Set Category Budget" : "Edit Budget")
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

    private var selectableCategories: [TransactionCategory] {
        TransactionCategory.allCases.filter { $0 != .salary && $0 != .freelance }
    }

    private func categorySelectionButton(cat: TransactionCategory) -> some View {
        let isSelected = category == cat
        return Button {
            FPHaptics.light()
            category = cat
        } label: {
            HStack(spacing: 8) {
                Image(systemName: cat.iconName)
                    .font(.system(size: 14))
                Text(cat.displayName)
                    .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
                Spacer()
            }
            .padding(12)
            .background(isSelected ? cat.color.opacity(0.2) : FPTheme.Colors.secondaryBackground)
            .foregroundColor(isSelected ? cat.color : .primary)
            .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium)
                    .stroke(isSelected ? cat.color : Color.clear, lineWidth: 1.5)
            )
        }
    }

    private func saveBudget() async {
        guard let amount = Double(limitAmountString), amount > 0 else {
            errorMessage = "Please enter a valid budget limit greater than ₹0."
            return
        }

        isSaving = true
        errorMessage = nil

        let budget = Budget(
            id: existingBudget?.id ?? UUID(),
            category: category,
            limitAmount: amount,
            month: month,
            year: year,
            createdAt: existingBudget?.createdAt ?? Date(),
            updatedAt: Date()
        )

        do {
            try await repository.setBudget(budget)
            FPHaptics.success()
            onSaveSuccess?()
            dismiss()
        } catch {
            errorMessage = "Failed to save budget: \(error.localizedDescription)"
        }

        isSaving = false
    }
}
