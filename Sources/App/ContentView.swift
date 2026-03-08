import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView {
                OverviewTab()
                    .tabItem { Label(L10n.string(.appTabOverview), systemImage: "house") }
                RepoTab()
                    .tabItem { Label(L10n.string(.appTabRepo), systemImage: "folder.badge.gearshape") }
                DriftTab()
                    .tabItem { Label(L10n.string(.appTabDrift), systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right") }
                ExportTab()
                    .tabItem { Label(L10n.string(.appTabExport), systemImage: "square.and.arrow.up") }
                ImportTab()
                    .tabItem { Label(L10n.string(.appTabImport), systemImage: "square.and.arrow.down") }
                ReportsTab()
                    .tabItem { Label(L10n.string(.appTabReports), systemImage: "doc.text") }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.string(.appTitle))
                    .font(.title2)
                    .bold()
                Text(appState.statusMessage)
                    .font(.callout)
                    .foregroundStyle(Color.appMuted)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: appState.statusMessage)
            }
            Spacer()
            if let workspace = appState.connectedWorkspace {
                Label(L10n.format(.workspaceDetectedToolsCount, workspace.detectedTools.count), systemImage: "wrench.and.screwdriver")
                    .font(.caption)
                    .foregroundStyle(Color.appMuted)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
