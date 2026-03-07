import SwiftUI

@main
struct MacMoverApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .defaultSize(width: 960, height: 700)
    }
}
