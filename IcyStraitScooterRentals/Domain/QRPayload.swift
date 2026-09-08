import Foundation

enum QRPayload: Equatable {
    case scooter(id: String)
    case returnRental(rentalID: UUID, token: String)

    static let scheme = "escooter"

    /// Preferred on-scooter QR: https smart link. Custom scheme remains for Simulator demos.
    var urlString: String {
        switch self {
        case .scooter(let id):
            return AppLinkConfig.scooterSmartLink(id: id)
        case .returnRental(let rentalID, let token):
            return customSchemeURLString
        }
    }

    var customSchemeURLString: String {
        switch self {
        case .scooter(let id):
            return "\(Self.scheme)://scooter/\(id)"
        case .returnRental(let rentalID, let token):
            return "\(Self.scheme)://return/\(rentalID.uuidString)/\(token)"
        }
    }

    var url: URL? { URL(string: urlString) }

    static func parse(_ raw: String) -> QRPayload? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let url = URL(string: trimmed) {
            return parse(url: url) ?? parseBareScooterID(trimmed)
        }
        return parseBareScooterID(trimmed)
    }

    static func parse(url: URL) -> QRPayload? {
        let scheme = url.scheme?.lowercased() ?? ""
        if scheme == Self.scheme {
            return parseCustomScheme(url)
        }
        if scheme == "https" || scheme == "http" {
            return parseSmartLink(url)
        }
        return parseBareScooterID(url.absoluteString)
    }

    private static func parseCustomScheme(_ url: URL) -> QRPayload? {
        let host = url.host?.lowercased() ?? ""
        let parts = url.path.split(separator: "/").map(String.init)
        if host == "scooter" {
            guard let id = parts.first, isScooterID(id) else { return nil }
            return .scooter(id: normalizeScooterID(id))
        }
        if host == "return" {
            guard parts.count >= 2,
                  let rentalID = UUID(uuidString: parts[0]) else { return nil }
            let token = parts[1]
            guard !token.isEmpty else { return nil }
            return .returnRental(rentalID: rentalID, token: token)
        }
        return nil
    }

    private static func parseSmartLink(_ url: URL) -> QRPayload? {
        guard AppLinkConfig.isSmartLinkHost(url.host) else { return nil }
        let parts = url.path.split(separator: "/").map(String.init)
        if parts.count >= 2, parts[0].lowercased() == "s", isScooterID(parts[1]) {
            return .scooter(id: normalizeScooterID(parts[1]))
        }
        if parts.count >= 3, parts[0].lowercased() == "r",
           let rentalID = UUID(uuidString: parts[1]), !parts[2].isEmpty {
            return .returnRental(rentalID: rentalID, token: parts[2])
        }
        if let id = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.first(where: { $0.name == "id" })?.value,
           isScooterID(id) {
            return .scooter(id: normalizeScooterID(id))
        }
        return nil
    }

    static func parseBareScooterID(_ raw: String) -> QRPayload? {
        let id = normalizeScooterID(raw)
        guard isScooterID(id) else { return nil }
        return .scooter(id: id)
    }

    static func normalizeScooterID(_ raw: String) -> String {
        raw.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    /// Only the six catalog IDs. Shared “any / fleet” payloads are not scooter QRs.
    static func isScooterID(_ raw: String) -> Bool {
        FleetCatalog.isKnown(raw)
    }

    static func makeReturnToken() -> String {
        let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ23456789")
        return String((0..<8).map { _ in letters.randomElement()! })
    }
}
