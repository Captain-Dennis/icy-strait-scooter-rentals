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

    init(
        scooterID: String,
        name: String,
        dockLabel: String,
        batteryPercent: Int,
        estimatedRangeMiles: Int,
        isInService: Bool = true,
        vehicleSummary: String = Scooter.standardVehicleSummary,
        sortIndex: Int
    ) {
        self.scooterID = scooterID
        self.name = name
        self.dockLabel = dockLabel
        self.batteryPercent = batteryPercent
        self.estimatedRangeMiles = estimatedRangeMiles
        self.isInService = isInService
        self.vehicleSummary = vehicleSummary
        self.sortIndex = sortIndex
    }

    static let standardVehicleSummary =
        "4-wheel offroad e-scooter · orange frame · gloss black fenders · knobby all-terrain tires"
}
