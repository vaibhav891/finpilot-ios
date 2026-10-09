//
//  SDTransaction.swift
//  FinPilot
//

import Foundation
import SwiftData

@Model
public final class SDTransaction {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var amount: Double
    public var typeRaw: String
    public var categoryRaw: String
    public var date: Date
    public var notes: String?
    public var merchant: String?
    public var paymentMethodRaw: String
    public var userId: String
    public var createdAt: Date
    public var updatedAt: Date
    public var isSynced: Bool

    public init(
        id: UUID = UUID(),
        title: String,
        amount: Double,
        typeRaw: String,
        categoryRaw: String,
        date: Date = Date(),
        notes: String? = nil,
        merchant: String? = nil,
        paymentMethodRaw: String,
        userId: String = "local_user",
        createdAt: Date = Date(),
        updatedAt: Date = Date(),
        isSynced: Bool = false
    ) {
        self.id = id
        self.title = title
        self.amount = amount
        self.typeRaw = typeRaw
        self.categoryRaw = categoryRaw
        self.date = date
        self.notes = notes
        self.merchant = merchant
        self.paymentMethodRaw = paymentMethodRaw
        self.userId = userId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isSynced = isSynced
    }

    public convenience init(from domain: Transaction) {
        self.init(
            id: domain.id,
            title: domain.title,
            amount: domain.amount,
            typeRaw: domain.type.rawValue,
            categoryRaw: domain.category.rawValue,
            date: domain.date,
            notes: domain.notes,
            merchant: domain.merchant,
            paymentMethodRaw: domain.paymentMethod.rawValue,
            userId: domain.userId,
            createdAt: domain.createdAt,
            updatedAt: domain.updatedAt,
            isSynced: domain.isSynced
        )
    }

    public func toDomain() -> Transaction {
        Transaction(
            id: id,
            title: title,
            amount: amount,
            type: TransactionType(rawValue: typeRaw) ?? .expense,
            category: TransactionCategory(rawValue: categoryRaw) ?? .other,
            date: date,
            notes: notes,
            merchant: merchant,
            paymentMethod: PaymentMethod(rawValue: paymentMethodRaw) ?? .upi,
            userId: userId,
            createdAt: createdAt,
            updatedAt: updatedAt,
            isSynced: isSynced
        )
    }
}
