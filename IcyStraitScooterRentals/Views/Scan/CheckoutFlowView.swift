import SwiftData
import SwiftUI

struct CheckoutFlowView: View {
    var scooter: Scooter
    var remainingThisHour: Int
    var onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(POSEnvironment.self) private var pos
    @Environment(StaffServices.self) private var staff
    @Query private var rentals: [Rental]

    @State private var step: Step = .unit
    @State private var accepted: [AgreementAcceptanceRecord] = []
    @State private var busy = false
    @State private var errorMessage: String?

    enum Step: Int {
        case unit
        case agreements
    }

    private var acceptedIDs: Set<AgreementSectionID> {
        Set(accepted.map(\.sectionID))
    }

    private var canStart: Bool {
        AgreementGate.canStartRental(accepted: acceptedIDs)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if step == .unit {
                    unitStep
                } else {
                    AgreementWizardView(
                        accepted: $accepted,
                        requireLinearAccept: true,
                        startTitle: "Start rental · \(MoneyFormat.string(BillingCalculator.firstHour))",
                        startBusy: busy
                    ) {
                        start()
                    }
                }
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationTitle(step == .unit ? "Rent now" : "Quick agrees")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Brand.orange)
                }
                if step == .agreements {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Back") { step = .unit }
                            .foregroundStyle(Brand.silver)
                    }
                }
            }
            .alert("Can't start yet", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
        .interactiveDismissDisabled()
    }

    private var unitStep: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("CONFIRM THE UNIT")
                            .font(BrandFont.eyebrow())
                            .tracking(1.5)
                            .foregroundStyle(Brand.orange)
                        Text("You’re renting \(scooter.scooterID)")
                            .font(BrandFont.title(22))
                            .foregroundStyle(.white)
                            .accessibilityAddTraits(.isHeader)
                        Text(scooter.name)
                            .font(BrandFont.display(40))
                            .foregroundStyle(.white)
                    }
                    UnitPhoto(
                        scooterID: scooter.scooterID,
                        unitName: scooter.name,
                        height: 188,
                        photoAssetName: scooter.resolvedPhotoAssetName
                    )
                    VStack(alignment: .leading, spacing: 8) {
                        FactChip(text: scooter.dockLabel, symbol: "mappin.and.ellipse")
                        HStack(spacing: 8) {
                            FactChip(text: "\(scooter.batteryPercent)% battery", symbol: "bolt.fill")
                            FactChip(text: "~\(scooter.estimatedRangeMiles) mi", symbol: "arrow.left.and.right")
                        }
                    }
                    Text("This sticker belongs only to \(scooter.scooterID). Wrong scooter? Cancel and scan the one in front of you.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                        .fixedSize(horizontal: false, vertical: true)
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline) {
                            Text("First hour")
                                .font(.subheadline)
                                .foregroundStyle(Brand.tide)
                            Spacer()
                            Text(MoneyFormat.string(BillingCalculator.firstHour))
                                .font(BrandFont.mono(22))
                                .foregroundStyle(.white)
                        }
                        HStack {
                            Text("Each extra 30 minutes")
                                .font(.caption)
                                .foregroundStyle(Brand.silver)
                            Spacer()
                            Text(MoneyFormat.string(BillingCalculator.additionalHalfHour))
                                .font(BrandFont.headline(15))
                                .foregroundStyle(.white)
                        }
                        Text("This hour · \(remainingThisHour)/\(FleetCatalog.liveCapacityPerHour) open · Glacier only")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(remainingThisHour == 0 ? Brand.danger : Brand.ok)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .brandCard(radius: 16)
                }
                .padding(20)
            }
            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                step = .agreements
            }
            .padding(16)
            .background(Brand.charcoal.ignoresSafeArea(edges: .bottom))
        }
    }

    private func start() {
        guard canStart else {
            errorMessage = CheckoutError.agreementsIncomplete.localizedDescription
            return
        }
        busy = true
        Task {
            do {
                let rental = try await RentalOperations.startRental(
                    scooter: scooter,
                    rentals: rentals,
                    accepted: accepted,
                    now: .now,
                    pos: pos.provider,
                    context: modelContext,
                    enforceSeasonHours: AppPreferences.enforceSeasonHours
                )
                await staff.notifyCheckout(rental: rental, context: modelContext)
                busy = false
                onFinished()
                dismiss()
            } catch {
                busy = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
