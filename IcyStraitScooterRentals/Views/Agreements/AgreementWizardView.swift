import SwiftUI

struct AgreementWizardView: View {
    @Binding var accepted: [AgreementAcceptanceRecord]
    var readOnly: Bool = false
    var requireLinearAccept: Bool = false
    var startTitle: String = "Start rental"
    var startBusy: Bool = false
    var onAllAccepted: (() -> Void)? = nil

    @State private var selection: AgreementSectionID = .rentalAgreement

    private var acceptedIDs: Set<AgreementSectionID> {
        Set(accepted.map(\.sectionID))
    }

    private var acceptedCount: Int {
        AgreementGate.acceptedCount(acceptedIDs)
    }

    private var allAccepted: Bool {
        AgreementGate.canStartRental(accepted: acceptedIDs)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView(selection: $selection) {
                ForEach(AgreementSectionID.allCases) { section in
                    sectionPage(section)
                        .tag(section)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            footer
        }
        .background(Brand.background)
        .onChange(of: selection) { old, new in
            if requireLinearAccept && !readOnly && !AgreementGate.canOpen(new, accepted: acceptedIDs) {
                selection = old
            }
        }
        .onChange(of: acceptedIDs) { _, ids in
            if requireLinearAccept, !AgreementGate.canOpen(selection, accepted: ids) {
                selection = AgreementGate.missing(from: ids).first ?? .rentalAgreement
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(readOnly ? "Your agrees" : selection.progressLabel)
                    .font(BrandFont.title(28))
                    .foregroundStyle(.white)
                Spacer()
                Text(readOnly ? "Saved" : "\(acceptedCount)/5")
                    .font(BrandFont.headline(18))
                    .foregroundStyle(allAccepted ? Brand.ok : Brand.orange)
            }
            HStack(spacing: 6) {
                ForEach(AgreementSectionID.allCases) { section in
                    Capsule()
                        .fill(dotColor(section))
                        .frame(height: 7)
                }
            }
            Text(selection.title)
                .font(BrandFont.headline(16))
                .foregroundStyle(selection.isHighEmphasis ? Brand.danger : Brand.orange)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }

    private func dotColor(_ section: AgreementSectionID) -> Color {
        if acceptedIDs.contains(section) { return Brand.ok }
        if section == selection { return Brand.orange }
        return Brand.slate
    }

    private func sectionPage(_ section: AgreementSectionID) -> some View {
        let copy = AgreementLibrary.copy(for: section)
        return ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text(copy.headline)
                    .font(BrandFont.title(22))
                    .foregroundStyle(.white)
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(copy.bullets.enumerated()), id: \.offset) { _, bullet in
                        AgreementBulletRow(text: bullet, emphasizeProhibited: section == .areaOfOperation || section.isHighEmphasis)
                    }
                }
                if let stamp = accepted.first(where: { $0.sectionID == section })?.acceptedAt {
                    Text("Agreed \(stamp.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(Brand.silver)
                }
            }
            .padding(20)
        }
    }

    private var footer: some View {
        VStack(spacing: 10) {
            if !readOnly {
                if acceptedIDs.contains(selection) {
                    if !allAccepted {
                        Text("Next up: \(AgreementGate.missing(from: acceptedIDs).first?.title ?? "")")
                            .font(.footnote)
                            .foregroundStyle(Brand.silver)
                    }
                } else {
                    PrimaryButton(
                        title: "I agree",
                        systemImage: "checkmark",
                        fill: selection.isHighEmphasis ? Brand.danger : Brand.orange
                    ) {
                        toggle(selection)
                    }
                    Text(selection.acceptLabel)
                        .font(.caption)
                        .foregroundStyle(Brand.silver)
                        .multilineTextAlignment(.center)
                }
            }

            if !readOnly, allAccepted, let onAllAccepted {
                PrimaryButton(
                    title: startTitle,
                    systemImage: "flag.checkered",
                    busy: startBusy,
                    action: onAllAccepted
                )
            }
        }
        .padding(16)
        .background(Brand.charcoal.ignoresSafeArea(edges: .bottom))
    }

    private func toggle(_ section: AgreementSectionID) {
        if let index = accepted.firstIndex(where: { $0.sectionID == section }) {
            accepted.remove(at: index)
        } else {
            accepted.append(AgreementAcceptanceRecord(sectionID: section, acceptedAt: .now))
            if section != AgreementSectionID.allCases.last {
                move(1, onlyIfAccepted: true)
            }
        }
    }

    private func move(_ delta: Int, onlyIfAccepted: Bool = false) {
        guard let index = AgreementSectionID.allCases.firstIndex(of: selection) else { return }
        let next = index + delta
        guard AgreementSectionID.allCases.indices.contains(next) else { return }
        let target = AgreementSectionID.allCases[next]
        if requireLinearAccept && !readOnly && !AgreementGate.canOpen(target, accepted: acceptedIDs) {
            return
        }
        if onlyIfAccepted && delta > 0 && !acceptedIDs.contains(selection) { return }
        withAnimation { selection = target }
    }
}

struct AgreementBulletRow: View {
    var text: String
    var emphasizeProhibited: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Circle()
                .fill(isProhibited ? Brand.danger : Brand.orange)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            bulletText
                .font(.body)
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityLabel(text)
    }

    private var isProhibited: Bool {
        text.hasPrefix("PROHIBITED:")
    }

    @ViewBuilder
    private var bulletText: some View {
        if let rule = styledRule {
            (Text(rule.label)
                .font(.body.weight(.bold))
                .foregroundStyle(rule.prohibited ? Brand.danger : Brand.ok)
                + Text(rule.detail))
        } else {
            Text(text)
        }
    }

    private var styledRule: (label: String, detail: String, prohibited: Bool)? {
        if text.hasPrefix("PROHIBITED:") {
            return ("PROHIBITED:", String(text.dropFirst("PROHIBITED:".count)), true)
        }
        if text.hasPrefix("ALLOWED:") {
            return ("ALLOWED:", String(text.dropFirst("ALLOWED:".count)), false)
        }
        return nil
    }
}
