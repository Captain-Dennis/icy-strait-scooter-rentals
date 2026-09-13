import SwiftUI

struct CrewBoardView: View {
    @Environment(CrewLotMonitor.self) private var lot
    @Environment(CrewSession.self) private var session

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    if let error = lot.lastError {
                        pipeBanner(error)
                    }
                    ForEach(lot.rows) { row in
                        NavigationLink {
                            UnitHistoryView(row: row)
                        } label: {
                            UnitBoardCard(row: row)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .icyScreenBackground()
            .navigationTitle("Lot board")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await lot.refresh(announceNew: true) }
                    } label: {
                        Image(systemName: lot.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    }
                    .foregroundStyle(Brand.orange)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(session.operatorName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.orange)
            HStack(alignment: .firstTextBaseline) {
                Text("\(lot.outCount) out")
                    .font(BrandFont.title(34))
                    .foregroundStyle(lot.outCount == 0 ? Brand.ok : Brand.orange)
                Text("/ 6 units")
                    .font(BrandFont.headline(18))
                    .foregroundStyle(Brand.silver)
                Spacer()
                FourWheelScooterMark()
                    .frame(width: 72, height: 44)
            }
            Text("Each row is one stem sticker. Never a shared fleet QR.")
                .font(.footnote)
                .foregroundStyle(Brand.silver)
            if let refreshed = lot.lastRefreshed {
                Text("Updated \(CrewAlertCopy.alaskaTime(refreshed))")
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.cardStroke)
        )
    }

    private func pipeBanner(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Live pipe down")
                .font(BrandFont.headline(16))
                .foregroundStyle(Brand.danger)
            Text(error)
                .font(.footnote)
                .foregroundStyle(Brand.silver)
            Text("Start tools/rental-events-server on a host both phones can reach, then set that URL in Roster → Pipe.")
                .font(.footnote)
                .foregroundStyle(Brand.silver)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct UnitBoardCard: View {
    var row: UnitBoardRow

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(row.isOut ? Brand.orange : Brand.ok)
                .frame(width: 8)
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(row.scooterID)
                        .font(BrandFont.title(26))
                        .foregroundStyle(.white)
                    Spacer()
                    StatusPill(text: row.statusTitle, tint: row.isOut ? Brand.orange : Brand.ok)
                }
                Text(row.scooterName)
                    .font(BrandFont.headline(20))
                    .foregroundStyle(.white)
                Text(row.dock)
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
                if row.isOut {
                    Text("Renter  \(row.renterLabel)")
                        .font(BrandFont.headline(16))
                        .foregroundStyle(.white)
                    if let started = row.startedAt {
                        Text("Out since  \(CrewAlertCopy.alaskaTime(started))")
                            .font(.subheadline)
                            .foregroundStyle(Brand.orangeSoft)
                    }
                } else if let ended = row.endedAt {
                    Text("Back  \(CrewAlertCopy.alaskaTime(ended))")
                        .font(.subheadline)
                        .foregroundStyle(Brand.ok)
                    Text(row.renterLabel == "—" ? "No live rental" : "Last renter  \(row.renterLabel)")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                } else {
                    Text("Free on the lot")
                        .font(.subheadline)
                        .foregroundStyle(Brand.ok)
                }
            }
            Image(systemName: "chevron.right")
                .foregroundStyle(Brand.silver)
        }
        .padding(16)
        .frame(minHeight: 118)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(row.isOut ? Brand.orange.opacity(0.45) : Brand.cardStroke)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.unitLabel), \(row.statusTitle)")
    }
}
