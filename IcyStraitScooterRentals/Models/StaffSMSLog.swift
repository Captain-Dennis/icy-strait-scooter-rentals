import Foundation
import SwiftData

@Model
final class StaffSMSLog {
    @Attribute(.unique) var logID: UUID
    var staffName: String
    var phoneE164: String
    var email: String = ""
    var channelRaw: String = "sms"
    var kindRaw: String
    var body: String
    var title: String = ""
    var scooterID: String = ""
    var scooterName: String = ""
    var rentalID: UUID
    var providerName: String
    var sentAt: Date
    var liveDelivery: Bool = false

    init(
        logID: UUID = UUID(),
        staffName: String,
        phoneE164: String,
        email: String = "",
        channel: StaffAlertChannel = .sms,
        kind: StaffMessage.Kind,
        body: String,
        title: String = "",
        scooterID: String = "",
        scooterName: String = "",
        rentalID: UUID,
        providerName: String,
        sentAt: Date = .now,
        liveDelivery: Bool = false
    ) {
        self.logID = logID
        self.staffName = staffName
        self.phoneE164 = phoneE164
        self.email = email
        self.channelRaw = channel.rawValue
        self.kindRaw = kind.rawValue
        self.body = body
        self.title = title
        self.scooterID = scooterID
        self.scooterName = scooterName
        self.rentalID = rentalID
        self.providerName = providerName
        self.sentAt = sentAt
        self.liveDelivery = liveDelivery
    }

    var kind: StaffMessage.Kind {
        StaffMessage.Kind(rawValue: kindRaw) ?? .checkout
    }

    var channel: StaffAlertChannel {
        StaffAlertChannel(rawValue: channelRaw) ?? .sms
    }

    var displayPhone: String { StaffConfig.display(phoneE164) }
}
