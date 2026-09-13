import Foundation

enum UnitLotStatus: String, Codable, Sendable {
    case out
    case back
    case nextSeason
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
    var isNextSeason: Bool { status == .nextSeason }

    var statusTitle: String {
        switch status {
        case .out: return "Out"
        case .back: return "Back"
        case .nextSeason: return "2027"
        }
    }

    var renterLabel: String {
        if isNextSeason { return "—" }
        let trimmed = renterDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if trimmed.isEmpty { return isOut ? "Renter unknown" : "—" }
        return trimmed
    }
}

enum CrewBoard {
    /// One row per catalog unit. Next-season units stay off the live lot.
    static func rows(
        events: [RentalLifecycleEvent],
        units: [(id: String, name: String, dock: String, availability: FleetCatalog.Availability)]
    ) -> [UnitBoardRow] {
        units.map { unit in
            if unit.availability == .nextSeason {
                return UnitBoardRow(
                    scooterID: unit.id,
                    scooterName: unit.name,
                    dock: unit.dock,
                    status: .nextSeason,
                    renterDisplayName: nil,
                    startedAt: nil,
                    endedAt: nil,
                    lastEvent: nil
                )
            }
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
                renterDisplayName: last?.renterDisplayName,
                startedAt: last?.startedAt,
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

    static func onLotCount(in rows: [UnitBoardRow]) -> Int {
        rows.filter { !$0.isNextSeason }.count
    }
}
