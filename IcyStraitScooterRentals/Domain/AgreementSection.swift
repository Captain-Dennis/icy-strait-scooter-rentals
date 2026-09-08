import Foundation

enum AgreementSectionID: String, CaseIterable, Codable, Identifiable {
    case rentalAgreement
    case useRestrictions
    case areaOfOperation
    case damageAndLiability
    case safetyAndReturn

    var id: String { rawValue }

    var title: String {
        switch self {
        case .rentalAgreement: return "Rental Agreement"
        case .useRestrictions: return "Use Restrictions"
        case .areaOfOperation: return "Area of Operation"
        case .damageAndLiability: return "Damage & Liability"
        case .safetyAndReturn: return "Safety & Return"
        }
    }

    var shortTitle: String {
        switch self {
        case .rentalAgreement: return "Rental"
        case .useRestrictions: return "Use"
        case .areaOfOperation: return "Area"
        case .damageAndLiability: return "Liability"
        case .safetyAndReturn: return "Return"
        }
    }

    var symbolName: String {
        switch self {
        case .rentalAgreement: return "doc.text.fill"
        case .useRestrictions: return "hand.raised.fill"
        case .areaOfOperation: return "map.fill"
        case .damageAndLiability: return "exclamationmark.triangle.fill"
        case .safetyAndReturn: return "checkmark.shield.fill"
        }
    }

    var isHighEmphasis: Bool {
        self == .damageAndLiability || self == .areaOfOperation
    }

    var stepOrder: Int {
        Self.allCases.firstIndex(of: self) ?? 0
    }

    var acceptLabel: String {
        switch self {
        case .areaOfOperation:
            return "I will stay off dirt roads and all Icy Strait Port property"
        case .damageAndLiability:
            return "I will pay for any damage to the e-scooter, any person, and any property — including cars and trucks"
        default:
            return "I agree to \(title)"
        }
    }

    var progressLabel: String {
        "\(stepOrder + 1) of \(Self.allCases.count)"
    }
}

struct AgreementCopy: Equatable {
    var id: AgreementSectionID
    var headline: String
    var isDraft: Bool
    var paragraphs: [String]
    var bullets: [String]
}

enum AgreementLibrary {
    static let allIDs = AgreementSectionID.allCases

    static func copy(for id: AgreementSectionID) -> AgreementCopy {
        switch id {
        case .rentalAgreement:
            return AgreementCopy(
                id: id,
                headline: "You are renting a 4-wheel offroad e-scooter",
                isDraft: true,
                paragraphs: [],
                bullets: [
                    "Be 18 or older. You are the renter of record.",
                    "This is a 4-wheel offroad e-scooter — not a kick scooter.",
                    "You are responsible from start until you check it back in.",
                    "Tell us about existing damage before you leave the lot."
                ]
            )
        case .useRestrictions:
            return AgreementCopy(
                id: id,
                headline: "Ride it like you would a truck on a wet boardwalk",
                isDraft: true,
                paragraphs: [],
                bullets: [
                    "One rider. No passengers.",
                    "No racing, jumping, or stunts.",
                    "Helmet if the lot sign says so.",
                    "No phones, alcohol, or riding in ice, flood, or high wind."
                ]
            )
        case .areaOfOperation:
            return AgreementCopy(
                id: id,
                headline: "Stay on marked pavement",
                isDraft: false,
                paragraphs: [],
                bullets: [
                    "PROHIBITED: Dirt roads. Not allowed on any dirt, gravel, mud, or forest road.",
                    "PROHIBITED: Icy Strait Port property. Not allowed on any port land — terminals, yards, docks, or port lots.",
                    "ALLOWED: Marked paved rental routes posted at the lot."
                ]
            )
        case .damageAndLiability:
            return AgreementCopy(
                id: id,
                headline: "If it gets hurt, you pay",
                isDraft: true,
                paragraphs: [],
                bullets: [
                    "You pay for any damage to the e-scooter.",
                    "You pay for injury to any person.",
                    "You pay for damage to any property — including cars, trucks, and other vehicles.",
                    "This is on top of the rental fee."
                ]
            )
        case .safetyAndReturn:
            return AgreementCopy(
                id: id,
                headline: "Ride safe. Check in to stop the clock.",
                isDraft: true,
                paragraphs: [],
                bullets: [
                    "First hour $75. Then $37.50 each extra 30 minutes until you check in.",
                    "Check in with the return QR, then a left photo and a right photo.",
                    "Billing stops only after those two photos.",
                    "Hands on the bars. Four knobby tires — still can tip on loose rock."
                ]
            )
        }
    }
}

enum AgreementGate {
    static var requiredIDs: Set<AgreementSectionID> {
        Set(AgreementSectionID.allCases)
    }

    static var ordered: [AgreementSectionID] {
        AgreementSectionID.allCases
    }

    static func acceptedCount(_ accepted: Set<AgreementSectionID>) -> Int {
        accepted.intersection(requiredIDs).count
    }

    static func missing(from accepted: Set<AgreementSectionID>) -> [AgreementSectionID] {
        ordered.filter { !accepted.contains($0) }
    }

    static func canStartRental(accepted: Set<AgreementSectionID>) -> Bool {
        missing(from: accepted).isEmpty
    }

    /// Later sections stay locked until every earlier section is accepted. No skip.
    static func canOpen(_ section: AgreementSectionID, accepted: Set<AgreementSectionID>) -> Bool {
        guard let index = ordered.firstIndex(of: section) else { return false }
        return ordered.prefix(index).allSatisfy { accepted.contains($0) }
    }
}

struct AgreementAcceptanceRecord: Codable, Equatable, Identifiable {
    var sectionID: AgreementSectionID
    var acceptedAt: Date

    var id: AgreementSectionID { sectionID }
}
