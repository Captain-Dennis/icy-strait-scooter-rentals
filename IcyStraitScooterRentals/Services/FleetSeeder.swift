import Foundation
import SwiftData

enum FleetSeeder {
    static let fleet: [(id: String, name: String, dock: String, battery: Int, range: Int)] = FleetCatalog.units.map {
        ($0.id, $0.name, $0.dock, $0.batteryPercent, $0.estimatedRangeMiles)
    }

    @MainActor
    static func seedIfNeeded(context: ModelContext) throws {
        try StaffSeeder.seedIfNeeded(context: context)

        if UserDefaults.standard.integer(forKey: AppPreferences.seedVersionKey) == AppPreferences.currentSeedVersion {
            let existing = try context.fetch(FetchDescriptor<Scooter>())
            if existing.count == 6 {
                try applyLotAvailability(context: context)
                return
            }
        }

        try deleteAll(StaffSMSLog.self, context: context)
        try deleteAll(ReturnPhoto.self, context: context)
        try deleteAll(AgreementAcceptance.self, context: context)
        try deleteAll(POSLedgerEntry.self, context: context)
        try deleteAll(Rental.self, context: context)
        try deleteAll(Scooter.self, context: context)

        for (index, unit) in FleetCatalog.units.enumerated() {
            context.insert(
                Scooter(
                    scooterID: unit.id,
                    name: unit.name,
                    dockLabel: unit.dock,
                    batteryPercent: unit.batteryPercent,
                    estimatedRangeMiles: unit.estimatedRangeMiles,
                    isInService: unit.availability == .onLotNow,
                    sortIndex: index
                )
            )
        }

        for rental in sampleSeasonRentals() {
            context.insert(rental)
            for section in AgreementSectionID.allCases {
                context.insert(
                    AgreementAcceptance(
                        sectionID: section,
                        acceptedAt: rental.startedAt.addingTimeInterval(-120),
                        rental: rental
                    )
                )
            }
            if let amount = rental.capturedAmount, let chargeID = rental.posChargeID {
                context.insert(
                    POSLedgerEntry(
                        rentalID: rental.rentalID,
                        kind: .capture,
                        amount: amount,
                        providerReference: chargeID,
                        createdAt: rental.endedAt ?? rental.startedAt,
                        note: "Season sample capture"
                    )
                )
            }
        }

        try context.save()
        UserDefaults.standard.set(AppPreferences.currentSeedVersion, forKey: AppPreferences.seedVersionKey)
    }

    /// Keep SwiftData in sync with the catalog: Glacier on the lot, IS-102–106 next season.
    @MainActor
    static func applyLotAvailability(context: ModelContext) throws {
        let scooters = try context.fetch(FetchDescriptor<Scooter>())
        var changed = false
        for scooter in scooters {
            let rentable = FleetCatalog.isRentableNow(scooter.scooterID)
            if scooter.isInService != rentable {
                scooter.isInService = rentable
                changed = true
            }
        }
        if changed {
            try context.save()
        }
    }

    /// Representative 2027 days so the calendar shows remaining capacity (e.g. 4/6) without thousands of rows.
    static func sampleSeasonRentals() -> [Rental] {
        let days: [(month: Int, day: Int, perHour: [Int])] = [
            (5, 1, [1, 2, 3, 3, 4, 4, 3, 2, 2, 1, 1]),
            (5, 15, [0, 1, 1, 2, 2, 2, 1, 1, 0, 0, 1]),
            (5, 29, [2, 3, 4, 5, 6, 6, 5, 4, 3, 3, 2]),
            (6, 12, [1, 2, 2, 3, 3, 3, 2, 2, 1, 1, 1]),
            (6, 26, [2, 2, 3, 3, 4, 4, 3, 2, 2, 1, 1]),
            (7, 3, [3, 4, 5, 6, 6, 6, 6, 5, 4, 4, 3]),
            (7, 4, [4, 5, 6, 6, 6, 6, 6, 6, 5, 4, 4]),
            (7, 16, [2, 3, 4, 5, 5, 5, 4, 3, 3, 2, 2]),
            (8, 8, [1, 2, 3, 3, 4, 3, 3, 2, 2, 1, 1]),
            (8, 21, [2, 3, 4, 4, 5, 5, 4, 3, 2, 2, 1]),
            (9, 4, [1, 2, 3, 3, 3, 3, 2, 2, 1, 1, 1]),
            (9, 18, [0, 1, 1, 2, 2, 2, 1, 1, 0, 1, 0]),
            (9, 30, [1, 1, 2, 2, 2, 1, 1, 1, 0, 0, 1])
        ]

        var rentals: [Rental] = []
        for (month, dayNumber, perHour) in days {
            let day = Season.date(year: Season.year, month: month, day: dayNumber)
            for (offset, occupancy) in perHour.enumerated() {
                let hour = Season.firstSlotHour + offset
                for index in 0..<occupancy {
                    let scooter = fleet[index % fleet.count]
                    let start = Season.slotStart(on: day, hour: hour).addingTimeInterval(Double(5 + index * 4) * 60)
                    let linger: TimeInterval = occupancy >= 5 ? 50 * 60 : 40 * 60
                    let endTime = start.addingTimeInterval(linger)
                    let amount = BillingCalculator.charge(elapsed: linger)
                    let rentalID = stableUUID(month: month, day: dayNumber, hour: hour, index: index)
                    rentals.append(
                        Rental(
                            rentalID: rentalID,
                            scooterID: scooter.id,
                            scooterName: scooter.name,
                            startedAt: start,
                            endedAt: endTime,
                            returnToken: String(format: "SEED%02d%02d%02d%01d", month, dayNumber, hour, index),
                            status: .completed,
                            posAuthorizationID: "mock_auth_seed_\(rentalID.uuidString.prefix(6))",
                            posChargeID: "mock_ch_seed_\(rentalID.uuidString.prefix(6))",
                            capturedAmount: amount,
                            lastQuotedAmount: amount,
                            isSeededSample: true
                        )
                    )
                }
            }
        }
        return rentals
    }

    private static func deleteAll<T: PersistentModel>(_ type: T.Type, context: ModelContext) throws {
        let items = try context.fetch(FetchDescriptor<T>())
        for item in items {
            context.delete(item)
        }
    }

    private static func stableUUID(month: Int, day: Int, hour: Int, index: Int) -> UUID {
        UUID(uuid: (
            0x20, 0x27, UInt8(month), UInt8(day),
            UInt8(hour), UInt8(index), 0x40, 0x00,
            0x80, 0x00, 0x1C, 0x75,
            0x57, 0x52, 0x4E, 0x54
        ))
    }
}
