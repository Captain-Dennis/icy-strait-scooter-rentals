import SwiftUI

struct QRCodeView: View {
    var payload: String
    var dimension: CGFloat = 220

    var body: some View {
        Group {
            if let image = QRImageRenderer.image(from: payload) {
                Image(uiImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .padding(12)
                    .background(.white, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            } else {
                Text(payload)
                    .font(.caption.monospaced())
                    .foregroundStyle(.white)
                    .padding()
            }
        }
        .frame(width: dimension, height: dimension)
        .accessibilityLabel("QR code for \(payload)")
    }
}
