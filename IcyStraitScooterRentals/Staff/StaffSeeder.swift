import Foundation
import SwiftData

enum StaffSeeder {
    @MainActor
    static func seedIfNeeded(context: ModelContext) throws {
        if UserDefaults.standard.bool(forKey: AppPreferences.staffSeededKey) {
            try upgradeDennisProfile(context: context)
            return
        }
        let existing = try context.fetch(FetchDescriptor<StaffMember>())
        if existing.isEmpty {
            context.insert(
                StaffMember(
                    staffID: StaffConfig.starterStaffID,
                    displayName: StaffConfig.starterName,
                    phoneE164: StaffConfig.defaultE164,
                    emails: StaffConfig.defaultEmails,
                    isActive: true
                )
            )
            try context.save()
        }
        UserDefaults.standard.set(true, forKey: AppPreferences.staffSeededKey)
        try upgradeDennisProfile(context: context)
    }

    /// Fill emails / Dennis name on the original Front desk row. Never recreates a deleted roster.
    @MainActor
    static func upgradeDennisProfile(context: ModelContext) throws {
        let people = try context.fetch(FetchDescriptor<StaffMember>())
        guard let desk = people.first(where: { $0.phoneE164 == StaffConfig.defaultE164 }) else { return }
        var changed = false
        if desk.displayName == "Front desk" {
            desk.displayName = StaffConfig.starterName
            changed = true
        }
        if desk.emails.isEmpty {
            desk.emails = StaffConfig.defaultEmails
            changed = true
        }
        if changed {
            desk.updatedAt = .now
            try context.save()
        }
    }
}
