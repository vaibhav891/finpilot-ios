//
//  DateExtensions.swift
//  FinPilot
//

import Foundation

public extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let nextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .second, value: -1, to: nextMonth) ?? self
    }

    var previousMonthStart: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: -1, to: startOfMonth) ?? self
    }

    var previousMonthEnd: Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .second, value: -1, to: startOfMonth) ?? self
    }

    var month: Int {
        Calendar.current.component(.month, from: self)
    }

    var year: Int {
        Calendar.current.component(.year, from: self)
    }

    var day: Int {
        Calendar.current.component(.day, from: self)
    }

    func isSameMonth(as otherDate: Date) -> Bool {
        let calendar = Calendar.current
        let c1 = calendar.dateComponents([.year, .month], from: self)
        let c2 = calendar.dateComponents([.year, .month], from: otherDate)
        return c1.year == c2.year && c1.month == c2.month
    }

    func dateByAdding(days: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: self) ?? self
    }

    func dateByAdding(months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }
}
