import Foundation
import Testing
@testable import App
@testable import Core
@testable import SharedModels

@Test
@MainActor
func isRunningDefaultsToFalse() {
    let appState = AppState(machineSummaryProvider: { "test" })
    #expect(appState.isRunning == false)
}

@Test
@MainActor
func runImportPreflightLoadsPreviewState() throws {
    let bundleURL = URL(fileURLWithPath: "/tmp/import-bundle")
    let manifest = Manifest(
        exportedAt: Date(timeIntervalSince1970: 1_700_000_000),
        machine: MachineInfo(
            hostname: "source-host",
            architecture: .arm64,
            macosVersion: "15.3",
            homeDirectory: "/Users/test",
            homebrewPrefix: "/opt/homebrew",
            userName: "tester"
        ),
        items: [],
        restorePlan: [],
        manualTasks: [
            ManualTask(
                id: "manual.preview",
                title: "Preview task",
                reason: "needs review",
                action: "read the report",
                blocking: false
            )
        ],
        reports: ManifestReports(
            exportSummaryPath: "reports/export-summary.md",
            verifySummaryPath: "reports/verify-summary.md"
        )
    )
    let preview = BundlePreview(
        bundleURL: bundleURL,
        manifest: manifest,
        preflight: PreflightResult(
            machine: manifest.machine,
            checks: [PreflightCheck(id: "preflight.bundle.exists", title: "Import bundle exists", passed: true, detail: bundleURL.path, blocking: true)]
        ),
        exportSummary: "export summary",
        importSummary: "import summary",
        verifySummary: "verify summary",
        logsPreview: "log preview"
    )
    let appState = AppState(
        bundlePreviewLoader: MockBundlePreviewLoader(result: .success(preview)),
        machineSummaryProvider: { "Machine Summary" }
    )

    appState.runImportPreflight(bundleURL: bundleURL)

    #expect(appState.lastImportBundleURL == bundleURL)
    #expect(appState.manualTasks == manifest.manualTasks)
    #expect(appState.preflightChecks == preview.preflight.checks)
    #expect(appState.exportSummary == "export summary")
    #expect(appState.importSummary == "import summary")
    #expect(appState.verifySummary == "verify summary")
    #expect(appState.logsPreview == "log preview")
    #expect(appState.machineSummary == "Machine Summary")
    #expect(appState.statusMessage == "Import bundle ready")
}

private struct MockBundlePreviewLoader: BundlePreviewLoading {
    let result: Result<BundlePreview, Error>

    func load(from bundleURL: URL) throws -> BundlePreview {
        try result.get()
    }
}
