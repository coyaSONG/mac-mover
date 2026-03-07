import SwiftUI

struct ReportsTab: View {
    @EnvironmentObject private var appState: AppState

    @State private var workspaceScanExpanded = true
    @State private var workspaceDriftExpanded = true
    @State private var workspaceApplyExpanded = false
    @State private var workspacePromoteExpanded = false
    @State private var exportExpanded = false
    @State private var importExpanded = false
    @State private var verifyExpanded = false
    @State private var logsExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                reportSection(
                    title: "Workspace Scan",
                    icon: "doc.text.magnifyingglass",
                    content: appState.workspaceScanSummary,
                    isExpanded: $workspaceScanExpanded
                )
                reportSection(
                    title: "Workspace Drift",
                    icon: "arrow.left.and.right.righttriangle.left.righttriangle.right",
                    content: appState.workspaceDriftSummary,
                    isExpanded: $workspaceDriftExpanded
                )
                reportSection(
                    title: "Apply Preview",
                    icon: "square.and.arrow.down.on.square",
                    content: appState.workspaceApplySummary,
                    isExpanded: $workspaceApplyExpanded
                )
                reportSection(
                    title: "Promote Preview",
                    icon: "square.and.arrow.up.on.square",
                    content: appState.workspacePromoteSummary,
                    isExpanded: $workspacePromoteExpanded
                )
                reportSection(
                    title: "Legacy Export Report",
                    icon: "square.and.arrow.up",
                    content: appState.exportSummary,
                    isExpanded: $exportExpanded
                )
                reportSection(
                    title: "Legacy Import Report",
                    icon: "square.and.arrow.down",
                    content: appState.importSummary,
                    isExpanded: $importExpanded
                )
                reportSection(
                    title: "Legacy Verify Report",
                    icon: "checkmark.shield",
                    content: appState.verifySummary,
                    isExpanded: $verifyExpanded
                )
                reportSection(
                    title: "Logs",
                    icon: "text.alignleft",
                    content: appState.logsPreview,
                    isExpanded: $logsExpanded,
                    isCaption: true
                )
            }
            .padding(.vertical, 8)
        }
    }

    private func reportSection(
        title: String,
        icon: String,
        content: String,
        isExpanded: Binding<Bool>,
        isCaption: Bool = false
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            DisclosureGroup(isExpanded: isExpanded) {
                Text(content)
                    .font(.system(isCaption ? .caption : .body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)
            } label: {
                Label(title, systemImage: icon)
                    .font(.headline)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modifier(GlassReportBackground())
    }
}

private struct GlassReportBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 26.0, *) {
            content
                .glassEffect(.regular, in: .rect(cornerRadius: 12))
        } else {
            content
                .background(.thickMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(.quaternary, lineWidth: 0.5)
                )
        }
    }
}
