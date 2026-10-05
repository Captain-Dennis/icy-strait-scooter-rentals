import SwiftData
import SwiftUI

struct CrewRosterHome: View {
    @Environment(CrewSession.self) private var session
    @Environment(CrewLotMonitor.self) private var lot
    @Environment(StaffServices.self) private var staff
    @State private var pipeURL: String = ""
    @State private var preferCloudKit = SharedPipeConfig.preferCloudKit

    var body: some View {
        List {
            Section("On this phone") {
                LabeledContent("Signed in") {
                    Text(session.operatorName)
                        .foregroundStyle(.white)
                }
                Button("Lock crew app") {
                    session.lock()
                }
                .foregroundStyle(Brand.orange)
            }
            .listRowBackground(Brand.card)

            Section {
                TextField("Shared event URL", text: $pipeURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save and refresh") {
                    Task {
                        await lot.setPipeURL(pipeURL)
                        await staff.httpStore.setBaseURL(SharedPipeConfig.httpBaseURL)
                    }
                }
                .foregroundStyle(Brand.orange)
                Toggle("Prefer CloudKit", isOn: $preferCloudKit)
                    .disabled(!SharedPipeConfig.cloudKitEntitled)
                    .onChange(of: preferCloudKit) { _, newValue in
                        SharedPipeConfig.preferCloudKit = newValue
                    }
                labeled("Store", preferCloudKit && SharedPipeConfig.cloudKitEntitled ? "CloudKitLotStore" : lot.storeName)
                labeled("CloudKit", SharedPipeConfig.cloudKitStatusLabel)
                labeled("Twilio", "Stub · no keys")
                if let error = lot.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Brand.danger)
                }
            } header: {
                Text("Event pipe")
            } footer: {
                Text("Entitled builds start with Prefer CloudKit on. HTTP is used when this is off and when CloudKit fails. Container \(SharedPipeConfig.cloudKitContainer).")
                    .foregroundStyle(Brand.silver)
            }
            .listRowBackground(Brand.card)

            Section {
                NavigationLink {
                    StaffRosterView()
                } label: {
                    Label("Edit crew roster", systemImage: "person.2.fill")
                }
                .listRowBackground(Brand.card)
            } footer: {
                Text("Front desk / Dennis · \(StaffConfig.defaultDisplay) · maddasstoner@yahoo.com, f.vhappytimes@gmail.com. Roster also publishes to the shared pipe.")
                    .foregroundStyle(Brand.silver)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Brand.background)
        .navigationTitle("Roster")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Brand.ink, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            if pipeURL.isEmpty {
                pipeURL = lot.pipeURL
            }
        }
    }

    private func labeled(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(.white)
            Spacer()
            Text(value).foregroundStyle(Brand.silver).font(.caption)
        }
    }
}
