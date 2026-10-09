//
//  AICoachRepository.swift
//  FinPilot
//

import Foundation

@MainActor
public protocol AICoachRepositoryProtocol {
    func askQuestion(
        prompt: String,
        context: FinancialContextPayload,
        history: [AICoachMessage]
    ) async throws -> AICoachResponsePayload

    func getSavedInsights() async throws -> [AIInsight]
    func saveInsight(_ insight: AIInsight) async throws
}

@MainActor
public final class AICoachRepository: AICoachRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol
    private let useCase: AICoachUseCase

    public init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol = MockRemoteDataSource.shared,
        useCase: AICoachUseCase = AICoachUseCase()
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
        self.useCase = useCase
    }

    public func askQuestion(
        prompt: String,
        context: FinancialContextPayload,
        history: [AICoachMessage]
    ) async throws -> AICoachResponsePayload {
        let historyDTO = history.map {
            ChatMessageDTO(role: $0.sender == .user ? "user" : "assistant", content: $0.text)
        }
        let requestPayload = AICoachRequestPayload(
            userPrompt: prompt,
            financialContext: context,
            history: historyDTO
        )

        // Check if remote call succeeds
        var response: AICoachResponsePayload
        do {
            response = try await remoteDataSource.sendAICoachRequest(request: requestPayload)
        } catch {
            // Fallback to local heuristic engine
            response = useCase.generateSmartHeuristicResponse(
                prompt: prompt,
                transactions: [],
                budgets: [],
                profile: FinancialProfile()
            )
        }

        // Save structured insight if returned
        if let insightDTO = response.structuredInsight {
            let insight = AIInsight(
                type: InsightType(rawValue: insightDTO.type) ?? .general,
                title: insightDTO.title,
                summary: insightDTO.summary,
                severity: InsightSeverity(rawValue: insightDTO.severity) ?? .medium,
                recommendations: insightDTO.recommendations,
                category: insightDTO.category.flatMap { TransactionCategory(rawValue: $0) },
                impactAmount: insightDTO.impactAmount,
                generatedAt: Date()
            )
            try? localDataSource.saveInsight(insight)
        }

        return response
    }

    public func getSavedInsights() async throws -> [AIInsight] {
        try localDataSource.fetchInsights()
    }

    public func saveInsight(_ insight: AIInsight) async throws {
        try localDataSource.saveInsight(insight)
    }
}
