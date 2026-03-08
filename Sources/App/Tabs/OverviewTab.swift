import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct OverviewTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: L10n.string(.overviewAppOverviewTitle), icon: "info.circle") {
                    Text(L10n.string(.overviewAppOverviewDescription))
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.overviewCurrentMachineTitle), icon: "desktopcomputer") {
                    VStack(alignment: .leading, spacing: 8) {
                        machineRow(icon: "network", label: L10n.string(.labelHost), value: appState.machineHost)
                        machineRow(icon: "cpu", label: L10n.string(.labelArchitecture), value: appState.machineArch)
                        machineRow(icon: "apple.logo", label: L10n.string(.labelMacOS), value: appState.machineOS)
                        machineRow(icon: "house", label: L10n.string(.labelHome), value: appState.machineHome)
                        machineRow(icon: "mug", label: L10n.string(.labelBrewPrefix), value: appState.machineBrewPrefix)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.overviewRecentRunsTitle), icon: "clock") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appState.connectedWorkspace?.rootPath ?? L10n.string(.overviewNoWorkspaceConnected), systemImage: "folder")
                            .foregroundStyle(appState.connectedWorkspace != nil ? Color.primary : Color.appMuted)
                        Label(L10n.format(.overviewDriftItemsCount, appState.driftItems.count), systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            .foregroundStyle(appState.driftItems.isEmpty ? Color.appMuted : Color.primary)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.overviewLegacyBundleWorkflowsTitle), icon: "shippingbox") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appState.lastExportBundleURL?.path ?? L10n.string(.overviewNoExportYet), systemImage: "square.and.arrow.up")
                            .foregroundStyle(appState.lastExportBundleURL != nil ? Color.primary : Color.appMuted)
                        Label(appState.lastImportBundleURL?.path ?? L10n.string(.overviewNoImportYet), systemImage: "square.and.arrow.down")
                            .foregroundStyle(appState.lastImportBundleURL != nil ? Color.primary : Color.appMuted)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
            }
            .padding(.vertical, 8)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    appeared = true
                }
            }
        }
    }

    private func machineRow(icon: String, label: String, value: String) -> some View {
        Label {
            HStack {
                Text(label)
                    .foregroundStyle(Color.appMuted)
                    .frame(width: 100, alignment: .leading)
                Text(value)
                    .textSelection(.enabled)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(Color.appAccent)
                .frame(width: 20)
        }
    }
}
