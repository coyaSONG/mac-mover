#if canImport(XCTest)
import XCTest
@testable import App
@testable import Core
@testable import SharedModels

@MainActor
final class AppStateTests: XCTestCase {
    func testRunImportPreflightLoadsPreviewState() throws {
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

        XCTAssertEqual(appState.lastImportBundleURL, bundleURL)
        XCTAssertEqual(appState.manualTasks, manifest.manualTasks)
        XCTAssertEqual(appState.preflightChecks, preview.preflight.checks)
        XCTAssertEqual(appState.exportSummary, "export summary")
        XCTAssertEqual(appState.importSummary, "import summary")
        XCTAssertEqual(appState.verifySummary, "verify summary")
        XCTAssertEqual(appState.logsPreview, "log preview")
        XCTAssertEqual(appState.machineSummary, "Machine Summary")
        XCTAssertEqual(appState.statusMessage, "Import bundle ready")
    }
}

private struct MockBundlePreviewLoader: BundlePreviewLoading {
    let result: Result<BundlePreview, Error>

    func load(from bundleURL: URL) throws -> BundlePreview {
        try result.get()
    }
}
#endif
