//
//  FirebaseFunctionClient.swift
//  FinPilot
//

import Foundation

public struct FinancialContextPayload: Codable {
    public let currencyCode: String
    public let currentMonthTotalIncome: Double
    public let currentMonthTotalExpense: Double
    public let currentMonthSavings: Double
    public let topSpendingCategories: [CategorySpendingDTO]
    public let recentTransactions: [TransactionSummaryDTO]
    public let activeBudgets: [BudgetStatusDTO]
    public let userGoalSummary: String

    public init(
        currencyCode: String,
        currentMonthTotalIncome: Double,
        currentMonthTotalExpense: Double,
        currentMonthSavings: Double,
        topSpendingCategories: [CategorySpendingDTO],
        recentTransactions: [TransactionSummaryDTO],
        activeBudgets: [BudgetStatusDTO],
        userGoalSummary: String
    ) {
        self.currencyCode = currencyCode
        self.currentMonthTotalIncome = currentMonthTotalIncome
        self.currentMonthTotalExpense = currentMonthTotalExpense
        self.currentMonthSavings = currentMonthSavings
        self.topSpendingCategories = topSpendingCategories
        self.recentTransactions = recentTransactions
        self.activeBudgets = activeBudgets
        self.userGoalSummary = userGoalSummary
    }
}

public struct CategorySpendingDTO: Codable {
    public let category: String
    public let amount: Double
    public let percentage: Double

    public init(category: String, amount: Double, percentage: Double) {
        self.category = category
        self.amount = amount
        self.percentage = percentage
    }
}

public struct TransactionSummaryDTO: Codable {
    public let title: String
    public let amount: Double
    public let category: String
    public let date: String

    public init(title: String, amount: Double, category: String, date: String) {
        self.title = title
        self.amount = amount
        self.category = category
        self.date = date
    }
}

public struct BudgetStatusDTO: Codable {
    public let category: String
    public let limitAmount: Double
    public let spentAmount: Double
    public let utilizationPercentage: Double

    public init(category: String, limitAmount: Double, spentAmount: Double, utilizationPercentage: Double) {
        self.category = category
        self.limitAmount = limitAmount
        self.spentAmount = spentAmount
        self.utilizationPercentage = utilizationPercentage
    }
}

public struct AICoachRequestPayload: Codable {
    public let userPrompt: String
    public let financialContext: FinancialContextPayload
    public let history: [ChatMessageDTO]

    public init(userPrompt: String, financialContext: FinancialContextPayload, history: [ChatMessageDTO]) {
        self.userPrompt = userPrompt
        self.financialContext = financialContext
        self.history = history
    }
}

public struct ChatMessageDTO: Codable {
    public let role: String // "user" or "assistant"
    public let content: String

    public init(role: String, content: String) {
        self.role = role
        self.content = content
    }
}

public struct AICoachResponsePayload: Codable {
    public let replyText: String
    public let structuredInsight: AIInsightDTO?

    public init(replyText: String, structuredInsight: AIInsightDTO? = nil) {
        self.replyText = replyText
        self.structuredInsight = structuredInsight
    }
}

public struct AIInsightDTO: Codable {
    public let type: String
    public let title: String
    public let summary: String
    public let severity: String
    public let recommendations: [String]
    public let category: String?
    public let impactAmount: Double?

    public init(
        type: String,
        title: String,
        summary: String,
        severity: String,
        recommendations: [String],
        category: String? = nil,
        impactAmount: Double? = nil
    ) {
        self.type = type
        self.title = title
        self.summary = summary
        self.severity = severity
        self.recommendations = recommendations
        self.category = category
        self.impactAmount = impactAmount
    }
}

public enum NetworkError: LocalizedError {
    case invalidURL
    case serverError(statusCode: Int, message: String)
    case decodingError(Error)
    case offline
    case unauthorized

    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Cloud Function URL endpoint."
        case .serverError(let code, let msg):
            return "Server responded with error (\(code)): \(msg)"
        case .decodingError(let err):
            return "Failed to parse response: \(err.localizedDescription)"
        case .offline:
            return "Device is offline. Connect to internet to reach cloud services."
        case .unauthorized:
            return "Authentication required. Please sign in again."
        }
    }
}

public final class FirebaseFunctionClient {
    public static let shared = FirebaseFunctionClient()

    // Configurable endpoint pointing to deployed Firebase Cloud Function or emulator
    public var cloudFunctionBaseURL: String = "https://us-central1-finpilot-ai.cloudfunctions.net"

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    public func callAICoach(
        request: AICoachRequestPayload,
        authToken: String? = nil
    ) async throws -> AICoachResponsePayload {
        guard let url = URL(string: "\(cloudFunctionBaseURL)/askAICoach") else {
            throw NetworkError.invalidURL
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")

        if let token = authToken {
            urlRequest.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        let encoder = JSONEncoder()
        urlRequest.httpBody = try encoder.encode(request)

        let (data, response) = try await session.data(for: urlRequest)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.serverError(statusCode: -1, message: "Invalid HTTP response")
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown server error"
            throw NetworkError.serverError(statusCode: httpResponse.statusCode, message: errorText)
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(AICoachResponsePayload.self, from: data)
        } catch {
            throw NetworkError.decodingError(error)
        }
    }
}
