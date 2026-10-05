import Foundation
import Observation
import UserNotifications

@MainActor
@Observable
final class CrewLotMonitor {
    var snapshot: LotSnapshot = .empty
    var lastError: String?
    var lastRefreshed: Date?
    var pipeURL: String = SharedPipeConfig.httpBaseURL.absoluteString
    var isRefreshing = false

    private let http: HTTPLotStore
    private let pipe: SelectingLotStore
    private var seenEventIDs: Set<UUID> = []
    private var didPrimeSeen = false
    private var didRegisterSubscription = false

    var storeName: String { SharedPipeConfig.liveStoreName }

    init() {
        let http = HTTPLotStore(baseURL: SharedPipeConfig.httpBaseURL)
        self.http = http
        self.pipe = SelectingLotStore(http: http, makeCloudKit: { CloudKitLotStore() })
    }

    var rows: [UnitBoardRow] {
        CrewBoard.rows(events: snapshot.events, units: FleetCatalog.boardUnits)
    }

    var outCount: Int { CrewBoard.outCount(in: rows) }

    var onLotCount: Int { CrewBoard.onLotCount(in: rows) }

    func setPipeURL(_ raw: String) async {
        SharedPipeConfig.setHTTPBaseURL(raw)
        pipeURL = SharedPipeConfig.httpBaseURL.absoluteString
        await http.setBaseURL(SharedPipeConfig.httpBaseURL)
        await refresh(announceNew: false)
    }

    func refresh(announceNew: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let next = try await pipe.snapshot()
            if announceNew {
                await announceNewEvents(in: next.events)
            } else {
                seenEventIDs.formUnion(next.events.map(\.id))
                didPrimeSeen = true
            }
            snapshot = next
            lastRefreshed = .now
            lastError = nil
            await registerSubscriptionIfNeeded()
        } catch {
            lastError = error.localizedDescription
        }
    }

    /// Query subscription for new rental events. No-op until Prefer CloudKit is on in an entitled build.
    private func registerSubscriptionIfNeeded() async {
        guard SharedPipeConfig.usesCloudKit, !didRegisterSubscription else { return }
        do {
            _ = try await CloudKitLotStore().registerEventSubscription()
            didRegisterSubscription = true
        } catch {
            // Dashboard schema or the push profile may still be catching up. The board already loaded.
        }
    }

    func requestNotificationPermission() async {
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func history(for scooterID: String) -> [RentalLifecycleEvent] {
        CrewBoard.history(for: scooterID, events: snapshot.events)
    }

    func alerts(for scooterID: String?) -> [StaffAlertRecord] {
        let rows = snapshot.alerts.sorted { $0.sentAt > $1.sentAt }
        guard let scooterID else { return rows }
        return rows.filter { $0.scooterID == scooterID }
    }

    private func announceNewEvents(in events: [RentalLifecycleEvent]) async {
        if !didPrimeSeen {
            seenEventIDs = Set(events.map(\.id))
            didPrimeSeen = true
            return
        }
        let fresh = events
            .filter { !seenEventIDs.contains($0.id) }
            .sorted { $0.occurredAt < $1.occurredAt }
        seenEventIDs.formUnion(events.map(\.id))
        for event in fresh {
            await postLocalNotification(for: event)
        }
    }

    /// Local notification for the polling path. CloudKit push is registered only when `usesCloudKit` is true.
    private func postLocalNotification(for event: RentalLifecycleEvent) async {
        let payload = CrewAlertCopy.payload(for: event)
        let content = UNMutableNotificationContent()
        content.title = payload.title
        content.body = payload.body
        content.sound = .default
        content.userInfo = payload.userInfo
        let request = UNNotificationRequest(
            identifier: event.id.uuidString,
            content: content,
            trigger: nil
        )
        try? await UNUserNotificationCenter.current().add(request)
    }
}
