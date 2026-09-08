import SwiftUI

/// Silhouette of the official 4-wheel offroad e-scooter.
/// Do not substitute SF Symbol `scooter` — that glyph is a 2-wheel kick scooter.
struct FourWheelScooterMark: View {
    var color: Color = Brand.orange
    var wheelColor: Color = Brand.ink

    var body: some View {
        Canvas { context, size in
            let w = size.width
            let h = size.height

            func wheel(_ cx: CGFloat) {
                let r = h * 0.16
                let center = CGPoint(x: w * cx, y: h * 0.78)
                context.fill(Path(ellipseIn: CGRect(x: center.x - r, y: center.y - r, width: r * 2, height: r * 2)), with: .color(wheelColor))
                let inner = r * 0.42
                context.fill(
                    Path(ellipseIn: CGRect(x: center.x - inner, y: center.y - inner, width: inner * 2, height: inner * 2)),
                    with: .color(Brand.silver)
                )
            }

            var deck = Path()
            deck.addRoundedRect(
                in: CGRect(x: w * 0.12, y: h * 0.52, width: w * 0.72, height: h * 0.14),
                cornerSize: CGSize(width: 6, height: 6)
            )
            context.fill(deck, with: .color(color))

            var stem = Path()
            stem.addRoundedRect(
                in: CGRect(x: w * 0.22, y: h * 0.16, width: w * 0.07, height: h * 0.40),
                cornerSize: CGSize(width: 4, height: 4)
            )
            context.fill(stem, with: .color(wheelColor))

            var bar = Path()
            bar.addRoundedRect(
                in: CGRect(x: w * 0.10, y: h * 0.14, width: w * 0.32, height: h * 0.07),
                cornerSize: CGSize(width: 4, height: 4)
            )
            context.fill(bar, with: .color(wheelColor))

            var seat = Path()
            seat.addRoundedRect(
                in: CGRect(x: w * 0.58, y: h * 0.42, width: w * 0.16, height: h * 0.08),
                cornerSize: CGSize(width: 5, height: 5)
            )
            context.fill(seat, with: .color(wheelColor))

            wheel(0.22)
            wheel(0.40)
            wheel(0.60)
            wheel(0.78)
        }
        .accessibilityHidden(true)
    }
}

struct FleetHeroImage: View {
    var cornerRadius: CGFloat = 18
    var height: CGFloat? = 200

    var body: some View {
        Image("FleetHero")
            .resizable()
            .scaledToFill()
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Brand.cardStroke, lineWidth: 1)
            )
            .accessibilityLabel("Official 4-wheel offroad e-scooter with bright orange frame, black fenders, and knobby all-terrain tires")
    }
}
