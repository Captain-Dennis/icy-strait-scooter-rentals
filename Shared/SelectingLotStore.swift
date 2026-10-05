import Foundation

/// Live pipe for both apps.
/// Prefers CloudKit when this binary is CloudKit-entitled and Prefer CloudKit is on.
/// Entitled Release builds start with that switch on. A failed CloudKit call retries on HTTP.
actor SelectingLotStore: SharedLotStore {
    nonisolated var providerName: String { SharedPipeConfig.liveStoreName }

    private let http: any SharedLotStore
    private let makeCloudKit: @Sendable () -> any SharedLotStore
    private var cloudKit: (any SharedLotStore)?

    init(http: any SharedLotStore, makeCloudKit: @escaping @Sendable () -> any SharedLotStore) {
        self.http = http
        self.makeCloudKit = makeCloudKit
    }

    func snapshot() async throws -> LotSnapshot {
        try await withFallback { try await $0.snapshot() }
    }

    func publish(_ event: RentalLifecycleEvent) async throws {
        try await withFallback { try await $0.publish(event) }
    }

    func publishAlert(_ alert: StaffAlertRecord) async throws {
        try await withFallback { try await $0.publishAlert(alert) }
    }

    func upsertStaff(_ member: SharedStaffMember) async throws {
        try await withFallback { try await $0.upsertStaff(member) }
    }

    func replaceStaff(_ members: [SharedStaffMember]) async throws {
        try await withFallback { try await $0.replaceStaff(members) }
    }

    private func withFallback<T>(_ work: (any SharedLotStore) async throws -> T) async throws -> T {
        guard SharedPipeConfig.usesCloudKit else {
            return try await work(http)
        }
        do {
            return try await work(cloudKitStore())
        } catch let cloudError {
            do {
                return try await work(http)
            } catch let httpError {
                throw SharedLotStoreError.unreachable(
                    "CloudKit failed (\(cloudError.localizedDescription)). HTTP fallback failed (\(httpError.localizedDescription))."
                )
            }
        }
    }

    private func cloudKitStore() -> any SharedLotStore {
        if let cloudKit { return cloudKit }
        let created = makeCloudKit()
        cloudKit = created
        return created
    }
}
