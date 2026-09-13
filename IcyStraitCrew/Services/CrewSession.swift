import Foundation
import Observation

@MainActor
@Observable
final class CrewSession {
    static let unlockedKey = "icystrait.crew.unlocked"
    static let operatorNameKey = "icystrait.crew.operatorName"

    var isUnlocked: Bool {
        didSet { UserDefaults.standard.set(isUnlocked, forKey: Self.unlockedKey) }
    }

    var operatorName: String {
        didSet { UserDefaults.standard.set(operatorName, forKey: Self.operatorNameKey) }
    }

    init() {
        isUnlocked = UserDefaults.standard.bool(forKey: Self.unlockedKey)
        operatorName = UserDefaults.standard.string(forKey: Self.operatorNameKey) ?? StaffConfig.starterName
    }

    func unlock(pin: String, name: String = StaffConfig.starterName) -> Bool {
        guard pin == StaffConfig.betaPIN else { return false }
        operatorName = name
        isUnlocked = true
        return true
    }

    func lock() {
        isUnlocked = false
    }
}
