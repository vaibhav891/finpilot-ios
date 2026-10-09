//
//  Transaction.swift
//  FinPilot
//

import Foundation

public enum TransactionType: String, Codable, CaseIterable {
    case expense = "expense"
    case income = "income"

    public var title: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

public enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    public var id: String { rawValue }
    case upi = "UPI"
    case creditCard = "Credit Card"
    case debitCard = "Debit Card"
    case netBanking = "Net Banking"
    case cash = "Cash"
    case other = "Other"

    public var systemIcon: String {
        switch self {
        case .upi: return "qrcode"
        case .creditCard: return "creditcard.fill"
        case .debitCard: return "creditcard"
        case .netBanking: return "building.columns.fill"
        case .cash: return "banknote"
        case .other: return "ellipsis.circle"
        }
    }
}

public struct Transaction: Identifiable, Codable, Equatable, Hashable {
    public let id: UUID
    public var title: String
    public var amount: Double
    public var type: TransactionType
    public var category: TransactionCategory
    public var date: Date
    public var notes: String?
    public var merchant: String?
    public var paymentMethod: PaymentMethod
    public var userId: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isSynced: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        type: TransactionType,
        category: TransactionCategory,
        date: Date = Date(),
        notes: String? = nil,
        merchant: String? = nil,
        paymentMethod: PaymentMethod = .upi,
        userId: String = "local_user",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isSynced: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.type = type
        self.category = category
        self.date = date
        self.notes = notes
        self.merchant = merchant
        self.paymentMethod = paymentMethod
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }
}
