import SwiftData
import SwiftUI

struct StaffRosterView: View {
    @Query(sort: \StaffMember.displayName) private var staff: [StaffMember]
    @Environment(\.modelContext) private var modelContext
    @Environment(StaffServices.self) private var staffServices
    @State private var editor: StaffDraft?
    @State private var confirmDelete: StaffMember?

    var body: some View {
        List {
            Section {
                Text("Active staff receive a mock SMS on every checkout and every return check-in. Disable someone to leave them on the roster without alerts.")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
                    .listRowBackground(Brand.card)
            }

            Section("Roster") {
                if staff.isEmpty {
                    Text("No staff yet. Add a lot employee.")
                        .foregroundStyle(Brand.silver)
                        .listRowBackground(Brand.card)
                }
                ForEach(staff, id: \.staffID) { person in
                    Button {
                        editor = StaffDraft(person)
                    } label: {
                        HStack(alignment: .top, spacing: 12) {
                            Circle()
                                .fill(person.isActive ? Brand.orange : Brand.slate)
                                .frame(width: 10, height: 10)
                                .padding(.top, 6)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(person.displayName)
                                    .font(BrandFont.headline(16))
                                    .foregroundStyle(.white)
                                Text(person.displayPhone)
                                    .font(.subheadline.monospaced())
                                    .foregroundStyle(Brand.silver)
                                if !person.emails.isEmpty {
                                    Text(person.emails.joined(separator: ", "))
                                        .font(.caption)
                                        .foregroundStyle(Brand.silver)
                                }
                                Text(person.isActive ? "Active — receives SMS + email copy" : "Disabled")
                                    .font(.caption)
                                    .foregroundStyle(person.isActive ? Brand.ok : Brand.silver)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(Brand.silver)
                        }
                    }
                    .listRowBackground(Brand.card)
                    .swipeActions {
                        Button(person.isActive ? "Disable" : "Enable") {
                            person.isActive.toggle()
                            try? modelContext.save()
                        }
                        .tint(person.isActive ? .gray : Brand.orange)
                        Button("Delete", role: .destructive) {
                            confirmDelete = person
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.background)
        .navigationTitle("Staff")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    editor = StaffDraft()
                } label: {
                    Image(systemName: "plus")
                }
                .foregroundStyle(Brand.orange)
            }
        }
        .sheet(item: $editor) { draft in
            StaffEditorView(draft: draft) { result in
                save(result)
            }
        }
        .alert("Remove staff?", isPresented: Binding(
            get: { confirmDelete != nil },
            set: { if !$0 { confirmDelete = nil } }
        )) {
            Button("Delete", role: .destructive) {
                if let person = confirmDelete {
                    modelContext.delete(person)
                    try? modelContext.save()
                }
                confirmDelete = nil
            }
            Button("Cancel", role: .cancel) { confirmDelete = nil }
        } message: {
            Text("They will stop receiving rental SMS. Past SMS logs stay on device.")
        }
    }

    private func save(_ draft: StaffDraft) {
        let phone = StaffConfig.normalize(draft.phone)
        let emails = StaffConfig.parseEmails(draft.emails)
        if let existing = staff.first(where: { $0.staffID == draft.id }) {
            existing.displayName = draft.name.trimmingCharacters(in: .whitespacesAndNewlines)
            existing.phoneE164 = phone
            existing.emails = emails
            existing.isActive = draft.isActive
            existing.updatedAt = .now
        } else {
            modelContext.insert(
                StaffMember(
                    staffID: draft.id,
                    displayName: draft.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    phoneE164: phone,
                    emails: emails,
                    isActive: draft.isActive
                )
            )
        }
        try? modelContext.save()
        Task { await staffServices.pushLocalRoster(modelContext) }
    }
}

struct StaffDraft: Identifiable, Equatable {
    var id: UUID
    var name: String
    var phone: String
    var emails: String
    var isActive: Bool
    var isNew: Bool

    init() {
        id = UUID()
        name = ""
        phone = ""
        emails = ""
        isActive = true
        isNew = true
    }

    init(_ person: StaffMember) {
        id = person.staffID
        name = person.displayName
        phone = person.phoneE164
        emails = StaffConfig.joinEmails(person.emails)
        isActive = person.isActive
        isNew = false
    }
}

struct StaffEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: StaffDraft
    var onSave: (StaffDraft) -> Void

    init(draft: StaffDraft, onSave: @escaping (StaffDraft) -> Void) {
        _draft = State(initialValue: draft)
        self.onSave = onSave
    }

    private var canSave: Bool {
        let emails = StaffConfig.parseEmails(draft.emails)
        return !draft.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && StaffConfig.isValidPhone(draft.phone)
            && (draft.emails.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !emails.isEmpty)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Employee") {
                    TextField("Display name", text: $draft.name)
                    TextField("Cell phone", text: $draft.phone)
                        .keyboardType(.phonePad)
                    TextField("Email (comma-separated)", text: $draft.emails)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                    Toggle("Active — receive SMS + email copy", isOn: $draft.isActive)
                }
                .listRowBackground(Brand.card)

                Section {
                    Text("Stored as E.164 (example \(StaffConfig.defaultE164)). Real SMS later goes through TwilioSMSNotifier to every active number.")
                        .font(.footnote)
                        .foregroundStyle(Brand.silver)
                }
                .listRowBackground(Brand.card)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.background)
            .navigationTitle(draft.isNew ? "Add staff" : "Edit staff")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(draft)
                        dismiss()
                    }
                    .disabled(!canSave)
                    .foregroundStyle(canSave ? Brand.orange : Brand.silver)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Brand.orange)
    }
}
