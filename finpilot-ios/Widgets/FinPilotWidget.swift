//
//  FinPilotWidget.swift
//  FinPilot
//

import WidgetKit
import SwiftUI

public struct FinPilotWidgetEntry: TimelineEntry {
    public let date: Date
    public let totalSpent: Double
    public let remainingBudget: Double
    public let budgetUtilization: Double
    public let currencyCode: String

    public init(
        date: Date = Date(),
        totalSpent: Double = 35240,
        remainingBudget: Double = 9760,
        budgetUtilization: Double = 0.78,
        currencyCode: String = "INR"
    ) {
        self.date = date
        self.totalSpent = totalSpent
        self.remainingBudget = remainingBudget
        self.budgetUtilization = budgetUtilization
        self.currencyCode = currencyCode
    }
}

public struct FinPilotWidgetProvider: TimelineProvider {
    public typealias Entry = FinPilotWidgetEntry

    public init() {}

    public func placeholder(in context: Context) -> FinPilotWidgetEntry {
        FinPilotWidgetEntry()
    }

    public func getSnapshot(in context: Context, completion: @escaping (FinPilotWidgetEntry) -> Void) {
        completion(FinPilotWidgetEntry())
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<FinPilotWidgetEntry>) -> Void) {
        let entry = FinPilotWidgetEntry(
            date: Date(),
            totalSpent: 42350,
            remainingBudget: 12650,
            budgetUtilization: 0.77,
            currencyCode: "INR"
        )
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

public struct FinPilotWidgetEntryView: View {
    public var entry: FinPilotWidgetEntry

    public init(entry: FinPilotWidgetEntry) {
        self.entry = entry
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color(hex: "#6366F1"))
                    Text("FinPilot")
                        .font(.caption2)
                        .fontWeight(.heavy)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("\(Int(entry.budgetUtilization * 100))%")
                    .font(.caption2)
                    .fontWeight(.bold)
                    .foregroundColor(entry.budgetUtilization >= 0.85 ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                Text("SPENT THIS MONTH")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.secondary)
                Text("₹\(Int(entry.totalSpent))")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }

            // Mini Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 5)
                    Capsule()
                        .fill(entry.budgetUtilization >= 0.85 ? Color(hex: "#EF4444") : Color(hex: "#10B981"))
                        .frame(width: min(geo.size.width, geo.size.width * CGFloat(entry.budgetUtilization)), height: 5)
                }
            }
            .frame(height: 5)

            HStack {
                Text("₹\(Int(entry.remainingBudget)) left")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
    }
}
