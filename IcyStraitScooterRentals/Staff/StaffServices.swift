import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class StaffServices {
    let notifier: any StaffNotifier
    let mock: MockStaffNotifier
    var lastBanner: String?
    var lastPipeStatus: String?

    let httpStore: HTTPLotStore
    let memoryStore: InMemoryLotStore
    let publisher: LotEventPublisher

    init(mock: MockStaffNotifier = MockStaffNotifier()) {
        self.mock = mock
        self.notifier = mock
        let memory = InMemoryLotStore()
        self.memoryStore = memory
        let http = HTTPLotStore(baseURL: SharedPipeConfig.httpBaseURL)
        self.httpStore = http
        self.publisher = LotEventPublisher(store: CompositeLotStore(primary: http, mirror: memory), notifier: mock)
    }

    func notifyCheckout(rental: Rental, context: ModelContext) async {
        let result = await publisher.publishCheckout(
            rentalID: rental.rentalID,
            scooterID: rental.scooterID,
            scooterName: rental.scooterName,
            renterDisplayName: rental.renterLabel,
            startedAt: rental.startedAt,
            recipients: activeRecipients(in: context)
        )
        record(result, context: context)
    }

    func notifyCheckIn(rental: Rental, context: ModelContext) async {
        let result = await publisher.publishReturn(
            rentalID: rental.rentalID,
            scooterID: rental.scooterID,
            scooterName: rental.scooterName,
            renterDisplayName: rental.renterLabel,
            startedAt: rental.startedAt,
            endedAt: rental.endedAt ?? .now,
            recipients: activeRecipients(in: context)
        )
        record(result, context: context)
    }

    func activeRecipients(in context: ModelContext) -> [StaffRecipient] {
        let descriptor = FetchDescriptor<StaffMember>(sortBy: [SortDescriptor(\.displayName)])
        let people = (try? context.fetch(descriptor)) ?? []
        return people.filter { $0.isActive }.map(\.recipient)
    }

    func pushLocalRoster(_ context: ModelContext) async {
        let descriptor = FetchDescriptor<StaffMember>(sortBy: [SortDescriptor(\.displayName)])
        let people = (try? context.fetch(descriptor)) ?? []
        let shared = people.map(\.shared)
        do {
            try await httpStore.replaceStaff(shared)
            try await memoryStore.replaceStaff(shared)
        } catch {
            lastPipeStatus = error.localizedDescription
        }
    }

    private func record(_ result: LotEventPublisher.PublishResult, context: ModelContext) {
        for dispatch in result.dispatches {
            context.insert(
                StaffSMSLog(
                    logID: dispatch.id,
                    staffName: dispatch.staffName,
                    phoneE164: dispatch.phoneE164,
                    email: dispatch.email ?? "",
                    channel: dispatch.channel,
                    kind: dispatch.kind,
                    body: dispatch.body,
                    title: result.push.title,
                    scooterID: result.event.scooterID,
                    scooterName: result.event.scooterName,
                    rentalID: dispatch.rentalID,
                    providerName: dispatch.providerName,
                    sentAt: dispatch.sentAt,
                    liveDelivery: dispatch.liveDelivery
                )
            )
        }
        try? context.save()

        if result.dispatches.count == 1, let only = result.dispatches.first {
            lastBanner = only.bannerText
        } else if result.dispatches.count > 1 {
            lastBanner = "Alerts queued to \(result.dispatches.count) contacts · mock SMS/email"
        } else if let notifyError = result.notifyError {
            lastBanner = notifyError
        }

        if result.eventPublished {
            lastPipeStatus = "Crew board updated · \(result.event.unitLabel)"
        } else {
            lastPipeStatus = result.eventError ?? "Crew board not updated — start tools/rental-events-server"
        }
        if lastBanner == nil {
            lastBanner = lastPipeStatus
        }
    }
}

/// Writes to the live HTTP pipe and keeps a local mirror so the publishing phone can still show copy if the pipe is down.
actor CompositeLotStore: SharedLotStore {
    nonisolated var providerName: String { "CompositeLotStore" }

    private let primary: any SharedLotStore
    private let mirror: any SharedLotStore

    init(primary: any SharedLotStore, mirror: any SharedLotStore) {
        self.primary = primary
        self.mirror = mirror
    }

    func snapshot() async throws -> LotSnapshot {
        do {
            return try await primary.snapshot()
        } catch {
            return try await mirror.snapshot()
        }
    }

    func publish(_ event: RentalLifecycleEvent) async throws {
        try await mirror.publish(event)
        try await primary.publish(event)
    }

    func publishAlert(_ alert: StaffAlertRecord) async throws {
        try await mirror.publishAlert(alert)
        try await primary.publishAlert(alert)
    }

    func upsertStaff(_ member: SharedStaffMember) async throws {
        try await mirror.upsertStaff(member)
        try await primary.upsertStaff(member)
    }

    func replaceStaff(_ members: [SharedStaffMember]) async throws {
        try await mirror.replaceStaff(members)
        try await primary.replaceStaff(members)
    }
}

@MainActor
@Observable
final class SessionRouter {
    var pendingPayload: QRPayload?
    var selectedTab: AppTab = .scan
}

enum AppTab: Hashable {
    case scan
    case calendar
    case rentals
}
