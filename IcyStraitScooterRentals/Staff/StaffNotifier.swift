import Foundation

protocol StaffNotifier: Sendable {
    var providerName: String { get }
    func notify(_ message: StaffMessage, recipients: [StaffRecipient]) async throws -> [StaffDispatch]
}

actor MockStaffNotifier: StaffNotifier {
    nonisolated var providerName: String { "MockStaffNotifier" }

    private(set) var outbox: [StaffDispatch] = []
    var simulatedDelayNanoseconds: UInt64 = 160_000_000

    func setDelay(_ value: UInt64) {
        simulatedDelayNanoseconds = value
    }

    func notify(_ message: StaffMessage, recipients: [StaffRecipient]) async throws -> [StaffDispatch] {
        if simulatedDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: simulatedDelayNanoseconds)
        }
        let active = recipients.filter { $0.hasContact }
        guard !active.isEmpty else { throw StaffNotifyError.noRecipients }
        let body = message.body()
        var batch: [StaffDispatch] = []
        for person in active {
            if !person.phoneE164.isEmpty {
                batch.append(
                    StaffDispatch(
                        id: UUID(),
                        staffName: person.displayName,
                        phoneE164: person.phoneE164,
                        email: nil,
                        channel: .sms,
                        body: body,
                        sentAt: .now,
                        kind: message.kind,
                        rentalID: message.rentalID,
                        providerName: providerName,
                        liveDelivery: false
                    )
                )
            }
            for email in person.emails {
                batch.append(
                    StaffDispatch(
                        id: UUID(),
                        staffName: person.displayName,
                        phoneE164: person.phoneE164,
                        email: email,
                        channel: .email,
                        body: body,
                        sentAt: .now,
                        kind: message.kind,
                        rentalID: message.rentalID,
                        providerName: providerName,
                        liveDelivery: false
                    )
                )
            }
        }
        outbox.append(contentsOf: batch)
        return batch
    }
}

/// Compile-ready Twilio shape. Does not send traffic and does not require API keys.
struct TwilioSMSNotifier: StaffNotifier, Sendable {
    var accountSID: String = ""
    var authToken: String = ""
    var fromNumber: String = ""

    var providerName: String { "TwilioSMSNotifier" }

    func notify(_ message: StaffMessage, recipients: [StaffRecipient]) async throws -> [StaffDispatch] {
        let sid = ProcessInfo.processInfo.environment["TWILIO_ACCOUNT_SID"] ?? accountSID
        let token = ProcessInfo.processInfo.environment["TWILIO_AUTH_TOKEN"] ?? authToken
        let from = ProcessInfo.processInfo.environment["TWILIO_FROM_NUMBER"] ?? fromNumber
        guard !sid.isEmpty, !token.isEmpty, !from.isEmpty else {
            throw StaffNotifyError.missingCredentials
        }
        throw StaffNotifyError.stubOnly(
            "TwilioSMSNotifier is a stub. After keys are added, send to every active staff phone (starter \(StaffConfig.defaultDisplay)). v1 uses MockStaffNotifier."
        )
    }
}
