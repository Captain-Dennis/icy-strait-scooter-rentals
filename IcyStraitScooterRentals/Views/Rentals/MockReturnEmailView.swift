import SwiftUI

struct MockReturnEmailView: View {
    var rental: Rental
    var onScan: (QRPayload) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Inbox · Demo")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.orange)
                    Text("Your Icy Strait return QR")
                        .font(BrandFont.title(24))
                        .foregroundStyle(.white)
                    Text("From returns@icystraitscooters.example")
                        .font(.caption)
                        .foregroundStyle(Brand.silver)
                }

                Text("Thanks for riding \(rental.scooterName) (\(rental.scooterID)). When you reach the drop-off lot, scan this QR, then photograph the left and right sides of the 4-wheel offroad e-scooter to finish check-in.")
                    .font(.subheadline)
                    .foregroundStyle(Brand.mist)

                QRCodeView(payload: rental.returnPayload.urlString, dimension: 220)
                    .frame(maxWidth: .infinity)

                Text(rental.returnPayload.urlString)
                    .font(.caption.monospaced())
                    .foregroundStyle(Brand.silver)
                    .textSelection(.enabled)

                PrimaryButton(title: "Simulate scan of this QR", systemImage: "qrcode.viewfinder") {
                    onScan(rental.returnPayload)
                }
            }
            .padding(20)
        }
        .icyScreenBackground()
        .navigationTitle("Return email")
        .navigationBarTitleDisplayMode(.inline)
    }
}
