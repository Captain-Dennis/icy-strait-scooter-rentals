import CoreImage
import UIKit

enum QRImageRenderer {
    static func image(from string: String, scale: CGFloat = 12) -> UIImage? {
        let data = Data(string.utf8)
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: scale, y: scale))
        let context = CIContext()
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

enum JPEGStore {
    static func compressed(_ image: UIImage, quality: CGFloat = 0.72) -> Data? {
        image.jpegData(compressionQuality: quality)
    }
}
