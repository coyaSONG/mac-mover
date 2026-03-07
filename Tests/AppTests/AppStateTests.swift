import Foundation
import Testing
@testable import App
@testable import Core
@testable import SharedModels
@testable import Reporting

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

@Test
@MainActor
func connectWorkspaceLoadsSnapshotsAndDriftState() async throws {
    let workspaceURL = URL(fileURLWithPath: "/tmp/dev-env-repo")
    let connectedWorkspace = ConnectedWorkspace(
        rootPath: workspaceURL.path,
        detectedTools: [.chezmoi, .homebrew]
    )
    let repoSnapshot = RepoSnapshot(
        capturedAt: Date(timeIntervalSince1970: 1_700_000_000),
        items: [
            WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("repo-hash"))
        ]
    )
    let environmentSnapshot = EnvironmentSnapshot(
        capturedAt: Date(timeIntervalSince1970: 1_700_000_010),
        items: [
            WorkspaceItem(category: .dotfiles, identifier: "~/.zshrc", value: .string("local-hash"))
        ]
    )
    let driftItems = [
        DriftItem(
            category: .dotfiles,
            identifier: "~/.zshrc",
            repoValue: .string("repo-hash"),
            localValue: .string("local-hash"),
            status: .modified,
            suggestedResolutions: [.apply, .promote]
        )
    ]

    let appState = AppState(
        workspaceDetector: MockWorkspaceDetector(result: .success(connectedWorkspace)),
        repoSnapshotLoader: MockRepoSnapshotLoader(result: .success(repoSnapshot)),
        environmentScanner: MockEnvironmentScanner(snapshot: environmentSnapshot),
        driftEngine: MockDriftEngine(items: driftItems),
        machineSummaryProvider: { "Machine Summary" }
    )

    await appState.connectWorkspace(at: workspaceURL)

    #expect(appState.workspacePath == workspaceURL.path)
    #expect(appState.connectedWorkspace?.rootPath == workspaceURL.path)
    #expect(appState.repoSnapshot == repoSnapshot)
    #expect(appState.environmentSnapshot == environmentSnapshot)
    #expect(appState.driftItems == driftItems)
    #expect(appState.workspaceScanSummary.contains("# Workspace Scan Summary"))
    #expect(appState.workspaceDriftSummary.contains("# Workspace Drift Summary"))
    #expect(appState.workspaceApplySummary.contains("Workspace Apply Preview"))
    #expect(appState.workspacePromoteSummary.contains("Workspace Promote Preview"))
    #expect(appState.statusMessage == "Workspace scan completed with drift")
}

@Test
@MainActor
func contentViewKeepsRepoDriftAndLegacyTransferTabsReachable() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let contentViewURL = sourceRoot.appendingPathComponent("Sources/App/ContentView.swift")
    let content = try String(contentsOf: contentViewURL, encoding: .utf8)

    #expect(content.contains("Label(\"Repo\""))
    #expect(content.contains("Label(\"Drift\""))
    #expect(content.contains("Label(\"Export\""))
    #expect(content.contains("Label(\"Import\""))
    #expect(content.contains("Label(\"Reports\""))
}

@Test
@MainActor
func xcodeProjectRegistersRepoAndDriftTabs() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let projectURL = sourceRoot.appendingPathComponent("MacMover.xcodeproj/project.pbxproj")
    let project = try String(contentsOf: projectURL, encoding: .utf8)

    #expect(project.contains("RepoTab.swift"))
    #expect(project.contains("DriftTab.swift"))
    #expect(project.contains("RepoTab.swift in Sources"))
    #expect(project.contains("DriftTab.swift in Sources"))
}

private struct MockBundlePreviewLoader: BundlePreviewLoading {
    let result: Result<BundlePreview, Error>

    func load(from bundleURL: URL) throws -> BundlePreview {
        try result.get()
    }
}

private struct MockWorkspaceDetector: WorkspaceDetecting {
    let result: Result<ConnectedWorkspace, Error>

    func detect(at root: URL) throws -> ConnectedWorkspace {
        try result.get()
    }
}

private struct MockRepoSnapshotLoader: RepoSnapshotLoading {
    let result: Result<RepoSnapshot, Error>

    func load(from workspace: ConnectedWorkspace) throws -> RepoSnapshot {
        try result.get()
    }
}

private struct MockEnvironmentScanner: EnvironmentScanning {
    let snapshot: EnvironmentSnapshot

    func scan() -> EnvironmentSnapshot {
        snapshot
    }
}

private struct MockDriftEngine: DriftComparing {
    let items: [DriftItem]

    func compare(repo: RepoSnapshot, local: EnvironmentSnapshot) -> [DriftItem] {
        items
    }
}
