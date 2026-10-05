import SwiftUI
import UIKit

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

    /// Desaturated harbor gray for quiet metadata. Not a second brand color.
    static let tide = Color(red: 0.62, green: 0.68, blue: 0.70)

    static let danger = Color(red: 0.95, green: 0.28, blue: 0.22)
    static let ok = Color(red: 0.35, green: 0.78, blue: 0.45)

    static let background = ink
    static let card = charcoal
    static let cardStroke = Color.white.opacity(0.08)
}

enum BrandFont {
    /// New York-style wordmark and unit names. Functional UI stays in `title`.
    static func display(_ size: CGFloat = 34) -> Font {
        .system(size: size, weight: .semibold, design: .serif)
    }

    static func title(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .bold, design: .default)
    }

    static func headline(_ size: CGFloat = 17) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }

    static func mono(_ size: CGFloat = 28) -> Font {
        .system(size: size, weight: .semibold, design: .monospaced)
    }

    static func eyebrow(_ size: CGFloat = 11) -> Font {
        .system(size: size, weight: .semibold, design: .default)
    }
}

enum BrandChrome {
    /// Opaque ink bars so tabs and navigation do not fall back to system material.
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
        nav.titleTextAttributes = [.foregroundColor: UIColor.white]
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        nav.shadowColor = .clear
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(red: 1.0, green: 0.353, blue: 0.0, alpha: 1)

        let tab = UITabBarAppearance()
        tab.configureWithOpaqueBackground()
        tab.backgroundColor = UIColor(red: 0.07, green: 0.07, blue: 0.07, alpha: 1)
        tab.shadowColor = UIColor.white.withAlphaComponent(0.06)
        UITabBar.appearance().standardAppearance = tab
        UITabBar.appearance().scrollEdgeAppearance = tab
    }
}

struct BrandCardModifier: ViewModifier {
    var radius: CGFloat = 18
    var stroke: Color = Brand.cardStroke

    func body(content: Content) -> some View {
        content
            .background(Brand.card, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(stroke)
            )
    }
}

extension View {
    func icyScreenBackground() -> some View {
        frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Brand.background.ignoresSafeArea())
    }

    func brandCard(radius: CGFloat = 18, stroke: Color = Brand.cardStroke) -> some View {
        modifier(BrandCardModifier(radius: radius, stroke: stroke))
    }
}
