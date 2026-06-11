import Foundation
import Sparkle

@MainActor
enum UpdateManager {
    // Sparkle requires a real app bundle; bare `swift run` has none
    private static var controller: SPUStandardUpdaterController?

    static func start() {
        guard Bundle.main.bundleIdentifier != nil, controller == nil else { return }
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    static func checkForUpdates() {
        controller?.updater.checkForUpdates()
    }
}
