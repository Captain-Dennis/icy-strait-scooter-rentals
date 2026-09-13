import Foundation
import SwiftData

enum RentalStatus: String, Codable {
    case active
    case completed
}

@Model
final class Rental {
    @Attribute(.unique) var rentalID: UUID
    var scooterID: String
    var scooterName: String
    var startedAt: Date
    var endedAt: Date?
    var returnToken: String
    var customerEmail: String
    var statusRaw: String

    var posAuthorizationID: String?
    var posChargeID: String?
    var capturedAmount: Decimal?
    var lastQuotedAmount: Decimal

    var isSeededSample: Bool

    @Relationship(deleteRule: .cascade, inverse: \AgreementAcceptance.rental)
    var acceptances: [AgreementAcceptance] = []

    @Relationship(deleteRule: .cascade, inverse: \ReturnPhoto.rental)
    var returnPhotos: [ReturnPhoto] = []

    init(
        rentalID: UUID = UUID(),
        scooterID: String,
        scooterName: String,
        startedAt: Date,
        endedAt: Date? = nil,
        returnToken: String,
        customerEmail: String = "guest@icystraitscooters.example",
        status: RentalStatus = .active,
        posAuthorizationID: String? = nil,
        posChargeID: String? = nil,
        capturedAmount: Decimal? = nil,
        lastQuotedAmount: Decimal = BillingCalculator.firstHour,
        isSeededSample: Bool = false
    ) {
        self.rentalID = rentalID
        self.scooterID = scooterID
        self.scooterName = scooterName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.returnToken = returnToken
        self.customerEmail = customerEmail
        self.statusRaw = status.rawValue
        self.posAuthorizationID = posAuthorizationID
        self.posChargeID = posChargeID
        self.capturedAmount = capturedAmount
        self.lastQuotedAmount = lastQuotedAmount
        self.isSeededSample = isSeededSample
    }

    var status: RentalStatus {
        get { RentalStatus(rawValue: statusRaw) ?? .active }
        set { statusRaw = newValue.rawValue }
    }

    var isActive: Bool { endedAt == nil && status == .active }

    /// Walk-up checkout does not collect a legal name. Use the email if it is not the demo guest.
    var renterLabel: String {
        let email = customerEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        if email.isEmpty || email == "guest@icystraitscooters.example" {
            return "Guest"
        }
        return email
    }

    var returnPayload: QRPayload {
        .returnRental(rentalID: rentalID, token: returnToken)
    }

    func snapshot() -> RentalSnapshot {
        RentalSnapshot(id: rentalID, scooterID: scooterID, startedAt: startedAt, endedAt: endedAt)
    }

    func elapsed(at now: Date) -> TimeInterval {
        let end = endedAt ?? now
        return max(0, end.timeIntervalSince(startedAt))
    }

    func quotedCharge(at now: Date) -> Decimal {
        if let capturedAmount { return capturedAmount }
        return BillingCalculator.charge(elapsed: elapsed(at: now))
    }

    func acceptedSectionIDs() -> Set<AgreementSectionID> {
        Set(acceptances.compactMap { AgreementSectionID(rawValue: $0.sectionID) })
    }
}

@Model
final class AgreementAcceptance {
    var sectionID: String
    var sectionTitle: String
    var acceptedAt: Date
    var rental: Rental?

    init(sectionID: AgreementSectionID, acceptedAt: Date, rental: Rental? = nil) {
        self.sectionID = sectionID.rawValue
        self.sectionTitle = sectionID.title
        self.acceptedAt = acceptedAt
        self.rental = rental
    }
}

@Model
final class POSLedgerEntry {
    @Attribute(.unique) var entryID: UUID
    var rentalID: UUID
    var kindRaw: String
    var amount: Decimal
    var providerReference: String
    var createdAt: Date
    var note: String

    init(
        entryID: UUID = UUID(),
        rentalID: UUID,
        kind: POSLedgerKind,
        amount: Decimal,
        providerReference: String,
        createdAt: Date = .now,
        note: String
    ) {
        self.entryID = entryID
        self.rentalID = rentalID
        self.kindRaw = kind.rawValue
        self.amount = amount
        self.providerReference = providerReference
        self.createdAt = createdAt
        self.note = note
    }

    var kind: POSLedgerKind {
        POSLedgerKind(rawValue: kindRaw) ?? .authorize
    }
}

enum POSLedgerKind: String, Codable {
    case authorize
    case capture
    case cancel
}
