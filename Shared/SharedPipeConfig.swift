import Foundation

enum SharedPipeConfig {
    static let defaultHTTPURLString = "http://127.0.0.1:8787"
    static let urlDefaultsKey = "icystrait.crewEventPipeURL"

    /// Shared public-database container. Customer and crew entitlement files must use this exact id.
    static let cloudKitContainer = "iCloud.com.icystrait.scooterrentals"
    static let cloudKitRecordType = "RentalEvent"
    static let cloudKitAlertRecordType = "StaffAlert"
    static let cloudKitStaffRecordType = "CrewMember"

    /// UserDefaults switch. Ignored unless this binary was built with `CLOUDKIT_ENTITLED`.
    /// A missing key on an entitled build reads as true (TestFlight starts on CloudKit).
    /// An explicit false forces HTTP. Unentitled builds ignore the key.
    static let preferCloudKitDefaultsKey = "icystrait.preferCloudKit"

    /// True only when the target was built with Config/*-CloudKit.xcconfig
    /// (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` includes `CLOUDKIT_ENTITLED`).
    /// Release uses those files. Debug stays on the empty-entitlements xcconfigs.
    static var cloudKitEntitled: Bool {
        #if CLOUDKIT_ENTITLED
        true
        #else
        false
        #endif
    }

    /// Historical name. Matches `cloudKitEntitled` for whichever target compiled this file.
    static var customerCloudKitEntitled: Bool { cloudKitEntitled }

    /// Prefer the CloudKit public database when this build is entitled.
    /// Unentitled builds always return false, even if the defaults key is true.
    static var preferCloudKit: Bool {
        get {
            resolvedPreferCloudKit(
                entitled: cloudKitEntitled,
                stored: UserDefaults.standard.object(forKey: preferCloudKitDefaultsKey)
            )
        }
        set {
            UserDefaults.standard.set(newValue, forKey: preferCloudKitDefaultsKey)
        }
    }

    /// Entitled + missing key is on. Entitled + stored false is off. Unentitled is always off.
    static func resolvedPreferCloudKit(entitled: Bool, stored: Any?) -> Bool {
        guard entitled else { return false }
        guard let stored else { return true }
        if let value = stored as? Bool {
            return value
        }
        if let number = stored as? NSNumber {
            return number.boolValue
        }
        return true
    }

    /// The single runtime gate. HTTP remains the store until this is true.
    static var usesCloudKit: Bool { cloudKitEntitled && preferCloudKit }

    static var liveStoreName: String {
        usesCloudKit ? "CloudKitLotStore" : "HTTPLotStore"
    }

    static var cloudKitStatusLabel: String {
        if !cloudKitEntitled {
            return "Compiled · not entitled on this build"
        }
        if preferCloudKit {
            return "On · HTTP if CloudKit fails"
        }
        return "Entitled · switch off (HTTP)"
    }

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
