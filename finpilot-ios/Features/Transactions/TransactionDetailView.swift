//
//  TransactionDetailView.swift
//  FinPilot
//

import SwiftUI

public struct TransactionDetailView: View {
    public let transaction: Transaction
    public var currencyCode: String = "INR"
    public var onDelete: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteAlert = false

    public init(transaction: Transaction, currencyCode: String = "INR", onDelete: (() -> Void)? = nil) {
        self.transaction = transaction
        self.currencyCode = currencyCode
        self.onDelete = onDelete
    }

    public var body: some View {
        ZStack {
            FPTheme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header Badge & Amount
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(transaction.category.color.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: transaction.category.iconName)
                                .font(.system(size: 32))
                                .foregroundColor(transaction.category.color)
                        }

                        Text(CurrencyFormatter.string(from: transaction.amount, currencyCode: currencyCode, showSign: true))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundColor(transaction.type == .income ? FPTheme.Colors.mint : .primary)

                        Text(transaction.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        FPBadge(
                            text: transaction.type.title,
                            icon: transaction.type == .income ? "arrow.down.left" : "arrow.up.right",
                            color: transaction.type == .income ? FPTheme.Colors.mint : FPTheme.Colors.coral
                        )
                    }
                    .padding(.top, 24)

                    // Details Card
                    VStack(spacing: 16) {
                        detailRow(title: "Category", value: transaction.category.displayName, icon: "tag.fill")
                        Divider()
                        detailRow(title: "Date", value: AppDateFormatters.displayDate.string(from: transaction.date), icon: "calendar")
                        Divider()
                        detailRow(title: "Payment Method", value: transaction.paymentMethod.rawValue, icon: "creditcard.fill")
                        if let merchant = transaction.merchant, !merchant.isEmpty {
                            Divider()
                            detailRow(title: "Merchant", value: merchant, icon: "building.2.fill")
                        }
                        if let notes = transaction.notes, !notes.isEmpty {
                            Divider()
                            detailRow(title: "Notes", value: notes, icon: "note.text")
                        }
                        Divider()
                        detailRow(
                            title: "Sync Status",
                            value: transaction.isSynced ? "Cloud Synced" : "Pending Sync (Local)",
                            icon: transaction.isSynced ? "checkmark.icloud.fill" : "icloud.slash.fill"
                        )
                    }
                    .fpCard()
                    .padding(.horizontal, 16)

                    // Delete Button
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "trash")
                            Text("Delete Transaction")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(FPTheme.Colors.coral)
                        .padding(.vertical, 14)
                        .frame(maxWidth: .infinity)
                        .background(FPTheme.Colors.cardBackground)
                        .clipShape(RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium))
                        .overlay(
                            RoundedRectangle(cornerRadius: FPTheme.CornerRadius.medium)
                                .stroke(FPTheme.Colors.coral.opacity(0.3), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                }
            }
        }
        .navigationTitle("Details")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Delete Transaction?", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete?()
                dismiss()
            }
        } message: {
            Text("Are you sure you want to delete '\(transaction.title)'? This will update your balances and budgets.")
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(FPTheme.Colors.subtleText)
                    .frame(width: 20)
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(FPTheme.Colors.subtleText)
            }
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .multilineTextAlignment(.trailing)
        }
    }
}
