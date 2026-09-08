import SwiftData
import SwiftUI
import UIKit

struct RentalDetailView: View {
    var rental: Rental
    var onCheckIn: (QRPayload) -> Void

    @Query private var ledger: [POSLedgerEntry]
    @State private var showAgreements = false

    private var rentalLedger: [POSLedgerEntry] {
        ledger.filter { $0.rentalID == rental.rentalID }.sorted { $0.createdAt < $1.createdAt }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FleetHeroImage(height: 180)
                header
                meter
                photoSection
                agreementButton
                if rental.isActive {
                    PrimaryButton(title: "Open emailed return QR", systemImage: "envelope.open.fill") {
                        onCheckIn(rental.returnPayload)
                    }
                    NavigationLink {
                        MockReturnEmailView(rental: rental, onScan: onCheckIn)
                    } label: {
                        Label("Preview mock return email", systemImage: "tray.full")
                            .font(BrandFont.headline(15))
                            .foregroundStyle(Brand.orange)
                    }
                }
                posSection
            }
            .padding(20)
        }
        .icyScreenBackground()
        .navigationTitle(rental.scooterName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAgreements) {
            NavigationStack {
                AgreementWizardView(
                    accepted: .constant(records),
                    readOnly: true
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { showAgreements = false }
                            .foregroundStyle(Brand.orange)
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
    }

    private var records: [AgreementAcceptanceRecord] {
        rental.acceptances.compactMap { row in
            guard let id = AgreementSectionID(rawValue: row.sectionID) else { return nil }
            return AgreementAcceptanceRecord(sectionID: id, acceptedAt: row.acceptedAt)
        }
        .sorted { $0.sectionID.rawValue < $1.sectionID.rawValue }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(text: rental.isActive ? "Active" : "Checked in", tint: rental.isActive ? Brand.orange : Brand.ok)
            Text(rental.scooterID)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.orange)
            Text("4-wheel offroad e-scooter")
                .foregroundStyle(Brand.silver)
            Text("Rental \(rental.rentalID.uuidString)")
                .font(.caption.monospaced())
                .foregroundStyle(Brand.silver)
                .textSelection(.enabled)
        }
    }

    private var meter: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            let now = rental.endedAt ?? context.date
            VStack(alignment: .leading, spacing: 8) {
                Text(rental.isActive ? "Running charge" : "Final charge")
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
                MoneyText(amount: rental.quotedCharge(at: now))
                Text(elapsed(rental.elapsed(at: now)))
                    .font(BrandFont.mono(18))
                    .foregroundStyle(.white)
                Text("Started \(rental.startedAt.formatted(date: .abbreviated, time: .shortened))")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
                if let ended = rental.endedAt {
                    Text("Returned \(ended.formatted(date: .abbreviated, time: .shortened))")
                        .font(.footnote)
                        .foregroundStyle(Brand.silver)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    @ViewBuilder
    private var photoSection: some View {
        let photos = rental.returnPhotos.sorted { $0.side < $1.side }
        VStack(alignment: .leading, spacing: 10) {
            Text("Return photos")
                .font(BrandFont.headline())
                .foregroundStyle(.white)
            if photos.isEmpty {
                Text(rental.isSeededSample ? "Season sample — no condition photos on file." : "Left and right photos are required at check-in.")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
            } else {
                HStack(spacing: 10) {
                    ForEach(photos, id: \.sideRaw) { photo in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(photo.side.sideLabel)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Brand.silver)
                            if let image = UIImage(data: photo.imageData) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 110)
                                    .clipped()
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            }
                        }
                    }
                }
            }
        }
    }

    private var agreementButton: some View {
        Button {
            showAgreements = true
        } label: {
            HStack {
                Label("Review accepted agreements", systemImage: "doc.text.fill")
                    .foregroundStyle(.white)
                Spacer()
                Text("\(rental.acceptances.count)/5")
                    .foregroundStyle(Brand.orange)
            }
            .padding(14)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

    private var posSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("POS ledger")
                .font(BrandFont.headline())
                .foregroundStyle(.white)
            if rentalLedger.isEmpty {
                Text("No POS rows for this rental.")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
            }
            ForEach(rentalLedger, id: \.entryID) { row in
                HStack {
                    Text(row.kindRaw.capitalized)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(MoneyFormat.string(row.amount))
                        .foregroundStyle(Brand.orange)
                }
                .font(.subheadline)
                Text(row.providerReference)
                    .font(.caption.monospaced())
                    .foregroundStyle(Brand.silver)
            }
        }
    }

    private func elapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
