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
        VStack(spacing: 12) {
            Text("That return code didn't match")
                .font(BrandFont.title(22))
                .foregroundStyle(.white)
            Text("Open My rentals and tap the return email, or scan the QR we sent you.")
                .foregroundStyle(Brand.silver)
        }
        .padding(24)
    }

    private func alreadyDone(_ rental: Rental) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            StatusPill(text: "Already back", tint: Brand.ok)
            Text("\(rental.scooterName) · \(rental.scooterID)")
                .font(BrandFont.title(22))
                .foregroundStyle(.white)
            if let amount = rental.capturedAmount {
                MoneyText(amount: amount)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func doneView(_ rental: Rental) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            StatusPill(text: "You're done", tint: Brand.ok)
            Text("Meter stopped")
                .font(BrandFont.title(28))
                .foregroundStyle(.white)
            Text("\(rental.scooterName) is back on the lot.")
                .foregroundStyle(Brand.silver)
            if let amount = rental.capturedAmount {
                MoneyText(amount: amount)
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
