import SwiftUI

@main
struct MacMoverApp: App {
    @StateObject private var appState = AppState()

    init() {
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .onAppear {
                    if #available(macOS 14.0, *) {
                        NSApplication.shared.activate()
                    } else {
                        NSApplication.shared.activate(ignoringOtherApps: true)
                    }
                }
        }
        .defaultSize(width: 960, height: 700)
    }
}
