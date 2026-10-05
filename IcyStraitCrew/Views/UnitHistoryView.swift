import SwiftUI

struct UnitHistoryView: View {
    var row: UnitBoardRow
    @Environment(CrewLotMonitor.self) private var lot

    var body: some View {
        let events = lot.history(for: row.scooterID)
        let alerts = lot.alerts(for: row.scooterID)
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                UnitBoardCard(row: lot.rows.first(where: { $0.scooterID == row.scooterID }) ?? row)

                SectionLabel(title: "History")
                if row.isNextSeason {
                    Text("\(row.unitLabel) is cataloged for the 2027 season. It is not on the lot and is not rentable — not inbound this month.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                } else if events.isEmpty {
                    Text("No live events for \(row.scooterName) yet. A customer checkout on \(row.scooterID) will land here.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                } else {
                    ForEach(events) { event in
                        eventCard(event)
                    }
                }

                SectionLabel(title: "Alert copy")
                if alerts.isEmpty {
                    Text("No SMS or push copy for this unit yet.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                } else {
                    ForEach(alerts) { alert in
                        AlertCopyCard(alert: alert)
                    }
                }
            }
            .padding(16)
        }
        .icyScreenBackground()
        .navigationTitle(row.unitLabel)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func eventCard(_ event: RentalLifecycleEvent) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(
                text: event.kind == .checkout ? "Checkout" : "Return",
                tint: event.kind == .checkout ? Brand.orange : Brand.ok
            )
            Text(event.unitLabel)
                .font(BrandFont.headline(18))
                .foregroundStyle(.white)
            Text("Renter  \(event.renterLabel)")
                .foregroundStyle(.white)
            Text(CrewAlertCopy.alaskaTime(event.occurredAt))
                .foregroundStyle(Brand.orange)
            Text("Rental \(String(event.rentalID.uuidString.prefix(8)))")
                .font(.caption.monospaced())
                .foregroundStyle(Brand.silver)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .brandCard(radius: 14)
    }
}
