import Foundation

/// Builds the per-unit event + SMS/email/push copies and writes them to the shared pipe.
actor LotEventPublisher {
    private let store: any SharedLotStore
    private let notifier: any StaffNotifier

    init(store: any SharedLotStore, notifier: any StaffNotifier) {
        self.store = store
        self.notifier = notifier
    }

    func publishCheckout(
        rentalID: UUID,
        scooterID: String,
        scooterName: String,
        renterDisplayName: String?,
        startedAt: Date,
        recipients: [StaffRecipient]
    ) async -> PublishResult {
        let event = RentalLifecycleEvent.checkout(
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: renterDisplayName,
            startedAt: startedAt
        )
        return await publish(event: event, extraNote: "", recipients: recipients)
    }

    func publishReturn(
        rentalID: UUID,
        scooterID: String,
        scooterName: String,
        renterDisplayName: String?,
        startedAt: Date,
        endedAt: Date,
        recipients: [StaffRecipient]
    ) async -> PublishResult {
        let event = RentalLifecycleEvent.returned(
            scooterID: scooterID,
            scooterName: scooterName,
            rentalID: rentalID,
            renterDisplayName: renterDisplayName,
            startedAt: startedAt,
            endedAt: endedAt
        )
        return await publish(
            event: event,
            extraNote: "Left and right condition photos were submitted. Please verify the 4-wheel offroad e-scooter is in perfect condition.",
            recipients: recipients
        )
    }

    func publish(event: RentalLifecycleEvent, extraNote: String, recipients: [StaffRecipient]) async -> PublishResult {
        var result = PublishResult(event: event, push: CrewAlertCopy.payload(for: event))
        do {
            try await store.publish(event)
            result.eventPublished = true
        } catch {
            result.eventError = error.localizedDescription
        }

        let message = StaffMessage(
            kind: event.kind == .checkout ? .checkout : .checkIn,
            rentalID: event.rentalID,
            scooterID: event.scooterID,
            scooterName: event.scooterName,
            occurredAt: event.occurredAt,
            extraNote: extraNote,
            renterDisplayName: event.renterDisplayName
        )

        do {
            let dispatches = try await notifier.notify(message, recipients: recipients)
            result.dispatches = dispatches
            for dispatch in dispatches {
                let alert = StaffAlertRecord(
                    id: dispatch.id,
                    channel: dispatch.channel,
                    title: result.push.title,
                    body: dispatch.body,
                    scooterID: event.scooterID,
                    scooterName: event.scooterName,
                    rentalID: event.rentalID,
                    kindRaw: event.kind == .checkout ? StaffMessage.Kind.checkout.rawValue : StaffMessage.Kind.checkIn.rawValue,
                    recipientName: dispatch.staffName,
                    recipientAddress: dispatch.address,
                    providerName: dispatch.providerName,
                    sentAt: dispatch.sentAt,
                    liveDelivery: dispatch.liveDelivery
                )
                try? await store.publishAlert(alert)
                result.alerts.append(alert)
            }
        } catch {
            result.notifyError = error.localizedDescription
            let fallback = StaffAlertRecord(
                channel: .push,
                title: result.push.title,
                body: result.push.body,
                scooterID: event.scooterID,
                scooterName: event.scooterName,
                rentalID: event.rentalID,
                kindRaw: event.kind == .checkout ? StaffMessage.Kind.checkout.rawValue : StaffMessage.Kind.checkIn.rawValue,
                recipientName: "Crew",
                recipientAddress: "push",
                providerName: "CrewAlertCopy",
                liveDelivery: false
            )
            try? await store.publishAlert(fallback)
            result.alerts.append(fallback)
        }

        let pushAlert = StaffAlertRecord(
            channel: .push,
            title: result.push.title,
            body: result.push.body,
            scooterID: event.scooterID,
            scooterName: event.scooterName,
            rentalID: event.rentalID,
            kindRaw: event.kind == .checkout ? StaffMessage.Kind.checkout.rawValue : StaffMessage.Kind.checkIn.rawValue,
            recipientName: "Crew phones",
            recipientAddress: "apns-not-wired",
            providerName: "CrewNotificationPayload",
            liveDelivery: false
        )
        try? await store.publishAlert(pushAlert)
        result.alerts.append(pushAlert)
        return result
    }

    struct PublishResult: Sendable {
        var event: RentalLifecycleEvent
        var push: CrewAlertCopy.Payload
        var eventPublished: Bool = false
        var eventError: String?
        var notifyError: String?
        var dispatches: [StaffDispatch] = []
        var alerts: [StaffAlertRecord] = []
    }
}
