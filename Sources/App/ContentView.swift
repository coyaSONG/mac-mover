import SwiftUI
import SharedModels

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Mac Dev Env Mover")
                .font(.title2)
                .bold()
            Text(appState.statusMessage)
                .font(.callout)
                .foregroundStyle(.secondary)

            TabView {
                OverviewTab()
                    .tabItem { Label("Overview", systemImage: "house") }
                ExportTab()
                    .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                ImportTab()
                    .tabItem { Label("Import", systemImage: "square.and.arrow.down") }
                ReportsTab()
                    .tabItem { Label("Reports", systemImage: "doc.text") }
            }
        }
        .padding(16)
        .frame(minWidth: 900, minHeight: 620)
    }
}
