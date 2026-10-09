//
//  NetworkMonitor.swift
//  FinPilot
//

import Foundation
import Network

@Observable
public final class NetworkMonitor {
    public static let shared = NetworkMonitor()

    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.finpilot.networkmonitor")

    public private(set) var isConnected: Bool = true
    public private(set) var isExpensive: Bool = false

    public init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isConnected = (path.status == .satisfied)
                self?.isExpensive = path.isExpensive
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
