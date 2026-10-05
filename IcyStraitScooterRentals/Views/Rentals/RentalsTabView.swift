import SwiftData
import SwiftUI

struct RentalsTabView: View {
    @Query(sort: \Rental.startedAt, order: .reverse) private var rentals: [Rental]
    @State private var checkInPayload: QRPayload?
    @State private var showSettings = false

    private var live: [Rental] { rentals.filter { !$0.isSeededSample } }
    private var active: [Rental] { live.filter { $0.isActive } }
    private var past: [Rental] { live.filter { !$0.isActive } }
    private var samples: [Rental] { rentals.filter(\.isSeededSample).prefix(12).map { $0 } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if active.isEmpty && past.isEmpty {
                        EmptyHeroState(
                            title: "The dock is quiet",
                            message: "Scan Glacier’s stem QR to start. The running charge and return code land here.",
                            kicker: "Hoonah · Icy Strait Point"
                        )
                    } else {
                        PlaceLockup(
                            title: "Your rides",
                            subtitle: "Active meters stay at the top. Tap a ride for the return QR."
                        )
                    }
                    if !active.isEmpty {
                        sectionTitle("Active")
                        ForEach(active, id: \.rentalID) { rental in
                            NavigationLink {
                                RentalDetailView(rental: rental) { checkInPayload = $0 }
                            } label: {
                                rentalRow(rental)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if !past.isEmpty {
                        sectionTitle("Checked in")
                        ForEach(past, id: \.rentalID) { rental in
                            NavigationLink {
                                RentalDetailView(rental: rental) { checkInPayload = $0 }
                            } label: {
                                rentalRow(rental)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    if !samples.isEmpty {
                        sectionTitle("2027 season samples")
                        ForEach(samples, id: \.rentalID) { rental in
                            NavigationLink {
                                RentalDetailView(rental: rental) { _ in }
                            } label: {
                                rentalRow(rental)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(20)
            }
            .icyScreenBackground()
            .navigationTitle("My rentals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .foregroundStyle(Brand.orange)
                    .accessibilityLabel("Settings and staff")
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sheet(item: $checkInPayload) { payload in
                CheckInFlowView(payload: payload) {}
            }
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        SectionLabel(title: text)
    }

    private func rentalRow(_ rental: Rental) -> some View {
        HStack(alignment: .center, spacing: 12) {
            UnitPhoto(
                scooterID: rental.scooterID,
                unitName: rental.scooterName,
                cornerRadius: 10,
                thumb: 56,
                photoAssetName: FleetCatalog.photoAssetName(for: rental.scooterID)
            )
            VStack(alignment: .leading, spacing: 3) {
                Text(rental.scooterName)
                    .font(BrandFont.display(20))
                    .foregroundStyle(.white)
                Text("\(rental.scooterID) · \(rental.isActive ? "Active" : (rental.isSeededSample ? "2027 sample" : "Returned"))")
                    .font(.caption)
                    .foregroundStyle(Brand.tide)
                Text(rental.startedAt, format: Date.FormatStyle().month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
            }
            Spacer(minLength: 8)
            Text(MoneyFormat.string(rental.quotedCharge(at: rental.endedAt ?? .now)))
                .font(BrandFont.headline(15))
                .foregroundStyle(Brand.orange)
        }
        .padding(12)
        .brandCard(radius: 16, stroke: rental.isActive ? Brand.orange.opacity(0.4) : Brand.cardStroke)
    }
}
