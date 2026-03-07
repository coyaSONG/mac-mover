import SwiftUI

struct ImportTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: "Import Bundle", icon: "folder.badge.gear") {
                    HStack {
                        TextField("Import bundle path", text: $appState.importPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse", action: appState.chooseImportFolder)
                    }
                    HStack(spacing: 12) {
                        Button(action: appState.runImport) {
                            Label("Run Import", systemImage: "square.and.arrow.down")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .disabled(appState.isRunning || appState.importPath.isEmpty)

                        Button(action: appState.runVerify) {
                            Label("Verify", systemImage: "checkmark.shield")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .disabled(appState.isRunning || appState.importPath.isEmpty)
                    }
                }
                .overlay {
                    if appState.isRunning && (appState.statusMessage.contains("Import") || appState.statusMessage.contains("Verify")) {
                        ProgressOverlay(message: appState.statusMessage)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                if !appState.preflightChecks.isEmpty {
                    CardView(title: "Preflight Results", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(appState.preflightChecks, id: \.id) { check in
                                StatusBadge(check: check)
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 10)
                }

                if !appState.manualTasks.isEmpty {
                    CardView(title: "Manual Tasks", icon: "hand.raised") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(appState.manualTasks, id: \.id) { task in
                                ManualTaskRow(task: task)
                            }
                        }
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
