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
                            title: "No live rentals yet",
                            message: "Scan a 4-wheel offroad e-scooter to start. Your active meter and return QR will land here."
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
                        }
                    }
                }
                .padding(20)
            }
            .icyScreenBackground()
            .navigationTitle("My rentals")
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
        Text(text)
            .font(BrandFont.headline(18))
            .foregroundStyle(.white)
    }

    private func rentalRow(_ rental: Rental) -> some View {
        HStack(alignment: .top, spacing: 12) {
            FourWheelScooterMark()
                .frame(width: 56, height: 36)
            VStack(alignment: .leading, spacing: 4) {
                Text(rental.scooterName)
                    .font(BrandFont.headline(16))
                    .foregroundStyle(.white)
                Text("\(rental.scooterID) · \(rental.isActive ? "Active" : "Returned")")
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
                Text(rental.startedAt, format: Date.FormatStyle().month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
            }
            Spacer()
            Text(MoneyFormat.string(rental.quotedCharge(at: rental.endedAt ?? .now)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.orange)
        }
        .padding(14)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
