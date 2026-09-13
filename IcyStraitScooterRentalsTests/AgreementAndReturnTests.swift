import SwiftData
import XCTest
@testable import IcyStraitScooterRentals

final class AgreementAndReturnTests: XCTestCase {
    func testAreaOfOperationBansDirtRoadsAndPortProperty() {
        let copy = AgreementLibrary.copy(for: .areaOfOperation)
        XCTAssertTrue(copy.bullets.contains(where: { $0.contains("NOT allowed on any dirt roads") }))
        XCTAssertTrue(copy.bullets.contains(where: { $0.contains("NOT allowed on any Icy Strait Port property") }))
        XCTAssertEqual(
            AgreementSectionID.areaOfOperation.acceptLabel,
            "I will stay off dirt roads and all Icy Strait Port property"
        )
        XCTAssertFalse(AgreementGate.canStartRental(accepted: Set(AgreementSectionID.allCases).subtracting([.areaOfOperation])))
    }

    func testCheckoutRequiresAllFiveSectionsIncludingLiability() {
        XCTAssertEqual(AgreementSectionID.allCases.count, 5)
        XCTAssertTrue(AgreementSectionID.allCases.contains(.damageAndLiability))
        XCTAssertFalse(AgreementGate.canStartRental(accepted: []))
        XCTAssertFalse(AgreementGate.canStartRental(accepted: [.rentalAgreement, .useRestrictions, .areaOfOperation, .safetyAndReturn]))
        XCTAssertEqual(AgreementGate.missing(from: [.rentalAgreement]), [.useRestrictions, .areaOfOperation, .damageAndLiability, .safetyAndReturn])
        XCTAssertTrue(AgreementGate.canStartRental(accepted: Set(AgreementSectionID.allCases)))
    }

    func testStartRentalValidationRejectsMissingAgreements() {
        let scooter = Scooter(
            scooterID: "IS-101",
            name: "Glacier",
            dockLabel: "Dock A",
            batteryPercent: 90,
            estimatedRangeMiles: 25,
            sortIndex: 0
        )
        XCTAssertThrowsError(
            try RentalOperations.validateCheckout(
                scooter: scooter,
                rentals: [],
                now: Date(),
                accepted: [],
                enforceSeasonHours: false
            )
        ) { error in
            XCTAssertEqual(error as? CheckoutError, .agreementsIncomplete)
        }
        XCTAssertNoThrow(
            try RentalOperations.validateCheckout(
                scooter: scooter,
                rentals: [],
                now: Date(),
                accepted: Set(AgreementSectionID.allCases),
                enforceSeasonHours: false
            )
        )
    }

    func testAgreementSectionsCannotBeSkipped() {
        XCTAssertTrue(AgreementGate.canOpen(.rentalAgreement, accepted: []))
        XCTAssertFalse(AgreementGate.canOpen(.useRestrictions, accepted: []))
        XCTAssertFalse(AgreementGate.canOpen(.damageAndLiability, accepted: [.rentalAgreement, .useRestrictions]))
        XCTAssertTrue(AgreementGate.canOpen(.damageAndLiability, accepted: [.rentalAgreement, .useRestrictions, .areaOfOperation]))
        XCTAssertFalse(AgreementGate.canOpen(.safetyAndReturn, accepted: [.rentalAgreement, .useRestrictions, .areaOfOperation, .safetyAndReturn]))
    }

    func testReturnPhotosAreLeftAndRightOnly() {
        XCTAssertEqual(ReturnPhotoSide.allCases.map(\.rawValue), ["left", "right"])
        XCTAssertFalse(ReturnPhotoGate.canCompleteCheckIn(captured: []))
        XCTAssertFalse(ReturnPhotoGate.canCompleteCheckIn(captured: [.left]))
        XCTAssertTrue(ReturnPhotoGate.canCompleteCheckIn(captured: [.left, .right]))
        XCTAssertEqual(ReturnPhotoSide.left.progressTitle, "Photo 1 of 2 — Left side")
        XCTAssertEqual(ReturnPhotoSide.right.progressTitle, "Photo 2 of 2 — Right side")
    }

