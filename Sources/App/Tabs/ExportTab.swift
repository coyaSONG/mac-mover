import SwiftUI

struct ExportTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: "Export Destination", icon: "folder") {
                    HStack {
                        TextField("Export path", text: $appState.exportPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse", action: appState.chooseExportFolder)
                    }
                    Button(action: appState.runExport) {
                        Label("Run Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.isRunning)
                }
                .overlay {
                    if appState.isRunning && appState.statusMessage.contains("Export") {
                        ProgressOverlay(message: appState.statusMessage)
                    }
                }

                if appState.exportSummary != "No export executed" {
                    CardView(title: "Summary", icon: "doc.text") {
                        ScrollView {
                            Text(appState.exportSummary)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
