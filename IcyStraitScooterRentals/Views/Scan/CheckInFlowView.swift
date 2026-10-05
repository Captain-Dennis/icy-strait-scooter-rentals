import SwiftData
import SwiftUI
import UIKit

struct CheckInFlowView: View {
    var payload: QRPayload
    var onFinished: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(POSEnvironment.self) private var pos
    @Environment(StaffServices.self) private var staff
    @Query private var rentals: [Rental]

    @State private var photos: [ReturnPhotoCapture] = []
    @State private var busy = false
    @State private var errorMessage: String?
    @State private var completed: Rental?

    private var rental: Rental? {
        try? RentalOperations.rental(matching: payload, in: rentals)
    }

    var body: some View {
        NavigationStack {
            Group {
                if let completed {
                    doneView(completed)
                } else if rental == nil {
                    missing
                } else if let rental, !rental.isActive {
                    alreadyDone(rental)
                } else {
                    ReturnPhotoWizardView(photos: $photos, onDone: finalize, busy: busy)
                }
            }
            .background(Brand.background.ignoresSafeArea())
            .navigationTitle("Bring it back")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Brand.orange)
                }
            }
            .alert("Check-in paused", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var missing: some View {
        EmptyHeroState(
            title: "That return code didn't match",
            message: "Open My rentals and tap the return email, or scan the QR from that message.",
            kicker: "Check-in"
        )
        .padding(20)
    }

    private func alreadyDone(_ rental: Rental) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            UnitPhoto(
                scooterID: rental.scooterID,
                unitName: rental.scooterName,
                height: 160,
                photoAssetName: FleetCatalog.photoAssetName(for: rental.scooterID)
            )
            StatusPill(text: "Already back", tint: Brand.ok)
            Text(rental.scooterName)
                .font(BrandFont.display(32))
                .foregroundStyle(.white)
            Text(rental.scooterID)
                .font(BrandFont.mono(15))
                .foregroundStyle(Brand.orange)
            if let amount = rental.capturedAmount {
                MoneyText(amount: amount)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func doneView(_ rental: Rental) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            UnitPhoto(
                scooterID: rental.scooterID,
                unitName: rental.scooterName,
                height: 168,
                photoAssetName: FleetCatalog.photoAssetName(for: rental.scooterID)
            )
            Text("CHECKED IN")
                .font(BrandFont.eyebrow())
                .tracking(1.5)
                .foregroundStyle(Brand.ok)
            Text("Meter stopped")
                .font(BrandFont.display(34))
                .foregroundStyle(.white)
            Text("\(rental.scooterName) is back on the lot.")
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
            if let amount = rental.capturedAmount {
                VStack(alignment: .leading, spacing: 4) {
                    Text("FINAL CHARGE")
                        .font(BrandFont.eyebrow(10))
                        .tracking(1.2)
                        .foregroundStyle(Brand.tide)
                    MoneyText(amount: amount)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .brandCard(radius: 16)
            }
            Spacer()
            PrimaryButton(title: "Done", systemImage: "checkmark") {
                onFinished()
                dismiss()
            }
        }
        .padding(20)
    }

    private func finalize() {
        busy = true
        Task {
            do {
                let result = try await RentalOperations.checkIn(
                    payload: payload,
                    rentals: rentals,
                    photos: photos,
                    now: .now,
                    pos: pos.provider,
                    context: modelContext
                )
                await staff.notifyCheckIn(rental: result, context: modelContext)
                completed = result
                busy = false
            } catch {
                busy = false
                errorMessage = error.localizedDescription
            }
        }
    }
}
