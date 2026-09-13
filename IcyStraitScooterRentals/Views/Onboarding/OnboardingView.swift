import SwiftUI

struct OnboardingView: View {
    var onFinished: () -> Void
    @State private var page = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                heroPage.tag(0)
                howPage.tag(1)
                pricePage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            PrimaryButton(
                title: page < 2 ? "Continue" : "Enter the lot",
                systemImage: page < 2 ? "arrow.right" : "qrcode.viewfinder"
            ) {
                if page < 2 {
                    withAnimation { page += 1 }
                } else {
                    AppPreferences.onboardingCompleted = true
                    onFinished()
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
        .icyScreenBackground()
    }

    private var heroPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                FleetHeroImage(height: 260)
                StatusPill(text: "4-wheel offroad e-scooters")
                Text("Icy Strait Scooter Rentals")
                    .font(BrandFont.title(30))
                    .foregroundStyle(.white)
                Text("Stand-up or sit-down 4-wheel offroad electric scooters — bright orange frame, gloss black fenders, four knobby all-terrain tires. Not a 2-wheel kick scooter.")
                    .font(.body)
                    .foregroundStyle(Brand.silver)
            }
            .padding(20)
        }
    }

    private var howPage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("How a rental works")
                    .font(BrandFont.title(28))
                    .foregroundStyle(.white)
                step(1, title: "Scan the stem QR", detail: "Preferred code is https://icystraitscooters.example/s/IS-101 (opens the app or the App Store install page). escooter://scooter/IS-101 still works for Simulator demos.")
                step(2, title: "Accept every agreement first", detail: "Agreements come before payment. Five required sections, including Damage & Liability. You cannot skip, save for later, or start a rental until all five are accepted.")
                step(3, title: "Ride, then check in", detail: "A return QR is “emailed” to you (demo inbox in the app). Scan it, then photograph the left and right sides. That stops the meter, captures the mock POS charge, and texts every active staff member.")
            }
            .padding(20)
        }
    }

    private var pricePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Season, hours, price")
                    .font(BrandFont.title(28))
                    .foregroundStyle(.white)
                priceRow("First hour", MoneyFormat.string(BillingCalculator.firstHour))
                priceRow("Each extra 30 minutes", MoneyFormat.string(BillingCalculator.additionalHalfHour))
                priceRow("Live lot today", "IS-101 Glacier only")
                priceRow("2027 fleet / hourly cap", "6 units · 6 rentals/hour")
                priceRow("Season", "May 1–September 30, 2027")
                priceRow("Hours", "8:00 AM–7:00 PM Alaska time")
                Text("Charges run through POSProvider. This build uses MockPOSProvider — no API keys, no live card traffic.")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
                    .padding(.top, 8)
            }
            .padding(20)
        }
    }

    private func step(_ number: Int, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(BrandFont.headline(16))
                .foregroundStyle(.black)
                .frame(width: 28, height: 28)
                .background(Brand.orange, in: Circle())
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(BrandFont.headline()).foregroundStyle(.white)
                Text(detail).font(.subheadline).foregroundStyle(Brand.silver)
            }
        }
        .padding(14)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func priceRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title).foregroundStyle(Brand.silver)
            Spacer()
            Text(value).foregroundStyle(.white).font(BrandFont.headline(15))
        }
        .padding(14)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
