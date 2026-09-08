import Foundation

enum StaffConfig {
    static let defaultNational = "9075005152"
    static let defaultE164 = "+19075005152"
    static let defaultDisplay = "+1 (907) 500-5152"
    static let starterName = "Front desk"

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

    func body() -> String {
        let time = occurredAt.formatted(date: .abbreviated, time: .shortened)
        let shortID = String(rentalID.uuidString.prefix(8))
        switch kind {
        case .checkout:
            return "Icy Strait: \(scooterID) \(scooterName) checkout. Rental \(shortID) started \(time). Stage that exact unit — not another scooter."
        case .checkIn:
            return "Icy Strait: \(scooterID) \(scooterName) return. Rental \(shortID) checked in \(time). \(extraNote)"
        }
    }
}

struct StaffDispatch: Equatable, Identifiable, Sendable {
    var id: UUID
    var staffName: String
    var phoneE164: String
    var body: String
    var sentAt: Date
    var kind: StaffMessage.Kind
    var rentalID: UUID
    var providerName: String

    var displayPhone: String { StaffConfig.display(phoneE164) }

    var bannerText: String {
        "SMS sent to \(staffName) · \(displayPhone)"
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
