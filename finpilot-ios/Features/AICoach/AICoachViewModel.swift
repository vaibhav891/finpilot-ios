//
//  AICoachViewModel.swift
//  FinPilot
//

import SwiftUI

@Observable
@MainActor
public final class AICoachViewModel {
    public var messages: [AICoachMessage] = []
    public var inputText: String = ""
    public var isThinking: Bool = false
    public var errorMessage: String?

    public let suggestedQuestions: [String] = [
        "Where am I spending the most?",
        "Why did I spend more this month?",
        "How much did I spend on dining out?",
        "How much can I save if I reduce dining expenses by 20%?",
        "Give me three suggestions to reduce my expenses."
    ]

    private let aiCoachRepository: AICoachRepositoryProtocol
    private let transactionRepository: TransactionRepositoryProtocol
    private let budgetRepository: BudgetRepositoryProtocol
    private let profileRepository: FinancialProfileRepositoryProtocol
    private let contextBuilder = AICoachUseCase()

    public init(
        aiCoachRepository: AICoachRepositoryProtocol,
        transactionRepository: TransactionRepositoryProtocol,
        budgetRepository: BudgetRepositoryProtocol,
        profileRepository: FinancialProfileRepositoryProtocol
    ) {
        self.aiCoachRepository = aiCoachRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
        self.profileRepository = profileRepository

        setupInitialGreeting()
    }

    private func setupInitialGreeting() {
        if messages.isEmpty {
            let greeting = AICoachMessage(
                text: "Hello! I'm FinPilot, your AI Personal Finance Coach. I analyze your spending patterns, track your category budgets, and help you find actionable ways to save more.\n\nHow can I help you today?",
                sender: .coach
            )
            messages.append(greeting)
        }
    }

    public func sendMessage(_ promptText: String? = nil) async {
        let question = (promptText ?? inputText).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty else { return }

        // Clear input field if custom entered
        if promptText == nil {
            inputText = ""
        }

        // Add User Message
        let userMessage = AICoachMessage(text: question, sender: .user)
        messages.append(userMessage)
        FPHaptics.light()

        isThinking = true
        errorMessage = nil

        do {
            // 1. Gather domain data for structured context injection
            let transactions = try await transactionRepository.getTransactions()
            let budgets = try await budgetRepository.getBudgets(month: Date().month, year: Date().year)
            let profile = try await profileRepository.getProfile()

            let contextPayload = contextBuilder.buildFinancialContext(
                transactions: transactions,
                budgets: budgets,
                profile: profile
            )

            // 2. Query Repository
            let response = try await aiCoachRepository.askQuestion(
                prompt: question,
                context: contextPayload,
                history: messages
            )

            // 3. Map Structured Insight if present
            var insight: AIInsight?
            if let insightDTO = response.structuredInsight {
                insight = AIInsight(
                    type: InsightType(rawValue: insightDTO.type) ?? .general,
                    title: insightDTO.title,
                    summary: insightDTO.summary,
                    severity: InsightSeverity(rawValue: insightDTO.severity) ?? .medium,
                    recommendations: insightDTO.recommendations,
                    category: insightDTO.category.flatMap { TransactionCategory(rawValue: $0) },
                    impactAmount: insightDTO.impactAmount,
                    generatedAt: Date()
                )
            }

            // 4. Add Coach Reply
            let coachReply = AICoachMessage(
                text: response.replyText,
                sender: .coach,
                structuredInsight: insight
            )
            messages.append(coachReply)
            FPHaptics.medium()
        } catch {
            let fallbackReply = AICoachMessage(
                text: "I encountered an issue processing your request online. Please check your internet connection or try asking again.",
                sender: .coach
            )
            messages.append(fallbackReply)
            errorMessage = error.localizedDescription
        }

        isThinking = false
    }

    public func clearChat() {
        messages.removeAll()
        setupInitialGreeting()
        FPHaptics.light()
    }
}
