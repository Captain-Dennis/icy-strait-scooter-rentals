import Foundation
import SwiftData

@Model
final class StaffMember {
    @Attribute(.unique) var staffID: UUID
    var displayName: String
    var phoneE164: String
    var isActive: Bool
    var createdAt: Date

    init(
        staffID: UUID = UUID(),
        displayName: String,
        phoneE164: String,
        isActive: Bool = true,
        createdAt: Date = .now
    ) {
        self.staffID = staffID
        self.displayName = displayName
        self.phoneE164 = StaffConfig.normalize(phoneE164)
        self.isActive = isActive
        self.createdAt = createdAt
    }

    var displayPhone: String { StaffConfig.display(phoneE164) }

    var recipient: StaffRecipient {
        StaffRecipient(id: staffID, displayName: displayName, phoneE164: phoneE164)
    }
}

struct StaffRecipient: Equatable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var phoneE164: String
}
