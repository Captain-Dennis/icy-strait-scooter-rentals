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
    /// Missing key reads as false, so shipping and newly entitled builds stay on HTTP.
    static let preferCloudKitDefaultsKey = "icystrait.preferCloudKit"

    /// True only when the target was built with Config/*-CloudKit.xcconfig
    /// (`SWIFT_ACTIVE_COMPILATION_CONDITIONS` includes `CLOUDKIT_ENTITLED`).
    /// Shipping Debug/Release xcconfigs do not set that flag.
    static var cloudKitEntitled: Bool {
        #if CLOUDKIT_ENTITLED
        true
        #else
        false
        #endif
    }

    /// Historical name. False on the shipping customer and crew builds.
    static var customerCloudKitEntitled: Bool { cloudKitEntitled }

    /// Prefer the CloudKit public database when this build is entitled.
    /// Unentitled builds always return false, even if the defaults key is true.
    static var preferCloudKit: Bool {
        get {
            guard cloudKitEntitled else { return false }
            return UserDefaults.standard.bool(forKey: preferCloudKitDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: preferCloudKitDefaultsKey)
        }
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
