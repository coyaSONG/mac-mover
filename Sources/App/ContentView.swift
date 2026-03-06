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

private struct OverviewTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                GroupBox("App Overview") {
                    Text("Recreate a personal development environment (Homebrew, allowlisted dotfiles, Git global config, and VS Code) on a new Mac via export/import.")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Current Machine") {
                    Text(appState.machineSummary)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox("Recent Runs") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Last Export: \(appState.lastExportBundleURL?.path ?? "none")")
                        Text("Last Import: \(appState.lastImportBundleURL?.path ?? "none")")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct ExportTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Export path", text: $appState.exportPath)
                Button("Browse", action: appState.chooseExportFolder)
                Button("Run Export", action: appState.runExport)
                    .keyboardShortcut(.defaultAction)
            }

            GroupBox("Summary") {
                ScrollView {
                    Text(appState.exportSummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

private struct ImportTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                TextField("Import bundle path", text: $appState.importPath)
                Button("Browse", action: appState.chooseImportFolder)
                Button("Run Import", action: appState.runImport)
                Button("Run Verify", action: appState.runVerify)
            }

            GroupBox("Preflight Results") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(appState.preflightChecks, id: \.id) { check in
                            let prefix = check.passed ? "[OK]" : (check.blocking ? "[BLOCK]" : "[WARN]")
                            Text("\(prefix) \(check.title): \(check.detail)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }

            GroupBox("Manual Tasks") {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if appState.manualTasks.isEmpty {
                            Text("(none)")
                                .frame(maxWidth: .infinity, alignment: .leading)
                        } else {
                            ForEach(appState.manualTasks, id: \.id) { task in
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("- \(task.title) [blocking: \(task.blocking ? "yes" : "no")]")
                                    Text("  reason: \(task.reason)")
                                    Text("  action: \(task.action)")
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct ReportsTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GroupBox("Export Report") {
                ScrollView {
                    Text(appState.exportSummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            GroupBox("Import Report") {
                ScrollView {
                    Text(appState.importSummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            GroupBox("Verify Report") {
                ScrollView {
                    Text(appState.verifySummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }

            GroupBox("Logs") {
                ScrollView {
                    Text(appState.logsPreview)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}
