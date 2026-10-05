import SwiftUI

struct AlertInboxView: View {
    @Environment(CrewLotMonitor.self) private var lot

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    PlaceLockup(
                        kicker: "Desk copy",
                        title: "Alerts",
                        subtitle: "SMS, email, and push text for a specific unit. Mock dispatches show here. Live APNs and Twilio are not claimed."
                    )
                    if lot.snapshot.alerts.isEmpty {
                        EmptyHeroState(
                            title: "Inbox is clear",
                            message: "A checkout or return on a named unit — Glacier today — drops the exact alert text here.",
                            kicker: "No crew alerts"
                        )
                    }
                    ForEach(lot.alerts(for: nil)) { alert in
                        AlertCopyCard(alert: alert)
                    }
                }
                .padding(16)
            }
            .icyScreenBackground()
            .navigationTitle("Alerts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await lot.refresh(announceNew: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .foregroundStyle(Brand.orange)
                }
            }
        }
    }
}

struct AlertCopyCard: View {
    var alert: StaffAlertRecord

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            UnitPhoto(
                scooterID: alert.scooterID,
                unitName: alert.scooterName,
                cornerRadius: 8,
                thumb: 44
            )
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    StatusPill(text: alert.channel.rawValue.uppercased(), tint: Brand.orange)
                    StatusPill(
                        text: alert.liveDelivery ? "Live" : "Mock",
                        tint: alert.liveDelivery ? Brand.ok : Brand.silver
                    )
                    Spacer(minLength: 4)
                    Text(alert.scooterID)
                        .font(BrandFont.mono(11))
                        .foregroundStyle(Brand.orange)
                }
                Text(alert.title)
                    .font(BrandFont.headline(15))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                Text(alert.body)
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
                    .fixedSize(horizontal: false, vertical: true)
                Text("\(alert.recipientName) · \(alert.recipientAddress)")
                    .font(.caption2)
                    .foregroundStyle(Brand.mist)
                Text("\(alert.providerName) · \(CrewAlertCopy.alaskaTime(alert.sentAt))")
                    .font(.caption2)
                    .foregroundStyle(Brand.tide)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCard(radius: 14)
    }
}
