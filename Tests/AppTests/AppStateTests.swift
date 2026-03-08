import Foundation
import Testing
@testable import App
@testable import Core
@testable import Localization
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
    #expect(appState.statusMessage == L10n.string(.statusImportBundleReady))
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
    #expect(appState.workspaceScanSummary.contains("# \(L10n.string(.repoWorkspaceScanSummaryTitle))"))
    #expect(appState.workspaceDriftSummary.contains("# \(L10n.string(.driftWorkspaceSummaryTitle))"))
    #expect(appState.workspaceApplySummary.contains(L10n.string(.workspaceApplyPreviewTitle)))
    #expect(appState.workspacePromoteSummary.contains(L10n.string(.workspacePromotePreviewTitle)))
    #expect(appState.workspaceApplySummary.contains("[\(L10n.string(.driftModified))]"))
    #expect(appState.workspacePromoteSummary.contains("[\(L10n.string(.driftModified))]"))
    #expect(!appState.workspaceApplySummary.contains("[modified]"))
    #expect(!appState.workspacePromoteSummary.contains("[modified]"))
    #expect(appState.statusMessage == L10n.string(.statusWorkspaceScanCompletedWithDrift))
}

@Test
@MainActor
func connectedWorkspaceToolSummaryUsesLocalizedLabels() {
    let appState = AppState(machineSummaryProvider: { "Machine Summary" })
    appState.connectedWorkspace = ConnectedWorkspace(
        rootPath: "/tmp/dev-env-repo",
        detectedTools: [.plainDotfiles, .homebrew]
    )

    #expect(appState.connectedWorkspaceToolSummary == "Homebrew, Plain Dotfiles")
}

@Test
@MainActor
func connectedWorkspaceToolSummaryIsNilWhenNoToolsWereDetected() {
    let appState = AppState(machineSummaryProvider: { "Machine Summary" })
    appState.connectedWorkspace = ConnectedWorkspace(
        rootPath: "/tmp/dev-env-repo",
        detectedTools: []
    )

    #expect(appState.connectedWorkspaceToolSummary == nil)
}

@Test
@MainActor
func repoTabUsesExplicitWorkspaceScanStateForOverlay() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let repoTabURL = sourceRoot.appendingPathComponent("Sources/App/Tabs/RepoTab.swift")
    let content = try String(contentsOf: repoTabURL, encoding: .utf8)

    #expect(content.contains("appState.isWorkspaceScanRunning"))
    #expect(!content.contains("appState.statusMessage == L10n.string(.statusWorkspaceScanRunning)"))
}

@Test
func overviewDriftItemCountUsesLocalizedPluralization() {
    #expect(L10n.format(.overviewDriftItemsCount, locale: Locale(identifier: "en"), 1) == "1 drift item")
    #expect(L10n.format(.overviewDriftItemsCount, locale: Locale(identifier: "en"), 2) == "2 drift items")
    #expect(L10n.format(.overviewDriftItemsCount, locale: Locale(identifier: "ko"), 1) == "드리프트 항목 1개")
    #expect(L10n.format(.overviewDriftItemsCount, locale: Locale(identifier: "ko"), 3) == "드리프트 항목 3개")
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
