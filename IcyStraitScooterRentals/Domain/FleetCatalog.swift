import Foundation

/// Hard rule: six units, six unique checkout QRs. Never a shared “any scooter” code.
enum FleetCatalog {
    struct Unit: Equatable, Identifiable {
        var id: String
        var name: String
        var dock: String
        var batteryPercent: Int
        var estimatedRangeMiles: Int
    }

    static let units: [Unit] = [
        Unit(id: "IS-101", name: "Glacier", dock: "Dock A · North lot", batteryPercent: 94, estimatedRangeMiles: 28),
        Unit(id: "IS-102", name: "Humpback", dock: "Dock B · North lot", batteryPercent: 88, estimatedRangeMiles: 26),
        Unit(id: "IS-103", name: "Spruce", dock: "Dock C · Lodge loop", batteryPercent: 91, estimatedRangeMiles: 27),
        Unit(id: "IS-104", name: "Otter", dock: "Dock D · Waterfront", batteryPercent: 76, estimatedRangeMiles: 22),
        Unit(id: "IS-105", name: "Raven", dock: "Dock E · Cannery row", batteryPercent: 83, estimatedRangeMiles: 24),
        Unit(id: "IS-106", name: "Tidepool", dock: "Dock F · Point trail", batteryPercent: 97, estimatedRangeMiles: 30)
    ]

    static var ids: [String] { units.map(\.id) }

    static func unit(id: String) -> Unit? {
        let normalized = QRPayload.normalizeScooterID(id)
        return units.first { $0.id == normalized }
    }

    static func isKnown(_ id: String) -> Bool {
        unit(id: id) != nil
    }

    /// One preferred https QR per unit. These six strings must all be different.
    static var uniqueCheckoutLinks: [String] {
        ids.map { AppLinkConfig.scooterSmartLink(id: $0) }
    }

    static func customSchemeLink(id: String) -> String {
        QRPayload.scooter(id: id).customSchemeURLString
    }

    /// Printable / Settings payloads. Never emit a shared “any scooter” code.
    static var stickerPayloads: [StickerPayload] {
        units.map { unit in
            StickerPayload(
                id: unit.id,
                name: unit.name,
                dock: unit.dock,
                httpsPayload: AppLinkConfig.scooterSmartLink(id: unit.id),
                customSchemePayload: customSchemeLink(id: unit.id),
                barePayload: unit.id
            )
        }
    }

    struct StickerPayload: Equatable, Identifiable {
        var id: String
        var name: String
        var dock: String
        var httpsPayload: String
        var customSchemePayload: String
        var barePayload: String
    }
}
