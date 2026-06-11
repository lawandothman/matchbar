import SwiftUI

@main
struct WorldCupApp: App {
    init() {
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra {
            Text("World Cup 2026")
                .padding()
        } label: {
            Image(systemName: "soccerball")
        }
        .menuBarExtraStyle(.window)
    }
}
