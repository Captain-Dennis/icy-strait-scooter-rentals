import Foundation
import SwiftData

@Model
final class StaffMember {
    @Attribute(.unique) var staffID: UUID
    var displayName: String
    var phoneE164: String
    var emailsCSV: String = ""
    var isActive: Bool
    var createdAt: Date
    var updatedAt: Date = Date(timeIntervalSince1970: 0)

    init(
        staffID: UUID = UUID(),
        displayName: String,
        phoneE164: String,
        emails: [String] = [],
        isActive: Bool = true,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.staffID = staffID
        self.displayName = displayName
        self.phoneE164 = StaffConfig.normalize(phoneE164)
        self.emailsCSV = StaffConfig.joinEmails(emails)
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var emails: [String] {
        get { StaffConfig.parseEmails(emailsCSV) }
        set {
            emailsCSV = StaffConfig.joinEmails(newValue)
            updatedAt = .now
        }
    }

    var displayPhone: String { StaffConfig.display(phoneE164) }

    var recipient: StaffRecipient {
        StaffRecipient(
            id: staffID,
            displayName: displayName,
            phoneE164: phoneE164,
            emails: emails
        )
    }

    var shared: SharedStaffMember {
        SharedStaffMember(
            id: staffID,
            displayName: displayName,
            phoneE164: phoneE164,
            emails: emails,
            isActive: isActive,
            updatedAt: updatedAt
        )
    }

    func apply(_ shared: SharedStaffMember) {
        displayName = shared.displayName
        phoneE164 = StaffConfig.normalize(shared.phoneE164)
        emailsCSV = StaffConfig.joinEmails(shared.emails)
        isActive = shared.isActive
        updatedAt = shared.updatedAt
    }
}

struct StaffRecipient: Equatable, Identifiable, Sendable {
    var id: UUID
    var displayName: String
    var phoneE164: String
    var emails: [String]

    var hasContact: Bool {
        !phoneE164.isEmpty || !emails.isEmpty
    }
}
