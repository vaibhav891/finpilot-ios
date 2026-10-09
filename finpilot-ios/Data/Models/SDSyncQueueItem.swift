//
//  SDSyncQueueItem.swift
//  FinPilot
//

import Foundation
import SwiftData

@Model
public final class SDSyncQueueItem {
    @Attribute(.unique) public var id: UUID
    public var entityType: String // "transaction", "budget", "profile"
    public var entityId: String
    public var action: String // "create", "update", "delete"
    public var payloadJSON: String
    public var createdAt: Date
    public var retryCount: Int

    public init(
        id: UUID = UUID(),
        entityType: String,
        entityId: String,
        action: String,
        payloadJSON: String,
        createdAt: Date = Date(),
        retryCount: Int = 0
    ) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.action = action
        self.payloadJSON = payloadJSON
        self.createdAt = createdAt
        self.retryCount = retryCount
    }
}
