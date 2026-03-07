import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
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
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacMover")
                    .font(.title2)
                    .bold()
                Text(appState.statusMessage)
                    .font(.callout)
                    .foregroundStyle(Color.appMuted)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: appState.statusMessage)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
