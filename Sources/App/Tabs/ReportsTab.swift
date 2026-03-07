import SwiftUI

struct ReportsTab: View {
    @EnvironmentObject private var appState: AppState

    @State private var exportExpanded = true
    @State private var importExpanded = false
    @State private var verifyExpanded = false
    @State private var logsExpanded = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                reportSection(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    content: appState.exportSummary,
                    isExpanded: $exportExpanded
                )
                reportSection(
                    title: "Import Report",
                    icon: "square.and.arrow.down",
                    content: appState.importSummary,
                    isExpanded: $importExpanded
                )
                reportSection(
                    title: "Verify Report",
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
