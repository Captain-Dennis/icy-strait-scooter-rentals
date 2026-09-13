import CloudKit
import Foundation

/// Production-shaped CloudKit public-database pipe.
/// Not the v1 live path for the shipping customer app: adding iCloud entitlements
/// there would force a new App Store profile and can break the current TestFlight upload.
/// Crew can entitle this container when the App ID is created.
actor CloudKitLotStore: SharedLotStore {
    nonisolated var providerName: String { "CloudKitLotStore" }

    private let container: CKContainer
    private let database: CKDatabase

    init(containerIdentifier: String = SharedPipeConfig.cloudKitContainer) {
        let container = CKContainer(identifier: containerIdentifier)
        self.container = container
        self.database = container.publicCloudDatabase
    }

    func snapshot() async throws -> LotSnapshot {
        async let events = fetchEvents()
        async let alerts = fetchAlerts()
        async let staff = fetchStaff()
        return try await LotSnapshot(
            events: events,
            alerts: alerts,
            staff: staff,
            revisedAt: .now
        )
    }

    func publish(_ event: RentalLifecycleEvent) async throws {
        try await database.save(Self.record(for: event))
    }

    func publishAlert(_ alert: StaffAlertRecord) async throws {
        try await database.save(Self.record(for: alert))
    }

    func upsertStaff(_ member: SharedStaffMember) async throws {
        try await database.save(Self.record(for: member))
    }

    func replaceStaff(_ members: [SharedStaffMember]) async throws {
        for member in members {
            try await upsertStaff(member)
        }
    }

    /// Query subscription for new rental events. Requires Push + CloudKit on the Crew App ID.
    /// Live APNs is not claimed until that portal wiring exists.
    func registerEventSubscription() async throws -> CKSubscription.ID {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: SharedPipeConfig.cloudKitRecordType,
            predicate: predicate,
            subscriptionID: "icystrait.rental-events",
            options: [.firesOnRecordCreation]
        )
        let notification = CKSubscription.NotificationInfo()
        notification.shouldSendContentAvailable = true
        notification.alertLocalizationKey = "%1$@ %2$@"
        notification.alertLocalizationArgs = ["scooterID", "scooterName"]
        notification.shouldBadge = false
        subscription.notificationInfo = notification
        let saved = try await database.save(subscription)
        return saved.subscriptionID
    }

    private func fetchEvents() async throws -> [RentalLifecycleEvent] {
        let records = try await query(SharedPipeConfig.cloudKitRecordType)
        return records.compactMap(Self.event(from:)).sorted { $0.occurredAt < $1.occurredAt }
    }

    private func fetchAlerts() async throws -> [StaffAlertRecord] {
        let records = try await query(SharedPipeConfig.cloudKitAlertRecordType)
        return records.compactMap(Self.alert(from:)).sorted { $0.sentAt > $1.sentAt }
    }

    private func fetchStaff() async throws -> [SharedStaffMember] {
        let records = try await query(SharedPipeConfig.cloudKitStaffRecordType)
        return records.compactMap(Self.staff(from:)).sorted { $0.displayName < $1.displayName }
    }

    private func query(_ recordType: String) async throws -> [CKRecord] {
        let query = CKQuery(recordType: recordType, predicate: NSPredicate(value: true))
        let result = try await database.records(matching: query, resultsLimit: CKQueryOperation.maximumResults)
        return result.matchResults.compactMap { _, recordResult in
            try? recordResult.get()
        }
    }

    static func record(for event: RentalLifecycleEvent) -> CKRecord {
        let record = CKRecord(
            recordType: SharedPipeConfig.cloudKitRecordType,
            recordID: CKRecord.ID(recordName: event.id.uuidString)
        )
        record["kind"] = event.kind.rawValue as CKRecordValue
        record["scooterID"] = event.scooterID as CKRecordValue
        record["scooterName"] = event.scooterName as CKRecordValue
        record["rentalID"] = event.rentalID.uuidString as CKRecordValue
        record["renterDisplayName"] = (event.renterDisplayName ?? "") as CKRecordValue
        record["startedAt"] = event.startedAt as CKRecordValue
        if let endedAt = event.endedAt {
            record["endedAt"] = endedAt as CKRecordValue
        }
        record["occurredAt"] = event.occurredAt as CKRecordValue
        return record
    }

    static func record(for alert: StaffAlertRecord) -> CKRecord {
        let record = CKRecord(
            recordType: SharedPipeConfig.cloudKitAlertRecordType,
            recordID: CKRecord.ID(recordName: alert.id.uuidString)
        )
        record["channel"] = alert.channel.rawValue as CKRecordValue
        record["title"] = alert.title as CKRecordValue
        record["body"] = alert.body as CKRecordValue
        record["scooterID"] = alert.scooterID as CKRecordValue
        record["scooterName"] = alert.scooterName as CKRecordValue
        record["rentalID"] = alert.rentalID.uuidString as CKRecordValue
        record["kindRaw"] = alert.kindRaw as CKRecordValue
        record["recipientName"] = alert.recipientName as CKRecordValue
        record["recipientAddress"] = alert.recipientAddress as CKRecordValue
        record["providerName"] = alert.providerName as CKRecordValue
        record["sentAt"] = alert.sentAt as CKRecordValue
        record["liveDelivery"] = (alert.liveDelivery ? 1 : 0) as CKRecordValue
        return record
    }

    static func record(for member: SharedStaffMember) -> CKRecord {
        let record = CKRecord(
            recordType: SharedPipeConfig.cloudKitStaffRecordType,
            recordID: CKRecord.ID(recordName: member.id.uuidString)
        )
        record["displayName"] = member.displayName as CKRecordValue
        record["phoneE164"] = member.phoneE164 as CKRecordValue
        record["emailsCSV"] = member.emails.joined(separator: ",") as CKRecordValue
        record["isActive"] = (member.isActive ? 1 : 0) as CKRecordValue
        record["updatedAt"] = member.updatedAt as CKRecordValue
        return record
    }

    static func event(from record: CKRecord) -> RentalLifecycleEvent? {
        guard
            let kindRaw = record["kind"] as? String,
            let kind = RentalLifecycleEvent.Kind(rawValue: kindRaw),
            let scooterID = record["scooterID"] as? String,
            let scooterName = record["scooterName"] as? String,
            let rentalString = record["rentalID"] as? String,
            let rentalID = UUID(uuidString: rentalString),
            let startedAt = record["startedAt"] as? Date,
            let occurredAt = record["occurredAt"] as? Date,
            let id = UUID(uuidString: record.recordID.recordName)
        else { return nil }
        let renter = record["renterDisplayName"] as? String
        return RentalLifecycleEvent(
            id: id,
            kind: kind,
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: (renter?.isEmpty == true) ? nil : renter,
            startedAt: startedAt,
            endedAt: record["endedAt"] as? Date,
            occurredAt: occurredAt
        )
    }

    static func alert(from record: CKRecord) -> StaffAlertRecord? {
        guard
            let channelRaw = record["channel"] as? String,
            let channel = StaffAlertChannel(rawValue: channelRaw),
            let title = record["title"] as? String,
            let body = record["body"] as? String,
            let scooterID = record["scooterID"] as? String,
            let scooterName = record["scooterName"] as? String,
            let rentalString = record["rentalID"] as? String,
            let rentalID = UUID(uuidString: rentalString),
            let kindRaw = record["kindRaw"] as? String,
            let recipientName = record["recipientName"] as? String,
            let recipientAddress = record["recipientAddress"] as? String,
            let providerName = record["providerName"] as? String,
            let sentAt = record["sentAt"] as? Date,
            let id = UUID(uuidString: record.recordID.recordName)
        else { return nil }
        let live = (record["liveDelivery"] as? Int64) == 1
        return StaffAlertRecord(
            id: id,
            channel: channel,
            title: title,
            body: body,
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            kindRaw: kindRaw,
            recipientName: recipientName,
            recipientAddress: recipientAddress,
            providerName: providerName,
            sentAt: sentAt,
            liveDelivery: live
        )
    }

    static func staff(from record: CKRecord) -> SharedStaffMember? {
        guard
            let displayName = record["displayName"] as? String,
            let phone = record["phoneE164"] as? String,
            let id = UUID(uuidString: record.recordID.recordName)
        else { return nil }
        let emailsCSV = record["emailsCSV"] as? String ?? ""
        let emails = emailsCSV.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return SharedStaffMember(
            id: id,
            displayName: displayName,
            phoneE164: phone,
            emails: emails,
            isActive: (record["isActive"] as? Int64) != 0,
            updatedAt: record["updatedAt"] as? Date ?? .now
        )
    }
}
