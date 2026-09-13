import SwiftUI

struct AlertInboxView: View {
    @Environment(CrewLotMonitor.self) private var lot

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("SMS, email, and push copy for each unit. Mock dispatches are visible here. Live APNs and Twilio are not claimed.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                    if lot.snapshot.alerts.isEmpty {
                        EmptyHeroState(
                            title: "No crew alerts yet",
                            message: "When a renter checks out or returns a specific scooter, the exact-unit alert text lands here."
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusPill(text: alert.channel.rawValue.uppercased(), tint: Brand.orange)
                StatusPill(
                    text: alert.liveDelivery ? "Live" : "Mock",
                    tint: alert.liveDelivery ? Brand.ok : Brand.silver
                )
                Spacer()
                Text(alert.unitLabel)
                    .font(BrandFont.headline(14))
                    .foregroundStyle(Brand.orange)
            }
            Text(alert.title)
                .font(BrandFont.headline(18))
                .foregroundStyle(.white)
            Text(alert.body)
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
            Text("\(alert.recipientName) · \(alert.recipientAddress)")
                .font(.caption)
                .foregroundStyle(.white)
            Text("\(alert.providerName) · \(CrewAlertCopy.alaskaTime(alert.sentAt))")
                .font(.caption2)
                .foregroundStyle(Brand.orange)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Brand.cardStroke)
        )
    }
}