    func testQRPayloads() {
        XCTAssertEqual(QRPayload.parse("escooter://scooter/IS-101"), .scooter(id: "IS-101"))
        XCTAssertEqual(QRPayload.parse("https://icystraitscooters.example/s/IS-101"), .scooter(id: "IS-101"))
        XCTAssertEqual(QRPayload.parse("https://www.icystraitscooters.example/s/is-106"), .scooter(id: "IS-106"))
        XCTAssertEqual(QRPayload.parse("https://icystraitscooters.example/s/?id=IS-103"), .scooter(id: "IS-103"))
        XCTAssertEqual(QRPayload.parse("is-106"), .scooter(id: "IS-106"))
        XCTAssertEqual(QRPayload.scooter(id: "IS-101").urlString, "https://icystraitscooters.example/s/IS-101")
        XCTAssertEqual(QRPayload.scooter(id: "IS-101").customSchemeURLString, "escooter://scooter/IS-101")
        let rentalID = UUID()
        let parsed = QRPayload.parse("escooter://return/\(rentalID.uuidString)/ABCD2345")
        XCTAssertEqual(parsed, .returnRental(rentalID: rentalID, token: "ABCD2345"))
        XCTAssertEqual(
            QRPayload.parse("https://icystraitscooters.example/r/\(rentalID.uuidString)/ABCD2345"),
            .returnRental(rentalID: rentalID, token: "ABCD2345")
        )
    }

    func testEachScooterHasAUniqueCheckoutQR() {
        XCTAssertEqual(FleetCatalog.ids, ["IS-101", "IS-102", "IS-103", "IS-104", "IS-105", "IS-106"])
        let links = FleetCatalog.uniqueCheckoutLinks
        XCTAssertEqual(links.count, 6)
        XCTAssertEqual(Set(links).count, 6, "Checkout QRs must never be shared across units")
        for sticker in FleetCatalog.stickerPayloads {
            XCTAssertEqual(QRPayload.parse(sticker.httpsPayload), .scooter(id: sticker.id))
            XCTAssertEqual(QRPayload.parse(sticker.customSchemePayload), .scooter(id: sticker.id))
            XCTAssertEqual(QRPayload.parse(sticker.barePayload), .scooter(id: sticker.id))
            XCTAssertTrue(sticker.httpsPayload.hasSuffix("/s/\(sticker.id)"))
            XCTAssertFalse(sticker.httpsPayload.contains("any"))
        }
    }

    func testSharedOrUnknownScooterQRIsRejected() {
        XCTAssertNil(QRPayload.parse("https://icystraitscooters.example/s/any"))
        XCTAssertNil(QRPayload.parse("https://icystraitscooters.example/s/fleet"))
        XCTAssertNil(QRPayload.parse("https://icystraitscooters.example/s/IS-999"))
        XCTAssertNil(QRPayload.parse("escooter://scooter/ANY"))
        XCTAssertNil(QRPayload.parse("escooter://scooter/IS-999"))
        XCTAssertNil(QRPayload.parse("IS-999"))
        XCTAssertNil(QRPayload.parse("FLEET"))
        XCTAssertNil(QRPayload.parse("https://icystraitscooters.example/"))
    }

    func testUnknownScooterCannotStartRental() {
        let scooter = Scooter(
            scooterID: "IS-999",
            name: "Unknown",
            dockLabel: "None",
            batteryPercent: 50,
            estimatedRangeMiles: 10,
            sortIndex: 99
        )
        XCTAssertThrowsError(
            try RentalOperations.validateCheckout(
                scooter: scooter,
                rentals: [],
                now: Date(),
                accepted: Set(AgreementSectionID.allCases),
                enforceSeasonHours: false
            )
        ) { error in
            XCTAssertEqual(error as? CheckoutError, .unknownScooter)
        }
    }

