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

    private var onTheDock: [Scooter] {
        scooters.filter { FleetCatalog.isRentableNow($0.scooterID) }
    }

    private var nextSeason: [Scooter] {
        scooters.filter { !FleetCatalog.isRentableNow($0.scooterID) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    header
                    if let activeRental {
                        ActiveRentalCard(rental: activeRental) {
                            checkInPayload = activeRental.returnPayload
                        }
                    }
                    scannerBlock
                    manualBlock
                    fleetSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .icyScreenBackground()
            .navigationTitle("Scan")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Brand.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(item: checkoutSheetItem) { item in
                if let scooter = scooters.first(where: { $0.scooterID == item.id }) {
                    CheckoutFlowView(scooter: scooter, remainingThisHour: remainingThisHour) {}
                } else {
                    EmptyHeroState(
                        title: "That unit is not on the lot",
                        message: "Scan Glacier’s stem sticker, or type IS-101.",
                        kicker: "Unknown code"
                    )
                    .padding(20)
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
        VStack(alignment: .leading, spacing: 14) {
            PlaceLockup(
                title: "Rent this hour",
                subtitle: "Scan the sticker on that scooter’s stem. Live on the dock today: IS-101 Glacier. IS-102–106 return for the 2027 season."
            )
            HStack(alignment: .center, spacing: 16) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("THIS HOUR")
                        .font(BrandFont.eyebrow(10))
                        .tracking(1.2)
                        .foregroundStyle(Brand.tide)
                    Text("\(remainingThisHour)/\(FleetCatalog.liveCapacityPerHour)")
                        .font(BrandFont.mono(28))
                        .foregroundStyle(remainingThisHour == 0 ? Brand.danger : .white)
                    Text(remainingThisHour == 0 ? "Glacier is out" : "Glacier is open")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(remainingThisHour == 0 ? Brand.danger : Brand.ok)
                }
                CapacityMeter(remaining: remainingThisHour, capacity: FleetCatalog.liveCapacityPerHour)
            }
            .padding(14)
            .brandCard(radius: 16)
        }
    }

    @ViewBuilder
    private var scannerBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Stem QR", trailing: "One code per unit")
            QRScannerPane { raw in
                handleRaw(raw)
            }
        }
    }

    private var manualBlock: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionLabel(title: "Know the unit")
            HStack(spacing: 8) {
                TextField("IS-101", text: $manualID)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .font(BrandFont.mono(18))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Brand.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                Button("Go") { handleRaw(manualID) }
                    .font(BrandFont.headline(16))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .background(Brand.orange, in: Capsule())
            }
            Text("Glacier’s sticker is IS-101. A demo link or the bare unit ID also works.")
                .font(.caption)
                .foregroundStyle(Brand.tide)
        }
    }

    private var fleetSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !onTheDock.isEmpty {
                SectionLabel(title: "On the dock", trailing: "Rent now")
                ForEach(onTheDock, id: \.scooterID) { scooter in
                    dockCard(scooter)
                }
            }
            if !nextSeason.isEmpty {
                SectionLabel(title: "2027 season", trailing: "Not on the lot")
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(nextSeason, id: \.scooterID) { scooter in
                        seasonCard(scooter)
                    }
                }
            }
        }
    }

    private func dockCard(_ scooter: Scooter) -> some View {
        Button {
            checkoutID = scooter.scooterID
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                UnitPhoto(scooterID: scooter.scooterID, unitName: scooter.name, height: 168, cornerRadius: 14)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(scooter.scooterID)
                            .font(BrandFont.mono(13))
                            .foregroundStyle(Brand.orange)
                        Text(scooter.name)
                            .font(BrandFont.display(28))
                            .foregroundStyle(.white)
                        Text(scooter.dockLabel)
                            .font(.caption)
                            .foregroundStyle(Brand.tide)
                    }
                    Spacer(minLength: 8)
                    Text("Rent")
                        .font(BrandFont.headline(15))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Brand.orange, in: Capsule())
                }
            }
            .padding(12)
            .brandCard(radius: 18, stroke: Brand.orange.opacity(0.35))
        }
        .buttonStyle(.plain)
    }

    private func seasonCard(_ scooter: Scooter) -> some View {
        Button {
            errorMessage = CheckoutError.nextSeasonNotOnLot.localizedDescription
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                UnitPhoto(scooterID: scooter.scooterID, unitName: scooter.name, height: 92, cornerRadius: 10)
                    .opacity(0.88)
                Text(scooter.scooterID)
                    .font(BrandFont.mono(11))
                    .foregroundStyle(Brand.tide)
                Text(scooter.name)
                    .font(BrandFont.headline(16))
                    .foregroundStyle(.white)
                Text("2027 · not on the lot")
                    .font(.caption2)
                    .foregroundStyle(Brand.silver)
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .brandCard(radius: 14)
        }
        .buttonStyle(.plain)
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
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .center, spacing: 12) {
                    UnitPhoto(
                        scooterID: rental.scooterID,
                        unitName: rental.scooterName,
                        cornerRadius: 10,
                        thumb: 64
                    )
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("OUT NOW")
                                .font(BrandFont.eyebrow(10))
                                .tracking(1.3)
                                .foregroundStyle(Brand.orange)
                            Spacer(minLength: 6)
                            Text(rental.scooterID)
                                .font(BrandFont.mono(12))
                                .foregroundStyle(Brand.tide)
                        }
                        Text(rental.scooterName)
                            .font(BrandFont.display(28))
                            .foregroundStyle(.white)
                    }
                }
                HStack(alignment: .firstTextBaseline) {
                    Text(elapsed(rental.elapsed(at: context.date)))
                        .font(BrandFont.mono(28))
                        .foregroundStyle(.white)
                    Spacer()
                    MoneyText(amount: rental.quotedCharge(at: context.date), size: 26)
                }
                Text("Meter running from the moment you started.")
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
                PrimaryButton(title: "Check in with return QR", systemImage: "qrcode.viewfinder", action: onReturn)
            }
            .padding(16)
            .brandCard(radius: 20, stroke: Brand.orange.opacity(0.55))
        }
    }

    private func elapsed(_ interval: TimeInterval) -> String {
        let total = Int(interval)
        return String(format: "%d:%02d:%02d", total / 3600, (total % 3600) / 60, total % 60)
    }
}
