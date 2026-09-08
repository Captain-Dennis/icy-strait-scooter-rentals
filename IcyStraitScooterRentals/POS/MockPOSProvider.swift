import Foundation

/// In-app POS stand-in. Swap this type in `POSEnvironment` for Square or Stripe later.
/// No API keys. Transactions live only in memory for the process lifetime.
actor MockPOSProvider: POSProvider {
    nonisolated var providerName: String { "MockPOSProvider" }

    private struct AuthRecord {
        var authorization: POSAuthorization
        var scooterID: String
        var rentalID: UUID
        var captured: POSCharge?
        var voided: Bool
    }

    private var authorizations: [String: AuthRecord] = [:]
    var simulatedDelayNanoseconds: UInt64 = 280_000_000
    var shouldDecline = false

    func startCheckout(rentalID: UUID, scooterID: String, estimatedAmount: Decimal) async throws -> POSAuthorization {
        try await pause()
        if shouldDecline {
            throw POSError.declined("Mock card declined. Try again or use a different mock tender.")
        }
        let auth = POSAuthorization(
            id: "mock_auth_\(UUID().uuidString.prefix(8))",
            amount: estimatedAmount,
            createdAt: .now
        )
        authorizations[auth.id] = AuthRecord(
            authorization: auth,
            scooterID: scooterID,
            rentalID: rentalID,
            captured: nil,
            voided: false
        )
        return auth
    }

    func finalizeCharge(authorizationID: String, finalAmount: Decimal) async throws -> POSCharge {
        try await pause()
        guard var record = authorizations[authorizationID] else {
            throw POSError.unknownAuthorization
        }
        if record.voided { throw POSError.cancelled }
        if let existing = record.captured { throw POSError.alreadyCaptured }
        let charge = POSCharge(
            id: "mock_ch_\(UUID().uuidString.prefix(8))",
            authorizationID: authorizationID,
            amount: finalAmount,
            createdAt: .now
        )
        record.captured = charge
        authorizations[authorizationID] = record
        return charge
    }

    func cancelCheckout(authorizationID: String) async throws {
        try await pause()
        guard var record = authorizations[authorizationID] else {
            throw POSError.unknownAuthorization
        }
        if record.captured != nil { throw POSError.alreadyCaptured }
        record.voided = true
        authorizations[authorizationID] = record
    }

    private func pause() async throws {
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }
    }
}
