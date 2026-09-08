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
                VStack(alignment: .leading, spacing: 14) {
                    Text("You’re renting \(scooter.scooterID)")
                        .font(BrandFont.title(28))
                        .foregroundStyle(Brand.orange)
                        .accessibilityAddTraits(.isHeader)
                    Text(scooter.scooterID)
                        .font(BrandFont.title(44))
                        .foregroundStyle(.white)
                    Text(scooter.name)
                        .font(BrandFont.title(26))
                        .foregroundStyle(.white)
                    FleetHeroImage(height: 160)
                    Text("This QR belongs only to \(scooter.scooterID). Wrong unit? Cancel and scan the sticker on that scooter.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("This hour · \(remainingThisHour)/6 open · rent now")
                        .font(BrandFont.headline(16))
                        .foregroundStyle(remainingThisHour == 0 ? Brand.danger : Brand.ok)
                    Text("First hour \(MoneyFormat.string(BillingCalculator.firstHour)). Then \(MoneyFormat.string(BillingCalculator.additionalHalfHour)) each extra 30 minutes.")
                        .font(.subheadline)
                        .foregroundStyle(Brand.silver)
                }
                .padding(20)
            }
            PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                step = .agreements
            }
            .padding(16)
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
