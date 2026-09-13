import Foundation

enum StaffConfig {
    static let defaultNational = "9075005152"
    static let defaultE164 = "+19075005152"
    static let defaultDisplay = "+1 (907) 500-5152"
    static let starterName = "Front desk / Dennis"
    static let defaultEmails = [
        "maddasstoner@yahoo.com",
        "f.vhappytimes@gmail.com"
    ]
    /// Beta Crew unlock. Last four of the front-desk cell. Not a product auth system.
    static let betaPIN = "5152"
    static let starterStaffID = UUID(uuidString: "00000000-0000-4000-8000-000000005152")!

    static func normalize(_ raw: String) -> String {
        let digits = raw.filter(\.isNumber)
        if digits.count == 10 {
            return "+1\(digits)"
        }
        if digits.count == 11, digits.hasPrefix("1") {
            return "+\(digits)"
        }
        if raw.hasPrefix("+"), digits.count >= 10 {
            return "+\(digits)"
        }
        return raw.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func display(_ e164: String) -> String {
        let digits = e164.filter(\.isNumber)
        if digits.count == 11, digits.hasPrefix("1") {
            let rest = Array(digits.dropFirst())
            return "+1 (\(String(rest[0...2]))) \(String(rest[3...5]))-\(String(rest[6...9]))"
        }
        return e164
    }

    static func isValidPhone(_ raw: String) -> Bool {
        let digits = normalize(raw).filter(\.isNumber)
        return digits.count == 11 && digits.hasPrefix("1")
    }

    static func parseEmails(_ raw: String) -> [String] {
        raw
            .split(whereSeparator: { $0 == "," || $0 == ";" || $0.isNewline })
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { $0.contains("@") && $0.contains(".") }
    }

    static func joinEmails(_ emails: [String]) -> String {
        emails.joined(separator: ", ")
    }

    static func isValidEmail(_ raw: String) -> Bool {
        let value = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.contains("@") && value.contains(".")
    }
}

struct StaffMessage: Equatable, Sendable {
    enum Kind: String, Codable, Sendable {
        case checkout
        case checkIn
    }

    var kind: Kind
    var rentalID: UUID
    var scooterID: String
    var scooterName: String
    var occurredAt: Date
    var extraNote: String
    var renterDisplayName: String? = nil

    var unitLabel: String { "\(scooterID) \(scooterName)" }

    var renterLabel: String {
        let trimmed = renterDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "Guest" : trimmed
    }

    func body() -> String {
        let eventKind: RentalLifecycleEvent.Kind = kind == .checkout ? .checkout : .returned
        let event = RentalLifecycleEvent(
            kind: eventKind,
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: renterDisplayName,
            startedAt: occurredAt,
            endedAt: kind == .checkIn ? occurredAt : nil,
            occurredAt: occurredAt
        )
        return CrewAlertCopy.smsBody(for: event, extraNote: extraNote)
    }
}

struct StaffDispatch: Equatable, Identifiable, Sendable {
    var id: UUID
    var staffName: String
    var phoneE164: String
    var email: String?
    var channel: StaffAlertChannel
    var body: String
    var sentAt: Date
    var kind: StaffMessage.Kind
    var rentalID: UUID
    var providerName: String
    var liveDelivery: Bool

    var displayPhone: String { StaffConfig.display(phoneE164) }

    var address: String {
        switch channel {
        case .sms:
            return phoneE164
        case .email:
            return email ?? ""
        case .push:
            return "apns-not-wired"
        }
    }

    var bannerText: String {
        switch channel {
        case .sms:
            return "SMS sent to \(staffName) · \(displayPhone)"
        case .email:
            return "Email queued to \(staffName) · \(email ?? "")"
        case .push:
            return "Push payload ready · \(staffName)"
        }
    }
}

enum StaffNotifyError: LocalizedError {
    case noRecipients
    case missingCredentials
    case stubOnly(String)

    var errorDescription: String? {
        switch self {
        case .noRecipients:
            return "No active staff members. Add or enable someone on the Staff screen."
        case .missingCredentials:
            return "TwilioSMSNotifier needs Account SID, Auth Token, and a from-number. Not used in v1."
        case .stubOnly(let message):
            return message
        }
    }
}
