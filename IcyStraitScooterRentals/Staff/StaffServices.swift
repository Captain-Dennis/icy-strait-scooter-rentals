import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class StaffServices {
    let notifier: any StaffNotifier
    let mock: MockStaffNotifier
    var lastBanner: String?

    init(mock: MockStaffNotifier = MockStaffNotifier()) {
        self.mock = mock
        self.notifier = mock
    }

    func notifyCheckout(rental: Rental, context: ModelContext) async {
        let message = StaffMessage(
            kind: .checkout,
            rentalID: rental.rentalID,
            scooterID: rental.scooterID,
            scooterName: rental.scooterName,
            occurredAt: rental.startedAt,
            extraNote: ""
        )
        await send(message, context: context)
    }

    func notifyCheckIn(rental: Rental, context: ModelContext) async {
        let message = StaffMessage(
            kind: .checkIn,
            rentalID: rental.rentalID,
            scooterID: rental.scooterID,
            scooterName: rental.scooterName,
            occurredAt: rental.endedAt ?? .now,
            extraNote: "Left and right condition photos were submitted. Please verify the 4-wheel offroad e-scooter is in perfect condition."
        )
        await send(message, context: context)
    }

    func activeRecipients(in context: ModelContext) -> [StaffRecipient] {
        let descriptor = FetchDescriptor<StaffMember>(sortBy: [SortDescriptor(\.displayName)])
        let people = (try? context.fetch(descriptor)) ?? []
        return people.filter { $0.isActive }.map(\.recipient)
    }

    private func send(_ message: StaffMessage, context: ModelContext) async {
        let recipients = activeRecipients(in: context)
        do {
            let dispatches = try await notifier.notify(message, recipients: recipients)
            for dispatch in dispatches {
                context.insert(
                    StaffSMSLog(
                        staffName: dispatch.staffName,
                        phoneE164: dispatch.phoneE164,
                        kind: dispatch.kind,
                        body: dispatch.body,
                        rentalID: dispatch.rentalID,
                        providerName: dispatch.providerName,
                        sentAt: dispatch.sentAt
                    )
                )
            }
            try? context.save()
            if dispatches.count == 1, let only = dispatches.first {
                lastBanner = only.bannerText
            } else if dispatches.count > 1 {
                lastBanner = "SMS sent to \(dispatches.count) staff · \(dispatches[0].displayPhone) and others"
            }
        } catch {
            lastBanner = error.localizedDescription
        }
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
