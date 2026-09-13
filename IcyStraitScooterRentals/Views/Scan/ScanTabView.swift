import SwiftData
import SwiftUI

struct ScanTabView: View {
    @Environment(SessionRouter.self) private var router
    @Query(sort: \Scooter.sortIndex) private var scooters: [Scooter]
    @Query(sort: \Rental.startedAt, order: .reverse) private var rentals: [Rental]

    @State private var manualID = ""
    @State private var checkoutID: String?
    @State private var checkInPayload: QRPayload?
    @State private var errorMessage: String?

    private var liveRentals: [Rental] {
        rentals.filter { !$0.isSeededSample }
    }

    private var activeRental: Rental? {
        liveRentals.first { $0.isActive }
    }

    private var remainingThisHour: Int {
        CapacityCalculator.remaining(
            rentals: RentalOperations.snapshots(from: liveRentals),
            slotStart: currentSlotStart,
            slotEnd: currentSlotStart.addingTimeInterval(3600),
            now: .now,
            capacity: FleetCatalog.liveCapacityPerHour
        )
    }

    private var checkoutSheetItem: Binding<IdentifiedText?> {
        Binding(
            get: { checkoutID.map { IdentifiedText(id: $0) } },
            set: { checkoutID = $0?.id }
        )
    }

    private var currentSlotStart: Date {
        let now = Date.now
        let hour = AppTimeZone.calendar.component(.hour, from: now)
        return Season.slotStart(on: now, hour: hour)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    if let activeRental {
                        ActiveRentalCard(rental: activeRental) {
                            checkInPayload = activeRental.returnPayload
                        }
                    }
                    scannerBlock
                    manualBlock
                    fleetChips
                }
                .padding(20)
            }
            .icyScreenBackground()
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: checkoutSheetItem) { item in
                if let scooter = scooters.first(where: { $0.scooterID == item.id }) {
                    CheckoutFlowView(scooter: scooter, remainingThisHour: remainingThisHour) {}
                } else {
                    Text("That unit is not on the lot.")
                        .foregroundStyle(.white)
                        .icyScreenBackground()
                }
            }
            .sheet(item: $checkInPayload) { payload in
                CheckInFlowView(payload: payload) {}
            }
            .alert("Scan", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .onChange(of: router.pendingPayload) { _, payload in
                if let payload {
                    handle(payload)
                    router.pendingPayload = nil
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            StatusPill(text: "Walk-up · rent this hour")
            Text("Scan that scooter’s own QR. Live today: IS-101 Glacier only. IS-102–106 are 2027 season units — not on the lot, not rentable.")
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
            Text("This hour: \(remainingThisHour)/\(FleetCatalog.liveCapacityPerHour) open · Glacier")
                .font(BrandFont.headline(16))
                .foregroundStyle(remainingThisHour == 0 ? Brand.danger : Brand.ok)
            CapacityMeter(remaining: remainingThisHour, capacity: FleetCatalog.liveCapacityPerHour)
        }
    }

    @ViewBuilder
    private var scannerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Camera")
                .font(BrandFont.headline())
                .foregroundStyle(.white)
            QRScannerPane { raw in
                handleRaw(raw)
            }
        }
    }

    private var manualBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Manual ID")
                .font(BrandFont.headline())
                .foregroundStyle(.white)
            HStack {
                TextField("IS-101", text: $manualID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(Brand.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Go") { handleRaw(manualID) }
                    .font(BrandFont.headline())
                    .foregroundStyle(.black)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Brand.orange, in: Capsule())
            }
            Text("Preferred live sticker: https://icystraitscooters.example/s/IS-101")
                .font(.caption)
                .foregroundStyle(Brand.silver)
            Text("Demo scheme: escooter://scooter/IS-101 · or type IS-101.")
                .font(.caption.monospaced())
                .foregroundStyle(Brand.silver)
        }
    }

    private var fleetChips: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Fleet · unique QR per unit")
                .font(BrandFont.headline())
                .foregroundStyle(.white)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(scooters, id: \.scooterID) { scooter in
                    let rentable = FleetCatalog.isRentableNow(scooter.scooterID)
                    Button {
                        if rentable {
                            checkoutID = scooter.scooterID
                        } else {
                            errorMessage = CheckoutError.nextSeasonNotOnLot.localizedDescription
                        }
                    } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(scooter.scooterID)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(rentable ? Brand.orange : Brand.silver)
                                Spacer()
                                FourWheelScooterMark()
                                    .frame(width: 40, height: 24)
                            }
                            Text(scooter.name)
                                .font(BrandFont.headline(16))
                                .foregroundStyle(.white)
                            Text(rentable ? "On the lot · rent now" : "2027 season · not on the lot")
                                .font(.caption2)
                                .foregroundStyle(rentable ? Brand.ok : Brand.silver)
                        }
                        .padding(12)
                        .background(Brand.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func handleRaw(_ raw: String) {
        if let payload = QRPayload.parse(raw) {
            handle(payload)
        } else {
            errorMessage = "That QR is not a fleet unit. Use a unique sticker for IS-101–IS-106 (https://icystraitscooters.example/s/IS-103), the demo scheme, the unit ID, or a return QR. Shared “any scooter” codes are rejected."
        }
    }

    private func handle(_ payload: QRPayload) {
        switch payload {
        case .scooter(let id):
            guard scooters.contains(where: { $0.scooterID == id }) else {
                errorMessage = CheckoutError.unknownScooter.localizedDescription
                return
            }
            if FleetCatalog.isRentableNow(id) {
                checkoutID = id
            } else {
                errorMessage = CheckoutError.nextSeasonNotOnLot.localizedDescription
            }
        case .returnRental:
            checkInPayload = payload
        }
    }
}

struct IdentifiedText: Identifiable, Hashable {
    var id: String
}

extension QRPayload: Identifiable {
    var id: String { urlString }
}

struct ActiveRentalCard: View {
    var rental: Rental
    var onReturn: () -> Void

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    StatusPill(text: "Active rental")
                    Spacer()
                    Text(rental.scooterID)
                        .font(.caption.monospaced())
                        .foregroundStyle(Brand.silver)
                }
                Text(rental.scooterName)
                    .font(BrandFont.title(22))
                    .foregroundStyle(.white)
                Text(elapsed(rental.elapsed(at: context.date)))
                    .font(BrandFont.mono(26))
                    .foregroundStyle(.white)
                MoneyText(amount: rental.quotedCharge(at: context.date), size: 28)
                PrimaryButton(title: "Check in with return QR", systemImage: "qrcode", action: onReturn)
            }
            .padding(16)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .strokeBorder(Brand.orange.opacity(0.45))
            )
        }
    }

    private func elapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
