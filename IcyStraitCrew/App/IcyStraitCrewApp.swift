import SwiftData
import SwiftUI
import UserNotifications

@main
struct IcyStraitCrewApp: App {
    @State private var staff = StaffServices()
    @State private var session = CrewSession()
    @State private var lot = CrewLotMonitor()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            StaffMember.self,
            StaffSMSLog.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Could not create Crew ModelContainer: \(error)")
        }
    }()

    init() {
        UNUserNotificationCenter.current().delegate = CrewNotificationCenter.shared
    }

    var body: some Scene {
        WindowGroup {
            CrewRootView()
                .environment(staff)
                .environment(session)
                .environment(lot)
                .preferredColorScheme(.dark)
                .tint(Brand.orange)
        }
        .modelContainer(sharedModelContainer)
    }
}

final class CrewNotificationCenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = CrewNotificationCenter()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .list]
    }
}
