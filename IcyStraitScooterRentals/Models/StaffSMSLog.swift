import Foundation
import SwiftData

@Model
final class StaffSMSLog {
    @Attribute(.unique) var logID: UUID
    var staffName: String
    var phoneE164: String
    var kindRaw: String
    var body: String
    var rentalID: UUID
    var providerName: String
    var sentAt: Date

    init(
        logID: UUID = UUID(),
        staffName: String,
        phoneE164: String,
        kind: StaffMessage.Kind,
        body: String,
        rentalID: UUID,
        providerName: String,
        sentAt: Date = .now
    ) {
        self.logID = logID
        self.staffName = staffName
        self.phoneE164 = phoneE164
        self.kindRaw = kind.rawValue
        self.body = body
        self.rentalID = rentalID
        self.providerName = providerName
        self.sentAt = sentAt
    }

    var kind: StaffMessage.Kind {
        StaffMessage.Kind(rawValue: kindRaw) ?? .checkout
    }

    var displayPhone: String { StaffConfig.display(phoneE164) }
}
