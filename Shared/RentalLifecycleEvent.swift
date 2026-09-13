import Foundation

/// One checkout or return for a single stem-sticker unit.
/// Never represents a shared “any scooter” rental.
struct RentalLifecycleEvent: Codable, Equatable, Identifiable, Sendable {
    enum Kind: String, Codable, Sendable {
        case checkout
        case returned
    }

    var id: UUID
    var kind: Kind
    var scooterID: String
    var scooterName: String
    var rentalID: UUID
    var renterDisplayName: String?
    var startedAt: Date
    var endedAt: Date?
    var occurredAt: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        kind: Kind,
        scooterID: String,
        scooterName: String,
        rentalID: UUID,
        renterDisplayName: String? = nil,
        startedAt: Date,
        endedAt: Date? = nil,
        occurredAt: Date,
        createdAt: Date = .now
    ) {
        self.id = id
        self.kind = kind
        self.scooterID = scooterID
        self.scooterName = scooterName
        self.rentalID = rentalID
        self.renterDisplayName = renterDisplayName
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.occurredAt = occurredAt
        self.createdAt = createdAt
    }

    var unitLabel: String { "\(scooterID) \(scooterName)" }

    var renterLabel: String {
        let trimmed = renterDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Guest" : trimmed
    }

    static func checkout(
        scooterID: String,
        scooterName: String,
        rentalID: UUID,
        renterDisplayName: String?,
        startedAt: Date
    ) -> RentalLifecycleEvent {
        RentalLifecycleEvent(
            kind: .checkout,
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: renterDisplayName,
            startedAt: startedAt,
            endedAt: nil,
            occurredAt: startedAt
        )
    }

    static func returned(
        scooterID: String,
        scooterName: String,
        rentalID: UUID,
        renterDisplayName: String?,
        startedAt: Date,
        endedAt: Date
    ) -> RentalLifecycleEvent {
        RentalLifecycleEvent(
            kind: .returned,
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: renterDisplayName,
            startedAt: startedAt,
            endedAt: endedAt,
            occurredAt: endedAt
        )
    }
}

enum StaffAlertChannel: String, Codable, Sendable {
    case sms
    case email
    case push
}

/// The SMS / email / push copy that was (or would be) sent for one unit event.
struct StaffAlertRecord: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var channel: StaffAlertChannel
    var title: String
    var body: String
    var scooterID: String
    var scooterName: String
    var rentalID: UUID
    var kindRaw: String
    var recipientName: String
    var recipientAddress: String
    var providerName: String
    var sentAt: Date
    var liveDelivery: Bool

    init(
        id: UUID = UUID(),
        channel: StaffAlertChannel,
        title: String,
        body: String,
        scooterID: String,
        scooterName: String,
        rentalID: UUID,
        kindRaw: String,
        recipientName: String,
        recipientAddress: String,
        providerName: String,
        sentAt: Date = .now,
        liveDelivery: Bool = false
    ) {
        self.id = id
        self.channel = channel
        self.title = title
        self.body = body
        self.scooterID = scooterID
        self.scooterName = scooterName
        self.rentalID = rentalID
        self.kindRaw = kindRaw
        self.recipientName = recipientName
        self.recipientAddress = recipientAddress
        self.providerName = providerName
        self.sentAt = sentAt
        self.liveDelivery = liveDelivery
    }

    var unitLabel: String { "\(scooterID) \(scooterName)" }
}

struct SharedStaffMember: Codable, Equatable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var phoneE164: String
    var emails: [String]
    var isActive: Bool
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        displayName: String,
        phoneE164: String,
        emails: [String] = [],
        isActive: Bool = true,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.displayName = displayName
        self.phoneE164 = phoneE164
        self.emails = emails
        self.isActive = isActive
        self.updatedAt = updatedAt
    }
}

struct LotSnapshot: Codable, Equatable, Sendable {
    var events: [RentalLifecycleEvent]
    var alerts: [StaffAlertRecord]
    var staff: [SharedStaffMember]
    var revisedAt: Date

    static let empty = LotSnapshot(events: [], alerts: [], staff: [], revisedAt: Date(timeIntervalSince1970: 0))
}
