import Foundation
import Combine

final class SettingsStore: ObservableObject {
    @Published var captureMode: CaptureMode {
        didSet { save() }
    }

    @Published var sideOrientation: SideOrientation {
        didSet { save() }
    }

    @Published var aspectMode: AspectMode {
        didSet { save() }
    }

    private let defaults: UserDefaults
    private let captureKey = "captureMode"
    private let sideKey = "sideOrientation"
    private let aspectKey = "aspectMode"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.captureMode = defaults.string(forKey: captureKey).flatMap(CaptureMode.init(rawValue:)) ?? .frontAndSide
        self.sideOrientation = defaults.string(forKey: sideKey).flatMap(SideOrientation.init(rawValue:)) ?? .right
        self.aspectMode = defaults.string(forKey: aspectKey).flatMap(AspectMode.init(rawValue:)) ?? .original
    }

    private func save() {
        defaults.set(captureMode.rawValue, forKey: captureKey)
        defaults.set(sideOrientation.rawValue, forKey: sideKey)
        defaults.set(aspectMode.rawValue, forKey: aspectKey)
    }
}
