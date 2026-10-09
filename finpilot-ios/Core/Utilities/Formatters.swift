//
//  Formatters.swift
//  FinPilot
//

import SwiftUI

public enum CurrencyFormatter {
    public static func string(from amount: Double, currencyCode: String = "INR", showSign: Bool = false) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 0
        formatter.locale = Locale(identifier: "en_IN")

        let absAmount = abs(amount)
        let formatted = formatter.string(from: NSNumber(value: absAmount)) ?? "₹\(Int(absAmount))"

        if showSign {
            if amount > 0 {
                return "+\(formatted)"
            } else if amount < 0 {
                return "-\(formatted)"
            }
        }
        return formatted
    }

    public static func compactString(from amount: Double, currencyCode: String = "INR") -> String {
        let absVal = abs(amount)
        let sign = amount < 0 ? "-" : ""
        if absVal >= 10000000 { // 1 Crore
            return String(format: "%@₹%.2f Cr", sign, absVal / 10000000.0)
        } else if absVal >= 100000 { // 1 Lakh
            return String(format: "%@₹%.1f L", sign, absVal / 100000.0)
        } else if absVal >= 1000 { // 1K
            return String(format: "%@₹%.1f k", sign, absVal / 1000.0)
        } else {
            return string(from: amount, currencyCode: currencyCode)
        }
    }
}

public enum AppDateFormatters {
    public static let displayDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    public static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        return formatter
    }()

    public static let monthYear: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    public static var fullMonthYear: DateFormatter { monthYear }

    public static let shortMonth: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM"
        return formatter
    }()

    public static let timeOnly: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    public static var shortTime: DateFormatter { timeOnly }
}

public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
