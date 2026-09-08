import Foundation
import SwiftData

enum RentalOperations {
    static func snapshots(from rentals: [Rental]) -> [RentalSnapshot] {
        rentals.map { $0.snapshot() }
    }

    static func activeRental(for scooterID: String, in rentals: [Rental]) -> Rental? {
        rentals.first { $0.scooterID == scooterID && $0.isActive }
    }

    static func validateCheckout(
        scooter: Scooter?,
        rentals: [Rental],
        now: Date,
        accepted: Set<AgreementSectionID>,
        enforceSeasonHours: Bool
    ) throws {
        guard let scooter else { throw CheckoutError.unknownScooter }
        guard FleetCatalog.isKnown(scooter.scooterID) else { throw CheckoutError.unknownScooter }
        guard scooter.isInService else { throw CheckoutError.outOfService }
        if activeRental(for: scooter.scooterID, in: rentals) != nil {
            throw CheckoutError.alreadyRented
        }
        if !AgreementGate.canStartRental(accepted: accepted) {
            throw CheckoutError.agreementsIncomplete
        }
        if enforceSeasonHours {
            if !Season.isInSeason(now) { throw CheckoutError.outsideSeason }
            if !Season.isDuringHours(now) { throw CheckoutError.outsideHours }
        }
        let snaps = snapshots(from: rentals)
        if !CapacityCalculator.hasCapacity(rentals: snaps, at: now, now: now) {
            throw CheckoutError.hourFull
        }
    }

    @MainActor
    static func startRental(
        scooter: Scooter,
        rentals: [Rental],
        accepted: [AgreementAcceptanceRecord],
        now: Date,
        pos: any POSProvider,
        context: ModelContext,
        enforceSeasonHours: Bool
    ) async throws -> Rental {
        let acceptedIDs = Set(accepted.map(\.sectionID))
        try validateCheckout(
            scooter: scooter,
            rentals: rentals,
            now: now,
            accepted: acceptedIDs,
            enforceSeasonHours: enforceSeasonHours
        )

        let rentalID = UUID()
        let token = QRPayload.makeReturnToken()
        let auth: POSAuthorization
        do {
            auth = try await pos.startCheckout(
                rentalID: rentalID,
                scooterID: scooter.scooterID,
                estimatedAmount: BillingCalculator.firstHour
            )
        } catch {
            throw CheckoutError.pos(error.localizedDescription)
        }

        let boundID = scooter.scooterID
        let rental = Rental(
            rentalID: rentalID,
            scooterID: boundID,
            scooterName: scooter.name,
            startedAt: now,
            returnToken: token,
            posAuthorizationID: auth.id,
            lastQuotedAmount: BillingCalculator.firstHour
        )
        context.insert(rental)

        for record in accepted {
            let row = AgreementAcceptance(sectionID: record.sectionID, acceptedAt: record.acceptedAt, rental: rental)
            context.insert(row)
        }

        context.insert(
            POSLedgerEntry(
                rentalID: rentalID,
                kind: .authorize,
                amount: auth.amount,
                providerReference: auth.id,
                note: "First-hour authorization on \(scooter.scooterID)"
            )
        )

        try context.save()
        return rental
    }

    static func rental(matching payload: QRPayload, in rentals: [Rental]) throws -> Rental {
        guard case .returnRental(let rentalID, let token) = payload else {
            throw CheckoutError.invalidReturnQR
        }
        guard let rental = rentals.first(where: { $0.rentalID == rentalID }) else {
            throw CheckoutError.rentalNotFound
        }
        guard rental.returnToken == token else { throw CheckoutError.invalidReturnQR }
        return rental
    }

    @MainActor
    static func checkIn(
        payload: QRPayload,
        rentals: [Rental],
        photos: [ReturnPhotoCapture],
        now: Date,
        pos: any POSProvider,
        context: ModelContext
    ) async throws -> Rental {
        let rental = try rental(matching: payload, in: rentals)
        guard rental.isActive else { throw CheckoutError.alreadyCheckedIn }
        guard ReturnPhotoGate.canCompleteCheckIn(photos: photos) else {
            throw CheckoutError.returnPhotosIncomplete
        }

        let amount = BillingCalculator.charge(elapsed: rental.elapsed(at: now))
        do {
            if let authID = rental.posAuthorizationID {
                let charge = try await pos.finalizeCharge(authorizationID: authID, finalAmount: amount)
                rental.posChargeID = charge.id
                context.insert(
                    POSLedgerEntry(
                        rentalID: rental.rentalID,
                        kind: .capture,
                        amount: charge.amount,
                        providerReference: charge.id,
                        note: "Final capture at check-in"
                    )
                )
            }
        } catch {
            throw CheckoutError.pos(error.localizedDescription)
        }

        for existing in rental.returnPhotos {
            context.delete(existing)
        }
        for photo in photos {
            context.insert(ReturnPhoto(side: photo.side, imageData: photo.jpegData, capturedAt: photo.capturedAt, rental: rental))
        }

        rental.endedAt = now
        rental.status = .completed
        rental.capturedAmount = amount
        rental.lastQuotedAmount = amount
        try context.save()
        return rental
    }
}
