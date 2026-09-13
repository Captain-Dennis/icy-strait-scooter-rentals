import Foundation

protocol SharedLotStore: Sendable {
    var providerName: String { get }
    func snapshot() async throws -> LotSnapshot
    func publish(_ event: RentalLifecycleEvent) async throws
    func publishAlert(_ alert: StaffAlertRecord) async throws
    func upsertStaff(_ member: SharedStaffMember) async throws
    func replaceStaff(_ members: [SharedStaffMember]) async throws
}

enum SharedLotStoreError: LocalizedError, Equatable {
    case unreachable(String)
    case decoding
    case encoding
    case notConfigured

    var errorDescription: String? {
        switch self {
        case .unreachable(let detail):
            return "Crew event pipe is unreachable. \(detail)"
        case .decoding:
            return "Crew event pipe returned data this build cannot read."
        case .encoding:
            return "Could not encode a rental event for the crew pipe."
        case .notConfigured:
            return "No live event pipe is configured."
        }
    }
}

/// Process-local store used by tests and as a cache. Not a phone-to-phone pipe.
actor InMemoryLotStore: SharedLotStore {
    nonisolated var providerName: String { "InMemoryLotStore" }

    private var events: [RentalLifecycleEvent] = []
    private var alerts: [StaffAlertRecord] = []
    private var staff: [SharedStaffMember] = []

    func snapshot() async throws -> LotSnapshot {
        LotSnapshot(
            events: events.sorted { $0.occurredAt < $1.occurredAt },
            alerts: alerts.sorted { $0.sentAt > $1.sentAt },
            staff: staff.sorted { $0.displayName < $1.displayName },
            revisedAt: .now
        )
    }

    func publish(_ event: RentalLifecycleEvent) async throws {
        events.removeAll { $0.id == event.id }
        events.append(event)
    }

    func publishAlert(_ alert: StaffAlertRecord) async throws {
        alerts.removeAll { $0.id == alert.id }
        alerts.append(alert)
    }

    func upsertStaff(_ member: SharedStaffMember) async throws {
        if let index = staff.firstIndex(where: { $0.id == member.id }) {
            staff[index] = member
        } else {
            staff.append(member)
        }
    }

    func replaceStaff(_ members: [SharedStaffMember]) async throws {
        staff = members
    }

    func reset() {
        events = []
        alerts = []
        staff = []
    }
}

enum LotJSON {
    static func encoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        return encoder
    }

    static func decoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
