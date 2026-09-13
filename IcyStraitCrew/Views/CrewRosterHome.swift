import SwiftData
import SwiftUI

struct CrewRosterHome: View {
    @Environment(CrewSession.self) private var session
    @Environment(CrewLotMonitor.self) private var lot
    @Environment(StaffServices.self) private var staff
    @State private var pipeURL: String = ""

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

            Section("Event pipe") {
                TextField("Shared event URL", text: $pipeURL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button("Save and refresh") {
                    Task { await lot.setPipeURL(pipeURL) }
                }
                .foregroundStyle(Brand.orange)
                labeled("Store", "HTTPLotStore")
                labeled("CloudKit", "Compiled · not live APNs")
                labeled("Twilio", "Stub · no keys")
                if let error = lot.lastError {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(Brand.danger)
                }
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
