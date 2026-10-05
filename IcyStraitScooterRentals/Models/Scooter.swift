import Foundation
import SwiftData

@Model
final class Scooter {
    @Attribute(.unique) var scooterID: String
    var name: String
    var dockLabel: String
    var batteryPercent: Int
    var estimatedRangeMiles: Int
    var isInService: Bool
    var vehicleSummary: String
    var sortIndex: Int
    /// Asset-catalog name (`UnitIS101` …). Empty on older stores until launch backfill.
    var photoAssetName: String = ""

    init(
        scooterID: String,
        name: String,
        dockLabel: String,
        batteryPercent: Int,
        estimatedRangeMiles: Int,
        isInService: Bool = true,
        vehicleSummary: String = Scooter.standardVehicleSummary,
        sortIndex: Int,
        photoAssetName: String = ""
    ) {
        self.scooterID = scooterID
        self.name = name
        self.dockLabel = dockLabel
        self.batteryPercent = batteryPercent
        self.estimatedRangeMiles = estimatedRangeMiles
        self.isInService = isInService
        self.vehicleSummary = vehicleSummary
        self.sortIndex = sortIndex
        let trimmed = photoAssetName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoAssetName = trimmed.isEmpty ? FleetCatalog.photoAssetName(for: scooterID) : trimmed
    }

    /// Prefer the stored name, then the catalog, so a photo swap does not require a UI change.
    var resolvedPhotoAssetName: String {
        let trimmed = photoAssetName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { return trimmed }
        return FleetCatalog.photoAssetName(for: scooterID)
    }

    static let standardVehicleSummary =
        "4-wheel offroad e-scooter · orange frame · gloss black fenders · knobby all-terrain tires"
}
