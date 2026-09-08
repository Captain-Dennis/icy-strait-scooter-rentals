import SwiftUI

struct PrimaryButton: View {
    var title: String
    var systemImage: String? = nil
    var enabled: Bool = true
    var busy: Bool = false
    var fill: Color = Brand.orange
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if busy {
                    ProgressView()
                        .tint(.white)
                } else if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(BrandFont.headline())
            }
            .font(BrandFont.headline(18))
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.vertical, 4)
            .foregroundStyle(enabled && !busy ? Color.white : Color.white.opacity(0.45))
            .background(enabled && !busy ? fill : Brand.slate, in: Capsule())
        }
        .disabled(!enabled || busy)
        .buttonStyle(.plain)
    }
}

struct DraftLegalBanner: View {
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "doc.badge.ellipsis")
                .foregroundStyle(Brand.orange)
            Text("Draft copy for the owner to replace with counsel-approved language before public use.")
                .font(.footnote)
                .foregroundStyle(Brand.silver)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct CapacityMeter: View {
    var remaining: Int
    var capacity: Int = Season.capacityPerHour

    var taken: Int { max(0, capacity - remaining) }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(remaining)/\(capacity) open")
                    .font(BrandFont.headline(15))
                    .foregroundStyle(remaining == 0 ? Brand.danger : .white)
                Spacer()
                Text("\(taken) out")
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
            }
            GeometryReader { geo in
                let width = geo.size.width
                let filled = width * CGFloat(taken) / CGFloat(max(capacity, 1))
                ZStack(alignment: .leading) {
                    Capsule().fill(Brand.slate)
                    Capsule()
                        .fill(remaining == 0 ? Brand.danger : Brand.orange)
                        .frame(width: max(filled, taken > 0 ? 8 : 0))
                }
            }
            .frame(height: 8)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(remaining) of \(capacity) 4-wheel offroad e-scooters open")
    }
}

struct MoneyText: View {
    var amount: Decimal
    var size: CGFloat = 32

    var body: some View {
        Text(MoneyFormat.string(amount))
            .font(BrandFont.mono(size))
            .foregroundStyle(.white)
            .monospacedDigit()
    }
}

struct StatusPill: View {
    var text: String
    var tint: Color = Brand.orange

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(tint.opacity(0.16), in: Capsule())
    }
}

struct EmptyHeroState: View {
    var title: String
    var message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FleetHeroImage(height: 168)
            Text(title)
                .font(BrandFont.title(22))
                .foregroundStyle(.white)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Brand.cardStroke)
        )
    }
}

struct ScooterDetailCard: View {
    var scooter: Scooter
    var remainingThisHour: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FleetHeroImage(height: 176)
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scooter.name)
                        .font(BrandFont.title(24))
                        .foregroundStyle(.white)
                    Text(scooter.scooterID)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.orange)
                }
                Spacer()
                FourWheelScooterMark()
                    .frame(width: 72, height: 44)
            }
            Text(scooter.vehicleSummary)
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
            HStack(spacing: 10) {
                meta(scooter.dockLabel, symbol: "mappin.and.ellipse")
                meta("\(scooter.batteryPercent)% battery", symbol: "bolt.fill")
                meta("~\(scooter.estimatedRangeMiles) mi", symbol: "arrow.left.and.right")
            }
            if let remainingThisHour {
                CapacityMeter(remaining: remainingThisHour)
            }
        }
        .padding(16)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Brand.cardStroke)
        )
    }

    private func meta(_ text: String, symbol: String) -> some View {
        Label(text, systemImage: symbol)
            .font(.caption)
            .foregroundStyle(Brand.mist)
            .labelStyle(.titleAndIcon)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
    }
}
