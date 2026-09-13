import Foundation

/// Push / banner / SMS wording. Always names the exact stem-sticker unit.
enum CrewAlertCopy {
    struct Payload: Equatable, Sendable {
        var title: String
        var body: String
        var scooterID: String
        var scooterName: String
        var kind: RentalLifecycleEvent.Kind

        var userInfo: [String: String] {
            [
                "scooterID": scooterID,
                "scooterName": scooterName,
                "kind": kind.rawValue,
                "unitLabel": "\(scooterID) \(scooterName)"
            ]
        }
    }

    static func alaskaTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(identifier: "America/Juneau") ?? .current
        formatter.dateFormat = "MMM d, h:mm a"
        return formatter.string(from: date) + " AK"
    }

    static func payload(for event: RentalLifecycleEvent) -> Payload {
        let unit = event.unitLabel
        let renter = event.renterLabel
        let time = alaskaTime(event.occurredAt)
        switch event.kind {
        case .checkout:
            return Payload(
                title: "\(unit) checked out",
                body: "\(renter) took \(unit) at \(time).",
                scooterID: event.scooterID,
                scooterName: event.scooterName,
                kind: .checkout
            )
        case .returned:
            return Payload(
                title: "\(unit) is back",
                body: "\(renter) returned \(unit) at \(time).",
                scooterID: event.scooterID,
                scooterName: event.scooterName,
                kind: .returned
            )
        }
    }

    static func smsBody(for event: RentalLifecycleEvent, extraNote: String = "") -> String {
        let unit = event.unitLabel
        let renter = event.renterLabel
        let time = alaskaTime(event.occurredAt)
        let shortID = String(event.rentalID.uuidString.prefix(8))
        switch event.kind {
        case .checkout:
            return "Icy Strait: \(unit) checkout. \(renter) started \(time). Rental \(shortID). Stage that exact unit — not another scooter."
        case .returned:
            let note = extraNote.isEmpty
                ? "Left and right condition photos were submitted. Please verify the 4-wheel offroad e-scooter is in perfect condition."
                : extraNote
            return "Icy Strait: \(unit) return. \(renter) checked in \(time). Rental \(shortID). \(note)"
        }
    }
}
