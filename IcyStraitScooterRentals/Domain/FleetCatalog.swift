import Foundation

/// Hard rule: six units, six unique checkout QRs. Never a shared “any scooter” code.
/// Only IS-101 Glacier is on the lot and rentable now. IS-102–106 stay in the
/// catalog for the 2027 season — not on the lot, not rentable, not inbound this month.
enum FleetCatalog {
    enum Availability: String, Codable, Sendable {
        case onLotNow
        case nextSeason
    }

    struct Unit: Equatable, Identifiable {
        var id: String
        var name: String
        var dock: String
        var batteryPercent: Int
        var estimatedRangeMiles: Int
        var availability: Availability
        /// Asset-catalog image for this physical unit. Screens load `Image(photoAssetName)` only.
        /// Swap the photo by replacing the file inside that imageset; do not rename the set.
        var photoAssetName: String
    }

    static let units: [Unit] = [
        Unit(id: "IS-101", name: "Glacier", dock: "Dock A · North lot", batteryPercent: 94, estimatedRangeMiles: 28, availability: .onLotNow, photoAssetName: "UnitIS101"),
        Unit(id: "IS-102", name: "Humpback", dock: "Dock B · North lot", batteryPercent: 88, estimatedRangeMiles: 26, availability: .nextSeason, photoAssetName: "UnitIS102"),
        Unit(id: "IS-103", name: "Spruce", dock: "Dock C · Lodge loop", batteryPercent: 91, estimatedRangeMiles: 27, availability: .nextSeason, photoAssetName: "UnitIS103"),
        Unit(id: "IS-104", name: "Otter", dock: "Dock D · Waterfront", batteryPercent: 76, estimatedRangeMiles: 22, availability: .nextSeason, photoAssetName: "UnitIS104"),
        Unit(id: "IS-105", name: "Raven", dock: "Dock E · Cannery row", batteryPercent: 83, estimatedRangeMiles: 24, availability: .nextSeason, photoAssetName: "UnitIS105"),
        Unit(id: "IS-106", name: "Tidepool", dock: "Dock F · Point trail", batteryPercent: 97, estimatedRangeMiles: 30, availability: .nextSeason, photoAssetName: "UnitIS106")
    ]

    static var ids: [String] { units.map(\.id) }

    static var rentableNow: [Unit] { units.filter { $0.availability == .onLotNow } }

    static var nextSeason: [Unit] { units.filter { $0.availability == .nextSeason } }

    /// Live walk-up cap: one rental per hour while only Glacier is on the lot.
    static var liveCapacityPerHour: Int { rentableNow.count }

    static var boardUnits: [(id: String, name: String, dock: String, availability: Availability, photoAssetName: String)] {
        units.map { ($0.id, $0.name, $0.dock, $0.availability, $0.photoAssetName) }
    }

    /// Catalog image name for a unit. Known IDs use the stored asset; unknown IDs still get a stable name.
    static func photoAssetName(for scooterID: String) -> String {
        let normalized = QRPayload.normalizeScooterID(scooterID)
        if let unit = units.first(where: { $0.id == normalized }) {
            return unit.photoAssetName
        }
        let compact = normalized.filter { $0.isLetter || $0.isNumber }
        return compact.isEmpty ? "UnitUnknown" : "Unit\(compact)"
    }

    static func unit(id: String) -> Unit? {
        let normalized = QRPayload.normalizeScooterID(id)
        return units.first { $0.id == normalized }
    }

    static func isKnown(_ id: String) -> Bool {
        unit(id: id) != nil
    }

    static func isRentableNow(_ id: String) -> Bool {
        unit(id: id)?.availability == .onLotNow
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
