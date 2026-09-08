import Foundation

enum ReturnPhotoSide: String, CaseIterable, Codable, Identifiable, Comparable {
    case left
    case right

    var id: String { rawValue }

    var title: String {
        switch self {
        case .left: return "Left"
        case .right: return "Right"
        }
    }

    var sideLabel: String {
        "\(title) side"
    }

    var instruction: String {
        switch self {
        case .left:
            return "Stand on the rider’s left. Capture the full 4-wheel offroad e-scooter in profile — orange frame, black fenders, knobby all-terrain tires."
        case .right:
            return "Stand on the rider’s right. Match the official side profile: orange body, gloss black fenders, four knobby tires."
        }
    }

    var symbolName: String {
        switch self {
        case .left: return "arrow.left.circle.fill"
        case .right: return "arrow.right.circle.fill"
        }
    }

    var stepIndex: Int {
        switch self {
        case .left: return 1
        case .right: return 2
        }
    }

    var progressTitle: String {
        "Photo \(stepIndex) of \(ReturnPhotoSide.allCases.count) — \(sideLabel)"
    }

    static func < (lhs: ReturnPhotoSide, rhs: ReturnPhotoSide) -> Bool {
        lhs.stepIndex < rhs.stepIndex
    }
}

struct ReturnPhotoCapture: Equatable, Identifiable {
    var side: ReturnPhotoSide
    var jpegData: Data
    var capturedAt: Date

    var id: ReturnPhotoSide { side }
}

enum ReturnPhotoGate {
    static var requiredSides: Set<ReturnPhotoSide> { Set(ReturnPhotoSide.allCases) }

    static func capturedCount(_ sides: Set<ReturnPhotoSide>) -> Int {
        sides.intersection(requiredSides).count
    }

    static func canCompleteCheckIn(captured: Set<ReturnPhotoSide>) -> Bool {
        captured.intersection(requiredSides) == requiredSides
    }

    static func canCompleteCheckIn(photos: [ReturnPhotoCapture]) -> Bool {
        canCompleteCheckIn(captured: Set(photos.map(\.side)))
    }
}
