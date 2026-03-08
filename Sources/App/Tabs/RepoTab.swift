import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct RepoTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: L10n.string(.repoConnectedWorkspaceTitle), icon: "folder.badge.gearshape") {
                    HStack {
                        TextField(L10n.string(.repoWorkspacePathPlaceholder), text: $appState.workspacePath)
                            .textFieldStyle(.roundedBorder)
                        Button(L10n.string(.actionBrowse), action: appState.chooseWorkspaceFolder)
                    }

                    Button {
                        let url = URL(fileURLWithPath: appState.workspacePath)
                        Task {
                            await appState.connectWorkspace(at: url)
                        }
                    } label: {
                        Label(L10n.string(.actionScanWorkspace), systemImage: "arrow.triangle.2.circlepath")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.isRunning || appState.workspacePath.isEmpty)

                    if let workspace = appState.connectedWorkspace {
                        Divider().padding(.vertical, 4)
                        Label(workspace.rootPath, systemImage: "folder")
                            .textSelection(.enabled)
                        if let toolSummary = appState.connectedWorkspaceToolSummary {
                            Label(toolSummary, systemImage: "wrench.and.screwdriver")
                                .foregroundStyle(Color.appMuted)
                        }
                    }
                }
                .overlay {
                    if appState.isWorkspaceScanRunning {
                        ProgressOverlay(message: appState.statusMessage)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.repoWorkspaceScanSummaryTitle), icon: "doc.text.magnifyingglass") {
                    ScrollView {
                        Text(appState.workspaceScanSummary)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 320)
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
}
