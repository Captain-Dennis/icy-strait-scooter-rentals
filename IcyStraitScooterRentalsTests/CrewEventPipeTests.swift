import XCTest
@testable import IcyStraitScooterRentals

final class CrewEventPipeTests: XCTestCase {
    func testBoardShowsExactUnitOutThenBack() {
        let rentalID = UUID()
        let checkout = RentalLifecycleEvent.checkout(
            scooterID: "IS-104",
            scooterName: "Otter",
            rentalID: rentalID,
            renterDisplayName: "Walk-up guest",
            startedAt: Date(timeIntervalSince1970: 1_814_000_000)
        )
        var rows = CrewBoard.rows(events: [checkout], units: FleetCatalog.boardUnits)
        XCTAssertEqual(rows.count, 6)
        XCTAssertEqual(rows.map(\.scooterID), FleetCatalog.ids)
        let otter = rows.first { $0.scooterID == "IS-104" }
        XCTAssertEqual(otter?.status, .out)
        XCTAssertEqual(otter?.renterDisplayName, "Walk-up guest")
        XCTAssertEqual(otter?.scooterName, "Otter")
        XCTAssertEqual(CrewBoard.outCount(in: rows), 1)

        let returned = RentalLifecycleEvent.returned(
            scooterID: "IS-104",
            scooterName: "Otter",
            rentalID: rentalID,
            renterDisplayName: "Walk-up guest",
            startedAt: checkout.startedAt,
            endedAt: Date(timeIntervalSince1970: 1_814_003_600)
        )
        rows = CrewBoard.rows(events: [checkout, returned], units: FleetCatalog.boardUnits)
        XCTAssertEqual(rows.first { $0.scooterID == "IS-104" }?.status, .back)
        XCTAssertEqual(CrewBoard.outCount(in: rows), 0)
    }

    func testNotificationPayloadNamesExactUnitRenterAndTime() {
        for unit in FleetCatalog.units {
            let checkout = RentalLifecycleEvent.checkout(
                scooterID: unit.id,
                scooterName: unit.name,
                rentalID: UUID(),
                renterDisplayName: "Dennis guest",
                startedAt: Date(timeIntervalSince1970: 1_814_000_000)
            )
            let push = CrewAlertCopy.payload(for: checkout)
            XCTAssertTrue(push.title.contains(unit.id), "Push must name \(unit.id)")
            XCTAssertTrue(push.title.contains(unit.name))
            XCTAssertTrue(push.body.contains(unit.id))
            XCTAssertTrue(push.body.contains(unit.name))
            XCTAssertTrue(push.body.contains("Dennis guest"))
            XCTAssertTrue(push.body.contains("AK"))
            XCTAssertEqual(push.userInfo["scooterID"], unit.id)

            let returned = RentalLifecycleEvent.returned(
                scooterID: unit.id,
                scooterName: unit.name,
                rentalID: checkout.rentalID,
                renterDisplayName: "Dennis guest",
                startedAt: checkout.startedAt,
                endedAt: Date(timeIntervalSince1970: 1_814_003_600)
            )
            let back = CrewAlertCopy.payload(for: returned)
            XCTAssertTrue(back.title.contains(unit.id))
            XCTAssertTrue(back.title.contains(unit.name))
            XCTAssertTrue(back.body.contains("returned"))
            XCTAssertTrue(back.body.contains("Dennis guest"))
        }
    }

    func testPublisherWritesCheckoutAndReturnOntoSharedStore() async throws {
        let store = InMemoryLotStore()
        let notifier = MockStaffNotifier()
        await notifier.setDelay(0)
        let publisher = LotEventPublisher(store: store, notifier: notifier)
        let rentalID = UUID()
        let recipients = [
            StaffRecipient(
                id: StaffConfig.starterStaffID,
                displayName: StaffConfig.starterName,
                phoneE164: StaffConfig.defaultE164,
                emails: StaffConfig.defaultEmails
            )
        ]

        let checkout = await publisher.publishCheckout(
            rentalID: rentalID,
            scooterID: "IS-103",
            scooterName: "Spruce",
            renterDisplayName: "Guest",
            startedAt: Date(timeIntervalSince1970: 1_814_000_000),
            recipients: recipients
        )
        XCTAssertTrue(checkout.eventPublished)
        XCTAssertTrue(checkout.push.title.contains("IS-103"))
        XCTAssertTrue(checkout.push.title.contains("Spruce"))
        XCTAssertGreaterThanOrEqual(checkout.dispatches.count, 3, "SMS plus two emails")
        XCTAssertTrue(checkout.dispatches.contains { $0.channel == .sms && $0.phoneE164 == StaffConfig.defaultE164 })
        XCTAssertTrue(checkout.dispatches.contains { $0.channel == .email && $0.email == "maddasstoner@yahoo.com" })
        XCTAssertTrue(checkout.dispatches.contains { $0.channel == .email && $0.email == "f.vhappytimes@gmail.com" })

        let returned = await publisher.publishReturn(
            rentalID: rentalID,
            scooterID: "IS-103",
            scooterName: "Spruce",
            renterDisplayName: "Guest",
            startedAt: Date(timeIntervalSince1970: 1_814_000_000),
            endedAt: Date(timeIntervalSince1970: 1_814_003_600),
            recipients: recipients
        )
        XCTAssertTrue(returned.eventPublished)
        XCTAssertTrue(returned.push.title.contains("IS-103"))

        let snap = try await store.snapshot()
        XCTAssertEqual(snap.events.count, 2)
        XCTAssertEqual(snap.events.map(\.kind), [.checkout, .returned])
        XCTAssertTrue(snap.events.allSatisfy { $0.scooterID == "IS-103" })
        XCTAssertTrue(snap.alerts.contains { $0.channel == .push && $0.title.contains("IS-103 Spruce") })
        let rows = CrewBoard.rows(events: snap.events, units: FleetCatalog.boardUnits)
        XCTAssertEqual(rows.first { $0.scooterID == "IS-103" }?.status, .back)
    }

    func testDennisRosterDefaults() {
        XCTAssertEqual(StaffConfig.starterName, "Front desk / Dennis")
        XCTAssertEqual(StaffConfig.defaultE164, "+19075005152")
        XCTAssertEqual(StaffConfig.defaultEmails, ["maddasstoner@yahoo.com", "f.vhappytimes@gmail.com"])
        XCTAssertEqual(StaffConfig.betaPIN, "5152")
        XCTAssertEqual(StaffConfig.parseEmails("maddasstoner@yahoo.com, f.vhappytimes@gmail.com").count, 2)
    }

    func testHTTPStoreRoundTripAgainstTinyServer() async throws {
        guard let server = ProcessInfo.processInfo.environment["ICY_STRAIT_LOT_TEST_URL"],
              let url = URL(string: server)
        else {
            throw XCTSkip("Set ICY_STRAIT_LOT_TEST_URL to exercise the live HTTP pipe.")
        }
        let store = HTTPLotStore(baseURL: url)
        let event = RentalLifecycleEvent.checkout(
            scooterID: "IS-106",
            scooterName: "Tidepool",
            rentalID: UUID(),
            renterDisplayName: "HTTP guest",
            startedAt: Date(timeIntervalSince1970: 1_814_100_000)
        )
        try await store.publish(event)
        let snap = try await store.snapshot()
        XCTAssertTrue(snap.events.contains { $0.id == event.id && $0.scooterID == "IS-106" })
    }
}
