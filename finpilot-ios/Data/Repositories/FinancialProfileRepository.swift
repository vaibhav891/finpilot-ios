//
//  FinancialProfileRepository.swift
//  FinPilot
//

import Foundation

@MainActor
public protocol FinancialProfileRepositoryProtocol {
    func getProfile() async throws -> FinancialProfile
    func updateProfile(_ profile: FinancialProfile) async throws
}

@MainActor
public final class FinancialProfileRepository: FinancialProfileRepositoryProtocol {
    private let localDataSource: LocalDataSourceProtocol
    private let remoteDataSource: RemoteDataSourceProtocol

    public init(
        localDataSource: LocalDataSourceProtocol,
        remoteDataSource: RemoteDataSourceProtocol = MockRemoteDataSource.shared
    ) {
        self.localDataSource = localDataSource
        self.remoteDataSource = remoteDataSource
    }

    public func getProfile() async throws -> FinancialProfile {
        if let local = try localDataSource.fetchProfile() {
            return local
        }
        let defaultProfile = FinancialProfile()
        try localDataSource.saveProfile(defaultProfile)
        return defaultProfile
    }

    public func updateProfile(_ profile: FinancialProfile) async throws {
        try localDataSource.saveProfile(profile)
        if NetworkMonitor.shared.isConnected {
            try? await remoteDataSource.uploadProfile(profile)
        }
    }
}
