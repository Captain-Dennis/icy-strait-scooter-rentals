import SwiftUI

struct CrewBoardView: View {
    @Environment(CrewLotMonitor.self) private var lot
    @Environment(CrewSession.self) private var session

    private var liveRows: [UnitBoardRow] { lot.rows.filter { !$0.isNextSeason } }
    private var seasonRows: [UnitBoardRow] { lot.rows.filter(\.isNextSeason) }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    header
                    if let error = lot.lastError {
                        pipeBanner(error)
                    }
                    if !liveRows.isEmpty {
                        SectionLabel(title: "On the dock", trailing: "\(lot.outCount) out")
                        ForEach(liveRows) { row in
                            unitLink(row)
                        }
                    }
                    if !seasonRows.isEmpty {
                        SectionLabel(title: "2027 season", trailing: "Not rentable")
                            .padding(.top, 6)
                        ForEach(seasonRows) { row in
                            unitLink(row)
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)
                .padding(.bottom, 20)
            }
            .icyScreenBackground()
            .navigationTitle("Lot")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await lot.refresh(announceNew: true) }
                    } label: {
                        Image(systemName: lot.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    }
                    .foregroundStyle(Brand.orange)
                    .accessibilityLabel("Refresh lot")
                }
            }
        }
    }

    private func unitLink(_ row: UnitBoardRow) -> some View {
        NavigationLink {
            UnitHistoryView(row: row)
        } label: {
            UnitBoardCard(row: row)
        }
        .buttonStyle(.plain)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HOONAH LOT")
                        .font(BrandFont.eyebrow())
                        .tracking(1.6)
                        .foregroundStyle(Brand.orange)
                    Text(session.operatorName)
                        .font(.caption)
                        .foregroundStyle(Brand.tide)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 0) {
                    Text("\(lot.outCount)")
                        .font(BrandFont.mono(36))
                        .foregroundStyle(lot.outCount == 0 ? Brand.ok : Brand.orange)
                    Text("out · \(lot.onLotCount) on dock")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Brand.silver)
                }
            }
            Text("Live unit is IS-101 Glacier. IS-102–106 stay off the lot until 2027.")
                .font(.caption)
                .foregroundStyle(Brand.silver)
            if let refreshed = lot.lastRefreshed {
                Text("Updated \(CrewAlertCopy.alaskaTime(refreshed))")
                    .font(.caption2)
                    .foregroundStyle(Brand.tide)
            }
        }
        .padding(.bottom, 2)
    }

    private func pipeBanner(_ error: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("LIVE PIPE DOWN")
                .font(BrandFont.eyebrow(10))
                .tracking(1.2)
                .foregroundStyle(Brand.danger)
            Text(error)
                .font(.caption)
                .foregroundStyle(Brand.silver)
                .lineLimit(3)
            Text("Start the rental-events server, then set the URL in Roster → Pipe.")
                .font(.caption2)
                .foregroundStyle(Brand.tide)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.danger.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Brand.danger.opacity(0.35))
        )
    }
}

struct UnitBoardCard: View {
    var row: UnitBoardRow
    var showsPhoto: Bool = true

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            if showsPhoto {
                UnitPhoto(
                    scooterID: row.scooterID,
                    unitName: row.scooterName,
                    cornerRadius: 8,
                    thumb: 52,
                    photoAssetName: row.photoAssetName
                )
                .opacity(row.isNextSeason ? 0.55 : 1)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text(row.scooterID)
                        .font(BrandFont.mono(12))
                        .foregroundStyle(row.isNextSeason ? Brand.tide : Brand.orange)
                    Text(row.scooterName)
                        .font(BrandFont.headline(16))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer(minLength: 6)
                    StatusPill(text: row.statusTitle, tint: statusTint)
                        .fixedSize()
                }
                Text(detailLine)
                    .font(.caption)
                    .foregroundStyle(detailTint)
                    .lineLimit(1)
                Text(row.dock)
                    .font(.caption2)
                    .foregroundStyle(Brand.tide)
                    .lineLimit(1)
            }

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Brand.silver.opacity(0.7))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .brandCard(radius: 14, stroke: row.isOut ? Brand.orange.opacity(0.45) : Brand.cardStroke)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(row.unitLabel), \(row.statusTitle), \(detailLine)")
    }

    private var statusTint: Color {
        if row.isNextSeason { return Brand.silver }
        return row.isOut ? Brand.orange : Brand.ok
    }

    private var detailTint: Color {
        if row.isOut { return Brand.orangeSoft }
        if row.isNextSeason { return Brand.silver }
        return Brand.ok
    }

    private var detailLine: String {
        if row.isNextSeason {
            return "Next season · not on the lot"
        }
        if row.isOut {
            if let started = row.startedAt {
                return "\(row.renterLabel) · \(CrewAlertCopy.alaskaTime(started))"
            }
            return row.renterLabel
        }
        if let ended = row.endedAt {
            return "Back \(CrewAlertCopy.alaskaTime(ended))"
        }
        return "Free on the lot"
    }
}
