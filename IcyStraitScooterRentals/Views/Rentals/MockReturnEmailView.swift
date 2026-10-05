import SwiftUI

struct MockReturnEmailView: View {
    var rental: Rental
    var onScan: (QRPayload) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("RETURNS DESK · DEMO")
                        .font(BrandFont.eyebrow())
                        .tracking(1.4)
                        .foregroundStyle(Brand.orange)
                    Text("Your return QR")
                        .font(BrandFont.display(32))
                        .foregroundStyle(.white)
                    Text("\(rental.scooterID) \(rental.scooterName)")
                        .font(BrandFont.headline(15))
                        .foregroundStyle(.white)
                    Text("From returns@icystraitscooters.example")
                        .font(.caption)
                        .foregroundStyle(Brand.tide)
                }
                UnitPhoto(scooterID: rental.scooterID, unitName: rental.scooterName, height: 140)

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
