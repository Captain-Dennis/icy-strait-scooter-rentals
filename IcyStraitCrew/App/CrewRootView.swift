import SwiftData
import SwiftUI

struct CrewRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Environment(StaffServices.self) private var staff
    @Environment(CrewSession.self) private var session
    @Environment(CrewLotMonitor.self) private var lot
    @State private var tab: CrewTab = .board

    var body: some View {
        Group {
            if session.isUnlocked {
                signedIn
            } else {
                CrewSignInView()
            }
        }
        .icyScreenBackground()
        .task {
            try? StaffSeeder.seedIfNeeded(context: modelContext)
            await lot.requestNotificationPermission()
            await lot.refresh(announceNew: false)
            await staff.pushLocalRoster(modelContext)
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await lot.refresh(announceNew: true) }
            }
        }
    }

    private var signedIn: some View {
        TabView(selection: $tab) {
            CrewBoardView()
                .tabItem { Label("Lot", systemImage: "square.grid.2x2.fill") }
                .tag(CrewTab.board)

            AlertInboxView()
                .tabItem { Label("Alerts", systemImage: "bell.fill") }
                .tag(CrewTab.alerts)

            NavigationStack {
                CrewRosterHome()
            }
            .tabItem { Label("Roster", systemImage: "person.2.fill") }
            .tag(CrewTab.roster)
        }
        .task(id: session.isUnlocked) {
            while !Task.isCancelled, session.isUnlocked {
                await lot.refresh(announceNew: true)
                try? await Task.sleep(nanoseconds: 8_000_000_000)
            }
        }
    }
}

enum CrewTab: Hashable {
    case board
    case alerts
    case roster
}
