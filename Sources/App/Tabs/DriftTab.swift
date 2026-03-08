import SwiftUI
#if canImport(Localization)
import Localization
#endif

struct DriftTab: View {
    @EnvironmentObject private var appState: AppState
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: L10n.string(.driftOverviewTitle), icon: "arrow.left.and.right.righttriangle.left.righttriangle.right") {
                    VStack(alignment: .leading, spacing: 8) {
                        driftRow(title: L10n.string(.driftModified), count: appState.driftItems.filter { $0.status == .modified }.count)
                        driftRow(title: L10n.string(.driftMissing), count: appState.driftItems.filter { $0.status == .missing }.count)
                        driftRow(title: L10n.string(.driftExtra), count: appState.driftItems.filter { $0.status == .extra }.count)
                        driftRow(title: L10n.string(.driftManual), count: appState.driftItems.filter { $0.status == .manual }.count)
                        driftRow(title: L10n.string(.driftUnsupported), count: appState.driftItems.filter { $0.status == .unsupported }.count)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.driftWorkspaceSummaryTitle), icon: "list.bullet.rectangle") {
                    ScrollView {
                        Text(appState.workspaceDriftSummary)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 260)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.workspaceApplyPreviewTitle), icon: "square.and.arrow.down.on.square") {
                    Text(appState.workspaceApplySummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)

                CardView(title: L10n.string(.workspacePromotePreviewTitle), icon: "square.and.arrow.up.on.square") {
                    Text(appState.workspacePromoteSummary)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
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

    private func driftRow(title: String, count: Int) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(Color.appMuted)
            Spacer()
            Text("\(count)")
                .font(.system(.headline, design: .rounded))
        }
    }
}
