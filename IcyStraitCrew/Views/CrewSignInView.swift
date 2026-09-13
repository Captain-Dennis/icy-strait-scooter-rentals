import SwiftData
import SwiftUI

struct CrewSignInView: View {
    @Environment(CrewSession.self) private var session
    @Query(sort: \StaffMember.displayName) private var staff: [StaffMember]
    @State private var pin = ""
    @State private var error: String?
    @State private var selectedName = StaffConfig.starterName

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            FourWheelScooterMark()
                .frame(width: 92, height: 56)
            Text("Icy Strait Crew")
                .font(BrandFont.title(32))
                .foregroundStyle(Brand.orange)
            Text("Staff phones only. Hoonah lot board for the six stem-sticker units.")
                .font(.body)
                .foregroundStyle(Brand.silver)

            VStack(alignment: .leading, spacing: 8) {
                Text("Who’s on the desk")
                    .font(BrandFont.headline(14))
                    .foregroundStyle(Brand.silver)
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
            }

            Text(pin.maskedPIN)
                .font(BrandFont.mono(36))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: 16, style: .continuous))

            pinPad

            if let error {
                Text(error)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.danger)
            }

            Text("Beta PIN is the last four of the front-desk cell (\(StaffConfig.betaPIN)). This is not a full login product.")
                .font(.footnote)
                .foregroundStyle(Brand.silver)
            Spacer()
        }
        .padding(22)
        .icyScreenBackground()
    }

    private var pinPad: some View {
        let keys = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["", "0", "⌫"]]
        return VStack(spacing: 10) {
            ForEach(keys, id: \.self) { row in
                HStack(spacing: 10) {
                    ForEach(row, id: \.self) { key in
                        Button {
                            tap(key)
                        } label: {
                            Text(key)
                                .font(BrandFont.title(24))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity, minHeight: 64)
                                .background(key.isEmpty ? Color.clear : Brand.slate, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(key.isEmpty)
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
