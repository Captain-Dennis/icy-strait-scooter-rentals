import Foundation

enum SharedPipeConfig {
    static let defaultHTTPURLString = "http://127.0.0.1:8787"
    static let urlDefaultsKey = "icystrait.crewEventPipeURL"
    static let cloudKitContainer = "iCloud.com.icystrait.scooterrentals"
    static let cloudKitRecordType = "RentalEvent"
    static let cloudKitAlertRecordType = "StaffAlert"
    static let cloudKitStaffRecordType = "CrewMember"

    /// Customer TestFlight stays on the empty entitlements file.
    /// CloudKit is compiled, but not entitled on the shipping customer app.
    static let customerCloudKitEntitled = false

    static var httpBaseURL: URL {
        let stored = UserDefaults.standard.string(forKey: urlDefaultsKey)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let url = URL(string: stored), url.scheme != nil {
            return url
        }
        return URL(string: defaultHTTPURLString)!
    }

    static func setHTTPBaseURL(_ raw: String) {
        UserDefaults.standard.set(raw.trimmingCharacters(in: .whitespacesAndNewlines), forKey: urlDefaultsKey)
    }
}
