import SwiftUI
import UIKit

struct ReturnPhotoWizardView: View {
    @Binding var photos: [ReturnPhotoCapture]
    var onDone: () -> Void
    var busy: Bool = false

    @State private var side: ReturnPhotoSide = .left
    @State private var showCamera = false

    private var capturedIDs: Set<ReturnPhotoSide> {
        Set(photos.map(\.side))
    }

    private var currentPhoto: ReturnPhotoCapture? {
        photos.first(where: { $0.side == side })
    }

    private var bothReady: Bool {
        ReturnPhotoGate.canCompleteCheckIn(captured: capturedIDs)
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                Text(side == .left ? "1 of 2 · Left side" : "2 of 2 · Right side")
                    .font(BrandFont.title(26))
                    .foregroundStyle(.white)
                Text(side.instruction)
                    .font(.subheadline)
                    .foregroundStyle(Brand.silver)
                HStack(spacing: 6) {
                    Capsule().fill(capturedIDs.contains(.left) ? Brand.ok : (side == .left ? Brand.orange : Brand.slate)).frame(height: 7)
                    Capsule().fill(capturedIDs.contains(.right) ? Brand.ok : (side == .right ? Brand.orange : Brand.slate)).frame(height: 7)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    preview
                    if CameraImagePicker.isCameraAvailable {
                        PrimaryButton(
                            title: currentPhoto == nil ? "Take photo" : "Retake",
                            systemImage: "camera.fill"
                        ) {
                            showCamera = true
                        }
                    } else {
                        Text("No camera here. Grab a library shot or the demo photo.")
                            .font(.footnote)
                            .foregroundStyle(Brand.silver)
                    }
                    LibraryPhotoButton(title: "Choose from library") { apply($0) }
                    Button("Use demo photo") { useHeroPhoto() }
                        .font(BrandFont.headline(15))
                        .foregroundStyle(Brand.silver)
                        .frame(maxWidth: .infinity)
                }
                .padding(20)
            }

            VStack(spacing: 8) {
                if bothReady {
                    PrimaryButton(title: "Done · stop the meter", systemImage: "checkmark", busy: busy, action: onDone)
                } else if currentPhoto != nil, side == .left {
                    PrimaryButton(title: "Continue", systemImage: "arrow.right") {
                        side = .right
                    }
                }
            }
            .padding(16)
            .background(Brand.charcoal.ignoresSafeArea(edges: .bottom))
        }
        .background(Brand.background)
        .fullScreenCover(isPresented: $showCamera) {
            CameraImagePicker(
                onImage: { image in
                    showCamera = false
                    if let data = JPEGStore.compressed(image) { apply(data) }
                },
                onCancel: { showCamera = false }
            )
            .ignoresSafeArea()
        }
    }

    @ViewBuilder
    private var preview: some View {
        if let photo = currentPhoto, let image = UIImage(data: photo.jpegData) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 220)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(alignment: .topLeading) {
                    StatusPill(text: "Got it", tint: Brand.ok)
                        .padding(10)
                }
        } else {
            ZStack {
                FleetHeroImage(height: 220)
                    .opacity(0.28)
                Text("Line up the \(side.sideLabel.lowercased())")
                    .font(BrandFont.headline(16))
                    .foregroundStyle(.white)
            }
        }
    }

    private func apply(_ data: Data) {
        photos.removeAll { $0.side == side }
        photos.append(ReturnPhotoCapture(side: side, jpegData: data, capturedAt: .now))
        if side == .left, !capturedIDs.contains(.right) {
            side = .right
        }
    }

    private func useHeroPhoto() {
        guard let image = UIImage(named: "FleetHero"),
              let data = JPEGStore.compressed(image) else { return }
        apply(data)
    }
}
