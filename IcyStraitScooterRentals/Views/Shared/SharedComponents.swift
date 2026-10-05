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
            .font(.caption2.weight(.bold))
            .tracking(0.4)
            .foregroundStyle(tint)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().strokeBorder(tint.opacity(0.28), lineWidth: 0.5))
    }
}

struct SectionLabel: View {
    var title: String
    var trailing: String? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title.uppercased())
                .font(BrandFont.eyebrow())
                .tracking(1.35)
                .foregroundStyle(Brand.tide)
            Spacer(minLength: 8)
            if let trailing {
                Text(trailing)
                    .font(.caption)
                    .foregroundStyle(Brand.silver)
            }
        }
    }
}

struct PlaceLockup: View {
    var kicker: String = "Hoonah · Icy Strait Point"
    var title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(kicker.uppercased())
                .font(BrandFont.eyebrow())
                .tracking(1.6)
                .foregroundStyle(Brand.orange)
            Rectangle()
                .fill(Brand.orange)
                .frame(width: 28, height: 2)
            Text(title)
                .font(BrandFont.display(34))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Brand.silver)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FactChip: View {
    var text: String
    var symbol: String

    var body: some View {
        Label(text, systemImage: symbol)
            .font(.caption.weight(.medium))
            .foregroundStyle(Brand.mist)
            .lineLimit(1)
            .minimumScaleFactor(0.75)
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(Brand.slate, in: Capsule())
    }
}

struct EmptyHeroState: View {
    var title: String
    var message: String
    var kicker: String = "Icy Strait Point"

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            FleetHeroImage(height: 168)
            VStack(alignment: .leading, spacing: 8) {
                Text(kicker.uppercased())
                    .font(BrandFont.eyebrow())
                    .tracking(1.4)
                    .foregroundStyle(Brand.orange)
                Text(title)
                    .font(BrandFont.display(26))
                    .foregroundStyle(.white)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(Brand.silver)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .brandCard(radius: 20)
    }
}

struct ScooterDetailCard: View {
    var scooter: Scooter
    var remainingThisHour: Int?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            UnitPhoto(
                scooterID: scooter.scooterID,
                unitName: scooter.name,
                height: 176
            )
            VStack(alignment: .leading, spacing: 4) {
                Text(scooter.scooterID)
                    .font(BrandFont.mono(13))
                    .foregroundStyle(Brand.orange)
                Text(scooter.name)
                    .font(BrandFont.display(28))
                    .foregroundStyle(.white)
            }
            Text(scooter.vehicleSummary)
                .font(.subheadline)
                .foregroundStyle(Brand.silver)
            VStack(alignment: .leading, spacing: 8) {
                FactChip(text: scooter.dockLabel, symbol: "mappin.and.ellipse")
                HStack(spacing: 8) {
                    FactChip(text: "\(scooter.batteryPercent)% battery", symbol: "bolt.fill")
                    FactChip(text: "~\(scooter.estimatedRangeMiles) mi", symbol: "arrow.left.and.right")
                }
            }
            if let remainingThisHour {
                CapacityMeter(remaining: remainingThisHour)
            }
        }
        .padding(16)
        .brandCard(radius: 22)
    }
}