    @MainActor
    func testStartRentalStoresExactScannedScooterID() async throws {
        let schema = Schema([
            Scooter.self,
            Rental.self,
            AgreementAcceptance.self,
            ReturnPhoto.self,
            POSLedgerEntry.self,
            StaffMember.self,
            StaffSMSLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [configuration])
        let context = ModelContext(container)
        let scooter = Scooter(
            scooterID: "IS-103",
            name: "Spruce",
            dockLabel: "Dock C · Lodge loop",
            batteryPercent: 91,
            estimatedRangeMiles: 27,
            sortIndex: 2
        )
        let accepted = AgreementSectionID.allCases.map {
            AgreementAcceptanceRecord(sectionID: $0, acceptedAt: Date())
        }
        let pos = MockPOSProvider()
        let rental = try await RentalOperations.startRental(
            scooter: scooter,
            rentals: [],
            accepted: accepted,
            now: Date(),
            pos: pos,
            context: context,
            enforceSeasonHours: false
        )
        XCTAssertEqual(rental.scooterID, "IS-103")
        XCTAssertEqual(rental.scooterName, "Spruce")
    }

    func testStaffCheckoutSMSIncludesExactScooterID() {
        for unit in FleetCatalog.units {
            let message = StaffMessage(
                kind: .checkout,
                rentalID: UUID(),
                scooterID: unit.id,
                scooterName: unit.name,
                occurredAt: Date(timeIntervalSince1970: 1_814_000_000),
                extraNote: ""
            )
            XCTAssertTrue(message.body().contains(unit.id), "Staff SMS must name \(unit.id)")
            XCTAssertTrue(message.body().contains(unit.name))
            XCTAssertTrue(message.body().contains("exact unit"))
            XCTAssertTrue(message.body().contains(unit.id + " " + unit.name) || message.body().contains("\(unit.id) \(unit.name)"))
        }
    }

    func testStaffPhoneNormalization() {
        XCTAssertEqual(StaffConfig.normalize("9075005152"), "+19075005152")
        XCTAssertEqual(StaffConfig.normalize("(907) 500-5152"), "+19075005152")
        XCTAssertEqual(StaffConfig.display("+19075005152"), "+1 (907) 500-5152")
        XCTAssertTrue(StaffConfig.isValidPhone("9075005152"))
        XCTAssertFalse(StaffConfig.isValidPhone("555"))
    }
}

final class StaffNotifierTests: XCTestCase {
    func testMockSendsToEveryActiveRecipient() async throws {
        let notifier = MockStaffNotifier()
        await notifier.setDelay(0)
        let rentalID = UUID()
        let message = StaffMessage(
            kind: .checkout,
            rentalID: rentalID,
            scooterID: "IS-101",
            scooterName: "Glacier",
            occurredAt: Date(timeIntervalSince1970: 1_814_000_000),
            extraNote: ""
        )
        let recipients = [
            StaffRecipient(id: UUID(), displayName: "Front desk", phoneE164: "+19075005152", emails: []),
            StaffRecipient(id: UUID(), displayName: "Lot lead", phoneE164: "+19075550101", emails: [])
        ]
        let sent = try await notifier.notify(message, recipients: recipients)
        XCTAssertEqual(sent.count, 2)
        XCTAssertEqual(sent.map(\.phoneE164), ["+19075005152", "+19075550101"])
        XCTAssertTrue(sent[0].body.contains("IS-101"))
        XCTAssertTrue(sent[0].bannerText.contains("Front desk"))
        XCTAssertTrue(sent[0].bannerText.contains("+1 (907) 500-5152"))
    }

    func testMockCheckInMentionsConditionPhotos() async throws {
        let notifier = MockStaffNotifier()
        await notifier.setDelay(0)
        let message = StaffMessage(
            kind: .checkIn,
            rentalID: UUID(),
            scooterID: "IS-102",
            scooterName: "Humpback",
            occurredAt: .now,
            extraNote: "Left and right condition photos were submitted. Please verify the 4-wheel offroad e-scooter is in perfect condition."
        )
        let sent = try await notifier.notify(
            message,
            recipients: [StaffRecipient(id: UUID(), displayName: "Front desk", phoneE164: StaffConfig.defaultE164, emails: [])]
        )
        XCTAssertTrue(sent[0].body.contains("Left and right condition photos"))
        XCTAssertTrue(sent[0].body.contains("IS-102"))
    }
}
