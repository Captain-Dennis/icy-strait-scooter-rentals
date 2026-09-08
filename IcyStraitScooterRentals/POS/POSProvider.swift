import Foundation

protocol POSProvider: Sendable {
    var providerName: String { get }
    func startCheckout(rentalID: UUID, scooterID: String, estimatedAmount: Decimal) async throws -> POSAuthorization
    func finalizeCharge(authorizationID: String, finalAmount: Decimal) async throws -> POSCharge
    func cancelCheckout(authorizationID: String) async throws
}

struct POSAuthorization: Equatable, Sendable {
    var id: String
    var amount: Decimal
    var createdAt: Date
}

struct POSCharge: Equatable, Sendable {
    var id: String
    var authorizationID: String
    var amount: Decimal
    var createdAt: Date
}

enum POSError: LocalizedError, Equatable {
    case declined(String)
    case unknownAuthorization
    case alreadyCaptured
    case cancelled

    var errorDescription: String? {
        switch self {
        case .declined(let message):
            return message
        case .unknownAuthorization:
            return "That payment authorization is no longer available."
        case .alreadyCaptured:
            return "This rental was already charged."
        case .cancelled:
            return "The authorization was voided."
        }
    }
}
