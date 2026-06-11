import SwiftUI

@main
struct MatchbarApp: App {
    @State private var store = MatchStore()

    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
        UpdateManager.start()
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView(store: store)
        } label: {
            MenuBarLabel(store: store)
        }
        .menuBarExtraStyle(.window)
    }
}
