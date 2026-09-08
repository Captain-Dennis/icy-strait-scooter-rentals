import SwiftData
import SwiftUI

struct RootView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(StaffServices.self) private var staff
    @Environment(SessionRouter.self) private var router
    @AppStorage(AppPreferences.onboardingCompletedKey) private var onboardingCompleted = false

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: tabBinding) {
                ScanTabView()
                    .tabItem {
                        Label("Scan", systemImage: "qrcode.viewfinder")
                    }
                    .tag(AppTab.scan)

                CalendarTabView()
                    .tabItem {
                        Label("Calendar", systemImage: "calendar")
                    }
                    .tag(AppTab.calendar)

                RentalsTabView()
                    .tabItem {
                        Label("My rentals", systemImage: "list.bullet.rectangle")
                    }
                    .tag(AppTab.rentals)
            }

            if let banner = staff.lastBanner {
                smsBanner(banner)
            }
        }
        .task {
            try? FleetSeeder.seedIfNeeded(context: modelContext)
        }
        .fullScreenCover(isPresented: onboardingBinding) {
            OnboardingView {
                onboardingCompleted = true
            }
        }
    }

    private var tabBinding: Binding<AppTab> {
        Binding(
            get: { router.selectedTab },
            set: { router.selectedTab = $0 }
        )
    }

    private var onboardingBinding: Binding<Bool> {
        Binding(
            get: { !onboardingCompleted },
            set: { if !$0 { onboardingCompleted = true } }
        )
    }

    private func smsBanner(_ text: String) -> some View {
        Button {
            staff.lastBanner = nil
        } label: {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "message.fill")
                Text(text)
                    .multilineTextAlignment(.leading)
                Spacer()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.black)
            .padding(12)
            .background(Brand.orange, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.top, 8)
        }
        .buttonStyle(.plain)
        .task(id: text) {
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            if staff.lastBanner == text {
                staff.lastBanner = nil
            }
        }
    }
}
