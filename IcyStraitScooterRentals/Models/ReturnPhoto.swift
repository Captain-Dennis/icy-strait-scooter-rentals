import Foundation
import SwiftData
import SwiftUI

@Model
final class ReturnPhoto {
    var sideRaw: String
    @Attribute(.externalStorage) var imageData: Data
    var capturedAt: Date
    var rental: Rental?

    init(side: ReturnPhotoSide, imageData: Data, capturedAt: Date = .now, rental: Rental? = nil) {
        self.sideRaw = side.rawValue
        self.imageData = imageData
        self.capturedAt = capturedAt
        self.rental = rental
    }

    var side: ReturnPhotoSide {
        ReturnPhotoSide(rawValue: sideRaw) ?? .left
    }
}
