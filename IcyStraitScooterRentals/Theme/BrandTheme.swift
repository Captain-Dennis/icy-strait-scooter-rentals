import SwiftUI

enum Brand {
    /// Safety orange sampled from the official 4-wheel offroad e-scooter frame.
    static let orange = Color(red: 1.0, green: 0.353, blue: 0.0)
    static let orangeDeep = Color(red: 0.86, green: 0.26, blue: 0.0)
    static let orangeSoft = Color(red: 1.0, green: 0.48, blue: 0.18)

    /// Gloss black from fenders, seat, and handlebars.
    static let ink = Color(red: 0.07, green: 0.07, blue: 0.07)
    static let charcoal = Color(red: 0.12, green: 0.12, blue: 0.13)
    static let slate = Color(red: 0.18, green: 0.18, blue: 0.19)

    /// Silver from the multi-spoke alloy rims.
    static let silver = Color(red: 0.78, green: 0.78, blue: 0.80)
    static let mist = Color(red: 0.93, green: 0.93, blue: 0.94)

    static let danger = Color(red: 0.95, green: 0.28, blue: 0.22)
    static let ok = Color(red: 0.35, green: 0.78, blue: 0.45)

    static let background = ink
    static let card = charcoal
    static let cardStroke = Color.white.opacity(0.08)
}

enum BrandFont {
    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }

    static func mono(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }
}

extension View {
    func icyScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Brand.background.ignoresSafeArea())
    }
}
