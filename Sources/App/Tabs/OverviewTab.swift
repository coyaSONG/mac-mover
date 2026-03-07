import SwiftUI

struct OverviewTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: "App Overview", icon: "info.circle") {
                    Text("Manage a local developer environment repo, compare it against the current Mac, and preview workspace drift before apply or promote actions.")
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: "Current Machine", icon: "desktopcomputer") {
                    VStack(alignment: .leading, spacing: 8) {
                        machineRow(icon: "network", label: "Host", value: appState.machineHost)
                        machineRow(icon: "cpu", label: "Architecture", value: appState.machineArch)
                        machineRow(icon: "apple.logo", label: "macOS", value: appState.machineOS)
                        machineRow(icon: "house", label: "Home", value: appState.machineHome)
                        machineRow(icon: "mug", label: "Brew Prefix", value: appState.machineBrewPrefix)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: "Recent Runs", icon: "clock") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appState.connectedWorkspace?.rootPath ?? "No workspace connected", systemImage: "folder")
                            .foregroundStyle(appState.connectedWorkspace != nil ? Color.primary : Color.appMuted)
                        Label("\(appState.driftItems.count) drift items", systemImage: "arrow.left.and.right.righttriangle.left.righttriangle.right")
                            .foregroundStyle(appState.driftItems.isEmpty ? Color.appMuted : Color.primary)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: "Legacy Bundle Workflows", icon: "shippingbox") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appState.lastExportBundleURL?.path ?? "No export yet", systemImage: "square.and.arrow.up")
                            .foregroundStyle(appState.lastExportBundleURL != nil ? Color.primary : Color.appMuted)
                        Label(appState.lastImportBundleURL?.path ?? "No import yet", systemImage: "square.and.arrow.down")
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
