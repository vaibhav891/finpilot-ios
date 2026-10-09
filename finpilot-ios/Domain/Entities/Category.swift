//
//  Category.swift
//  FinPilot
//

import SwiftUI

public enum TransactionCategory: String, CaseIterable, Identifiable, Codable {
    case food = "food"
    case dining = "dining"
    case groceries = "groceries"
    case transport = "transport"
    case shopping = "shopping"
    case entertainment = "entertainment"
    case utilities = "utilities"
    case rent = "rent"
    case healthcare = "healthcare"
    case education = "education"
    case travel = "travel"
    case investments = "investments"
    case salary = "salary"
    case freelance = "freelance"
    case other = "other"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .food: return "Food"
        case .dining: return "Dining Out"
        case .groceries: return "Groceries"
        case .transport: return "Transport"
        case .shopping: return "Shopping"
        case .entertainment: return "Entertainment"
        case .utilities: return "Bills & Utilities"
        case .rent: return "Rent & Housing"
        case .healthcare: return "Healthcare"
        case .education: return "Education"
        case .travel: return "Travel"
        case .investments: return "Investments"
        case .salary: return "Salary"
        case .freelance: return "Freelance"
        case .other: return "Other"
        }
    }

    public var iconName: String {
        switch self {
        case .food: return "cup.and.saucer.fill"
        case .dining: return "fork.knife"
        case .groceries: return "cart.fill"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "film.fill"
        case .utilities: return "bolt.fill"
        case .rent: return "house.fill"
        case .healthcare: return "cross.case.fill"
        case .education: return "book.fill"
        case .travel: return "airplane"
        case .investments: return "chart.line.uptrend.xyaxis"
        case .salary: return "banknote.fill"
        case .freelance: return "laptopcomputer"
        case .other: return "ellipsis.circle.fill"
        }
    }

    public var colorHex: String {
        switch self {
        case .food: return "#FF6B6B"
        case .dining: return "#FA5252"
        case .groceries: return "#20C997"
        case .transport: return "#4DABF7"
        case .shopping: return "#BE4BDB"
        case .entertainment: return "#FCC419"
        case .utilities: return "#FD7E14"
        case .rent: return "#495057"
        case .healthcare: return "#E03131"
        case .education: return "#15AABF"
        case .travel: return "#12B886"
        case .investments: return "#40C057"
        case .salary: return "#2B8A3E"
        case .freelance: return "#339AF0"
        case .other: return "#868E96"
        }
    }

    public var color: Color {
        Color(hex: colorHex)
    }

    public var isExpenseByDefault: Bool {
        switch self {
        case .salary, .freelance:
            return false
        default:
            return true
        }
    }
}
