import Foundation
import SwiftUI

enum AppPreferences {
    static let onboardingCompletedKey = "icystrait.onboardingCompleted"
    static let enforceSeasonHoursKey = "icystrait.enforceSeasonHours"
    static let seedVersionKey = "icystrait.seedVersion"
    static let staffSeededKey = "icystrait.staffSeeded"
    static let currentSeedVersion = 2

    static var onboardingCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: onboardingCompletedKey) }
        set { UserDefaults.standard.set(newValue, forKey: onboardingCompletedKey) }
    }

    /// Off by default so the Simulator can check out a unit today (outside the 2027 season).
    static var enforceSeasonHours: Bool {
        get { UserDefaults.standard.bool(forKey: enforceSeasonHoursKey) }
        set { UserDefaults.standard.set(newValue, forKey: enforceSeasonHoursKey) }
    }
}

@MainActor
@Observable
final class POSEnvironment {
    let provider: any POSProvider
    let mock: MockPOSProvider

    init(mock: MockPOSProvider = MockPOSProvider()) {
        self.mock = mock
        self.provider = mock
    }
}

enum CheckoutError: LocalizedError, Equatable {
    case unknownScooter
    case nextSeasonNotOnLot
    case outOfService
    case alreadyRented
    case hourFull
    case outsideSeason
    case outsideHours
    case agreementsIncomplete
    case invalidReturnQR
    case rentalNotFound
    case alreadyCheckedIn
    case returnPhotosIncomplete
    case pos(String)

    var errorDescription: String? {
        switch self {
        case .unknownScooter:
            return "That scooter ID is not in the Icy Strait fleet."
        case .nextSeasonNotOnLot:
            return "That unit is cataloged for the 2027 season. It is not on the lot and is not rentable. Only IS-101 Glacier is live today."
        case .outOfService:
            return "This 4-wheel offroad e-scooter is tagged out of service."
        case .alreadyRented:
            return "This unit already has an active rental."
        case .hourFull:
            return "This hour is at capacity. Only IS-101 Glacier is on the lot today."
        case .outsideSeason:
            return "Rentals run May 1–September 30, 2027 only."
        case .outsideHours:
            return "Checkout is 8:00 AM–7:00 PM Alaska time."
        case .agreementsIncomplete:
            return "Accept every required agreement now — including Damage & Liability. There is no skip or later option."
        case .invalidReturnQR:
            return "That return QR does not match an open rental."
        case .rentalNotFound:
            return "We could not find that rental."
        case .alreadyCheckedIn:
            return "This rental is already checked in."
        case .returnPhotosIncomplete:
            return "Photograph the left and right sides of the 4-wheel offroad e-scooter before check-in can finish."
        case .pos(let message):
            return message
        }
    }
}
