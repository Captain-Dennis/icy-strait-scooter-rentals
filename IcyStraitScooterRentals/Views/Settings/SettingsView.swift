import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppPreferences.enforceSeasonHoursKey) private var enforceSeasonHours = false
    @Environment(StaffServices.self) private var staffServices
    @Query(sort: \StaffSMSLog.sentAt, order: .reverse) private var smsLog: [StaffSMSLog]
    @Query(sort: \StaffMember.displayName) private var staff: [StaffMember]
    @State private var pipeURL = SharedPipeConfig.httpBaseURL.absoluteString

    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        StaffRosterView()
                    } label: {
                        HStack {
                            Label("Staff roster", systemImage: "person.2.fill")
                            Spacer()
                            Text("\(staff.filter { $0.isActive }.count) active")
                                .foregroundStyle(Brand.silver)
                        }
                    }
                    .listRowBackground(Brand.card)
                } footer: {
                    Text("Starter: Front desk / Dennis · \(StaffConfig.defaultDisplay) · maddasstoner@yahoo.com, f.vhappytimes@gmail.com. Only active members get SMS/email copy.")
                        .foregroundStyle(Brand.silver)
                }

                Section("Demo") {
                    Toggle("Enforce 2027 season hours", isOn: $enforceSeasonHours)
                    Button("Replay onboarding") {
                        AppPreferences.onboardingCompleted = false
                        dismiss()
                    }
                }
                .listRowBackground(Brand.card)

                Section("Providers") {
                    labeled("POS", "MockPOSProvider")
                    labeled("Staff SMS/email", "MockStaffNotifier")
                    labeled("Twilio stub", "TwilioSMSNotifier (no keys)")
                    labeled("Crew pipe", "HTTPLotStore (CloudKit compiled, not entitled here)")
                }
                .listRowBackground(Brand.card)

                Section("Crew event pipe") {
                    TextField("Shared event URL", text: $pipeURL)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    Button("Save pipe URL") {
                        SharedPipeConfig.setHTTPBaseURL(pipeURL)
                        Task { await staffServices.httpStore.setBaseURL(SharedPipeConfig.httpBaseURL) }
                    }
                    .foregroundStyle(Brand.orange)
                    if let status = staffServices.lastPipeStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundStyle(Brand.silver)
                    }
                    Text("Customer checkout/return POST to this URL so the Crew phone can see the same per-unit list. Default is the in-repo tiny server at \(SharedPipeConfig.defaultHTTPURLString). CloudKit is implemented but not entitled on this TestFlight app.")
                        .font(.footnote)
                        .foregroundStyle(Brand.silver)
                }
                .listRowBackground(Brand.card)

                Section {
                    NavigationLink {
                        FleetQRStickersView()
                    } label: {
                        Label("Fleet QR stickers", systemImage: "qrcode")
                    }
                    .listRowBackground(Brand.card)
                } footer: {
                    Text("Hard rule: one unique QR per unit (IS-101–IS-106). Only Glacier is rentable today. Never print a shared “any scooter” sticker.")
                        .foregroundStyle(Brand.silver)
                }

                Section("App install link (placeholders)") {
                    labeled("Smart host", AppLinkConfig.smartLinkHost)
                    labeled("Apple ID", AppLinkConfig.appStoreAppleIDPlaceholder)
                    labeled("Store URL", AppLinkConfig.appStoreURLPlaceholder)
                    labeled("Associated domain", AppLinkConfig.associatedDomain)
                }
                .listRowBackground(Brand.card)

                Section("Recent mock SMS") {
                    if smsLog.isEmpty {
                        Text("None yet. Complete a checkout or check-in.")
                            .foregroundStyle(Brand.silver)
                    }
                    ForEach(smsLog.prefix(12), id: \.logID) { row in
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(row.staffName) · \(row.displayPhone)")
                                .font(BrandFont.headline(14))
                                .foregroundStyle(.white)
                            Text(row.body)
                                .font(.caption)
                                .foregroundStyle(Brand.silver)
                            Text(row.sentAt.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(Brand.orange)
                        }
                    }
                }
                .listRowBackground(Brand.card)
            }
            .scrollContentBackground(.hidden)
            .background(Brand.background)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Brand.orange)
                }
            }
        }
        .preferredColorScheme(.dark)
        .tint(Brand.orange)
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.white)
            Spacer()
            Text(value).foregroundStyle(Brand.silver).font(.caption)
        }
    }
}

struct FleetQRStickersView: View {
    var body: some View {
        List {
            Section {
                Text("Print six unique stickers — never a shared fleet QR. Only affix and rent IS-101 Glacier today. IS-102–106 stay in the catalog for the 2027 season; they are not on the lot and are not inbound this month.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.silver)
                    .listRowBackground(Brand.card)
            }

            ForEach(FleetCatalog.stickerPayloads) { sticker in
                Section(sticker.id) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top, spacing: 16) {
                            QRCodeView(payload: sticker.httpsPayload, dimension: 140)
                            VStack(alignment: .leading, spacing: 6) {
                                Text(sticker.name)
                                    .font(BrandFont.title(22))
                                    .foregroundStyle(.white)
                                Text(sticker.dock)
                                    .font(.caption)
                                    .foregroundStyle(Brand.silver)
                                Text("Sticker belongs only to \(sticker.id)")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Brand.orange)
                            }
                        }
                        payloadRow("https (print this)", sticker.httpsPayload)
                        payloadRow("Demo scheme", sticker.customSchemePayload)
                        payloadRow("Bare ID", sticker.barePayload)
                    }
                    .padding(.vertical, 6)
                    .listRowBackground(Brand.card)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.background)
        .navigationTitle("Fleet QR stickers")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func payloadRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.orange)
            Text(value)
                .font(.caption.monospaced())
                .foregroundStyle(.white)
                .textSelection(.enabled)
        }
    }
}
