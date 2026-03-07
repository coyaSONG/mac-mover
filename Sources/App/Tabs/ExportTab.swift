import SwiftUI

struct ExportTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

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
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

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
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }
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
