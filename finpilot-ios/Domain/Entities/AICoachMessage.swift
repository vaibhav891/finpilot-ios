//
//  AICoachMessage.swift
//  FinPilot
//

import Foundation

public enum MessageSender: String, Codable {
    case user
    case coach
}

public struct AICoachMessage: Identifiable, Codable, Equatable {
    public let id: UUID
    public let sender: MessageSender
    public let text: String
    public let structuredInsight: AIInsight?
    public let timestamp: Date
    public let isError: Bool

    public init(
        id: UUID = UUID(),
        sender: MessageSender,
        text: String,
        structuredInsight: AIInsight? = nil,
        timestamp: Date = Date(),
        isError: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.structuredInsight = structuredInsight
        self.timestamp = timestamp
        self.isError = isError
    }

    public init(
        id: UUID = UUID(),
        text: String,
        sender: MessageSender,
        structuredInsight: AIInsight? = nil,
        timestamp: Date = Date(),
        isError: Bool = false
    ) {
        self.id = id
        self.sender = sender
        self.text = text
        self.structuredInsight = structuredInsight
        self.timestamp = timestamp
        self.isError = isError
    }
}
