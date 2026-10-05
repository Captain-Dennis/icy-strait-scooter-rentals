import SwiftData
import SwiftUI

struct CrewSignInView: View {
    @Environment(CrewSession.self) private var session
    @Query(sort: \StaffMember.displayName) private var staff: [StaffMember]
    @State private var pin = ""
    @State private var error: String?
    @State private var selectedName = StaffConfig.starterName

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                PlaceLockup(
                    kicker: "Icy Strait Crew",
                    title: "Hoonah desk",
                    subtitle: "Staff phones only. Six stem stickers. Glacier is the live unit."
                )
                UnitPhoto(scooterID: "IS-101", unitName: "Glacier", height: 140, cornerRadius: 14)

                VStack(alignment: .leading, spacing: 8) {
                    SectionLabel(title: "Who’s on the desk")
                    Picker("Operator", selection: $selectedName) {
                        ForEach(staff.filter(\.isActive), id: \.staffID) { person in
                            Text(person.displayName).tag(person.displayName)
                        }
                        if staff.isEmpty {
                            Text(StaffConfig.starterName).tag(StaffConfig.starterName)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(Brand.orange)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .brandCard(radius: 12)
                }

                Text(pin.maskedPIN)
                    .font(BrandFont.mono(32))
                    .foregroundStyle(.white)
                    .tracking(6)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .brandCard(radius: 14)

                pinPad

                if let error {
                    Text(error)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Brand.danger)
                }

                Text("Beta PIN is the last four of the front-desk cell (\(StaffConfig.betaPIN)). This is not a full login product.")
                    .font(.caption)
                    .foregroundStyle(Brand.tide)
            }
            .padding(20)
        }
        .icyScreenBackground()
    }

    private var pinPad: some View {
        let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
        return VStack(spacing: 8) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tap(key)
                        } label: {
                            Text(key)
                                .font(BrandFont.title(22))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 56)
                                .background(key.isEmpty ? Color.clear : Brand.slate, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                        .disabled(key.isEmpty)
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func tap(_ key: String) {
        error = nil
        if key == "⌫" {
            if !pin.isEmpty { pin.removeLast() }
            return
        }
        guard pin.count < 4 else { return }
        pin.append(key)
        if pin.count == 4 {
            if session.unlock(pin: pin, name: selectedName) {
                pin = ""
            } else {
                error = "Wrong PIN"
                pin = ""
            }
        }
    }
}

private extension String {
    var maskedPIN: String {
        let dots = String(repeating: "●", count: count)
        let pads = String(repeating: "○", count: max(0, 4 - count))
        return dots + pads
    }
}
