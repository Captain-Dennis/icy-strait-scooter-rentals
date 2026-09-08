import Foundation

/// Smart-link and App Store install placeholders.
/// There is no live App Store listing yet — do not treat these URLs as published.
enum AppLinkConfig {
    static let smartLinkHost = "icystraitscooters.example"
    static let smartLinkOrigin = "https://icystraitscooters.example"

    /// Path for a physical scooter QR: `https://icystraitscooters.example/s/IS-101`
    static let scooterPathPrefix = "/s/"

    /// Optional https return link: `https://icystraitscooters.example/r/{uuid}/{token}`
    static let returnPathPrefix = "/r/"

    /// Replace after App Store Connect assigns an Apple ID. Not a real listing.
    static let appStoreAppleIDPlaceholder = "APP_STORE_APPLE_ID_TBD"

    /// Replace with the team ID from the Apple Developer account.
    static let appleTeamIDPlaceholder = "APPLE_TEAM_ID_TBD"

    /// Replace after the app is published (or with a TestFlight public link for beta).
    static let appStoreURLPlaceholder = "https://apps.apple.com/app/idAPP_STORE_APPLE_ID_TBD"

    static let associatedDomain = "applinks:icystraitscooters.example"

    static func scooterSmartLink(id: String) -> String {
        "\(smartLinkOrigin)\(scooterPathPrefix)\(QRPayload.normalizeScooterID(id))"
    }

    static func returnSmartLink(rentalID: UUID, token: String) -> String {
        "\(smartLinkOrigin)\(returnPathPrefix)\(rentalID.uuidString)/\(token)"
    }

    static func isSmartLinkHost(_ host: String?) -> Bool {
        guard let host else { return false }
        let folded = host.lowercased()
        return folded == smartLinkHost || folded == "www.\(smartLinkHost)"
    }
}
