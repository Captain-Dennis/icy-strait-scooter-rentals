import SwiftData
import SwiftUI

@main
struct IcyStraitScooterRentalsApp: App {
    @State private var pos = POSEnvironment()
    @State private var staff = StaffServices()
    @State private var router = SessionRouter()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Scooter.self,
            Rental.self,
            AgreementAcceptance.self,
            ReturnPhoto.self,
            POSLedgerEntry.self,
            StaffMember.self,
            StaffSMSLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(pos)
                .environment(staff)
                .environment(router)
                .preferredColorScheme(.dark)
                .tint(Brand.orange)
                .onOpenURL { url in
                    routeIncoming(url)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    if let url = activity.webpageURL {
                        routeIncoming(url)
                    }
                }
        }
        .modelContainer(sharedModelContainer)
    }

    private func routeIncoming(_ url: URL) {
        if let payload = QRPayload.parse(url: url) {
            router.pendingPayload = payload
            router.selectedTab = .scan
        }
    }
}
