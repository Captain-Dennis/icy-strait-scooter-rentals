import Foundation

enum UnitLotStatus: String, Codable, Sendable {
    case out
    case back
}

struct UnitBoardRow: Equatable, Identifiable, Sendable {
    var scooterID: String
    var scooterName: String
    var dock: String
    var status: UnitLotStatus
    var renterDisplayName: String?
    var startedAt: Date?
    var endedAt: Date?
    var lastEvent: RentalLifecycleEvent?

    var id: String { scooterID }
    var unitLabel: String { "\(scooterID) \(scooterName)" }
    var isOut: Bool { status == .out }

    var statusTitle: String { isOut ? "Out" : "Back" }

    var renterLabel: String {
        let trimmed = renterDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty { return isOut ? "Renter unknown" : "—" }
        return trimmed
    }
}

enum CrewBoard {
    /// One row per catalog unit. Latest checkout without a later return = Out.
    static func rows(
        events: [RentalLifecycleEvent],
        units: [(id: String, name: String, dock: String)]
    ) -> [UnitBoardRow] {
        units.map { unit in
            let history = events
                .filter { $0.scooterID == unit.id }
                .sorted { $0.occurredAt < $1.occurredAt }
            let last = history.last
            let isOut = last?.kind == .checkout
            return UnitBoardRow(
                scooterID: unit.id,
                scooterName: unit.name,
                dock: unit.dock,
                status: isOut ? .out : .back,
                renterDisplayName: isOut ? last?.renterDisplayName : last?.renterDisplayName,
                startedAt: isOut ? last?.startedAt : last?.startedAt,
                endedAt: isOut ? nil : last?.endedAt,
                lastEvent: last
            )
        }
    }

    static func history(
        for scooterID: String,
        events: [RentalLifecycleEvent]
    ) -> [RentalLifecycleEvent] {
        events
            .filter { $0.scooterID == scooterID }
            .sorted { $0.occurredAt > $1.occurredAt }
    }

    static func outCount(in rows: [UnitBoardRow]) -> Int {
        rows.filter(\.isOut).count
    }
}
