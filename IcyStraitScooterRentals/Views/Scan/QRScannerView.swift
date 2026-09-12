import SwiftUI
import VisionKit

struct QRScannerView: UIViewControllerRepresentable {
    var onPayload: (String) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onPayload: onPayload) }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode(symbologies: [.qr])],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        context.coordinator.scanner = scanner
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        uiViewController.stopScanning()
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        var onPayload: (String) -> Void
        weak var scanner: DataScannerViewController?
        private var locked = false

        init(onPayload: @escaping (String) -> Void) {
            self.onPayload = onPayload
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didTapOn item: RecognizedItem) {
            emit(item)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            if let first = addedItems.first {
                emit(first)
            }
        }

        private func emit(_ item: RecognizedItem) {
            guard !locked else { return }
            if case .barcode(let barcode) = item, let payload = barcode.payloadStringValue {
                locked = true
                onPayload(payload)
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
                    self?.locked = false
                }
            }
        }
    }
}

@MainActor
enum CameraAvailability {
    static var canScanQR: Bool {
        DataScannerViewController.isSupported && DataScannerViewController.isAvailable
    }
}

struct QRScannerPane: View {
    var onPayload: (String) -> Void

    var body: some View {
        if CameraAvailability.canScanQR {
            QRScannerView(onPayload: onPayload)
                .frame(height: 240)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        } else {
            VStack(alignment: .leading, spacing: 10) {
                FleetHeroImage(height: 150)
                Text("The Simulator has no QR camera. Enter a unit ID, tap a fleet chip, or use a sample payload below.")
                    .font(.footnote)
                    .foregroundStyle(Brand.silver)
            }
        }
    }
}
