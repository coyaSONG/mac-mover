# Dev Environment Control Tower Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Replace the bundle-first workflow with a repo-first developer environment control tower that can scan, diff, apply, promote, verify, and report against a connected environment repo.

**Architecture:** Add repo-aware adapters and state models beside the existing exporter/importer code, then rewire `AppState` and the SwiftUI tabs to drive repo scan, drift, apply, and promote workflows. Reuse backup, manual task, verification, and Markdown reporting primitives instead of rebuilding them.

**Tech Stack:** Swift 6.2, SwiftUI, Swift Concurrency, Swift Testing, native macOS APIs, `Process`-backed command execution

---

### Task 1: Add Repo Workspace Models

**Files:**
- Create: `Sources/SharedModels/WorkspaceModels.swift`
- Modify: `Sources/SharedModels/OperationReport.swift`
- Modify: `Sources/SharedModels/WorkflowResults.swift`
- Test: `Tests/ManifestSchemaTests/WorkspaceModelsTests.swift`

**Step 1: Write the failing test**

```swift
import Testing
@testable import SharedModels

@Test func driftItemCapturesRepoAndLocalValues() throws {
    let item = DriftItem(
        category: .dotfiles,
        identifier: ".zshrc",
        repoValue: .string("repo"),
        localValue: .string("local"),
        status: .modified,
        suggestedResolutions: [.apply, .promote]
    )

    #expect(item.status == .modified)
    #expect(item.suggestedResolutions.contains(.apply))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorkspaceModelsTests`
Expected: FAIL because `DriftItem` and related workspace models do not exist yet.

**Step 3: Write minimal implementation**

```swift
public enum DriftStatus: String, Codable {
    case missing
    case extra
    case modified
    case manual
    case unsupported
}

public struct DriftItem: Codable, Equatable, Sendable {
    public var category: ItemCategory
    public var identifier: String
    public var repoValue: JSONValue?
    public var localValue: JSONValue?
    public var status: DriftStatus
    public var suggestedResolutions: [DriftResolution]
}
```

Also add `ConnectedWorkspace`, `RepoSnapshot`, `EnvironmentSnapshot`, and any report payload updates needed for scan and drift reporting.

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorkspaceModelsTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/SharedModels/WorkspaceModels.swift Sources/SharedModels/OperationReport.swift Sources/SharedModels/WorkflowResults.swift Tests/ManifestSchemaTests/WorkspaceModelsTests.swift
git commit -m "feat: add workspace and drift shared models"
```

### Task 2: Add Repo Detection and Parsing

**Files:**
- Create: `Sources/Core/RepoWorkspaceDetector.swift`
- Create: `Sources/Core/RepoSnapshotLoader.swift`
- Modify: `Sources/Core/ErrorTypes.swift`
- Test: `Tests/CoreTests/RepoWorkspaceDetectorTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Core

@Test func detectsChezmoiAndBrewfileInWorkspace() throws {
    let root = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent(UUID().uuidString)
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    try Data().write(to: root.appendingPathComponent(".chezmoiroot"))
    try Data().write(to: root.appendingPathComponent("Brewfile"))

    let workspace = try RepoWorkspaceDetector().detect(at: root)

    #expect(workspace.detectedTools.contains(.chezmoi))
    #expect(workspace.detectedTools.contains(.homebrew))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter RepoWorkspaceDetectorTests`
Expected: FAIL because detector types do not exist yet.

**Step 3: Write minimal implementation**

```swift
struct RepoWorkspaceDetector {
    func detect(at root: URL) throws -> ConnectedWorkspace {
        var tools: [WorkspaceTool] = []
        if FileManager.default.fileExists(atPath: root.appendingPathComponent("Brewfile").path) {
            tools.append(.homebrew)
        }
        if FileManager.default.fileExists(atPath: root.appendingPathComponent(".chezmoiroot").path) {
            tools.append(.chezmoi)
        }
        return ConnectedWorkspace(rootURL: root, detectedTools: tools, lastScannedAt: nil)
    }
}
```

Extend the loader to normalize repo state for `Brewfile`, `mise.toml` or `.tool-versions`, VS Code files, and plain dotfiles allowlist fallback.

**Step 4: Run test to verify it passes**

Run: `swift test --filter RepoWorkspaceDetectorTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Core/RepoWorkspaceDetector.swift Sources/Core/RepoSnapshotLoader.swift Sources/Core/ErrorTypes.swift Tests/CoreTests/RepoWorkspaceDetectorTests.swift
git commit -m "feat: detect supported tools in connected repos"
```

### Task 3: Add Local Environment Scan and Drift Engine

**Files:**
- Create: `Sources/Core/EnvironmentScanner.swift`
- Create: `Sources/Core/DriftEngine.swift`
- Modify: `Sources/Core/VerifyEngine.swift`
- Test: `Tests/CoreTests/DriftEngineTests.swift`

**Step 1: Write the failing test**

```swift
import Testing
import SharedModels
@testable import Core

@Test func classifiesMissingAndModifiedItems() throws {
    let repo = RepoSnapshot(items: [
        DriftComparableItem(category: .homebrew, identifier: "wget", value: .string("present")),
        DriftComparableItem(category: .dotfiles, identifier: ".zshrc", value: .string("repo"))
    ])
    let local = EnvironmentSnapshot(items: [
        DriftComparableItem(category: .dotfiles, identifier: ".zshrc", value: .string("local"))
    ])

    let drift = DriftEngine().compare(repo: repo, local: local)

    #expect(drift.contains(where: { $0.identifier == "wget" && $0.status == .missing }))
    #expect(drift.contains(where: { $0.identifier == ".zshrc" && $0.status == .modified }))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter DriftEngineTests`
Expected: FAIL because the scanner comparison types do not exist yet.

**Step 3: Write minimal implementation**

```swift
struct DriftEngine {
    func compare(repo: RepoSnapshot, local: EnvironmentSnapshot) -> [DriftItem] {
        // Normalize by category + identifier and classify missing, extra, and modified items.
    }
}
```

Backfill `EnvironmentScanner` with the minimum Homebrew, dotfiles, Git global, and VS Code scan support needed by the tests.

**Step 4: Run test to verify it passes**

Run: `swift test --filter DriftEngineTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Core/EnvironmentScanner.swift Sources/Core/DriftEngine.swift Sources/Core/VerifyEngine.swift Tests/CoreTests/DriftEngineTests.swift
git commit -m "feat: add environment scanning and drift classification"
```

### Task 4: Build Apply and Promote Workflows

**Files:**
- Create: `Sources/Importers/WorkspaceApplyCoordinator.swift`
- Create: `Sources/Exporters/WorkspacePromoteCoordinator.swift`
- Modify: `Sources/Core/FileRestorer.swift`
- Modify: `Sources/Core/ManualTaskEngine.swift`
- Test: `Tests/ExporterImporterTests/WorkspaceWorkflowTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Exporters
@testable import Importers

@Test func applyCreatesBackupBeforeOverwritingDotfile() throws {
    // Arrange a repo snapshot and local file, then expect a `.bak` file after apply.
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorkspaceWorkflowTests`
Expected: FAIL because workspace apply and promote coordinators do not exist yet.

**Step 3: Write minimal implementation**

```swift
public struct WorkspaceApplyCoordinator {
    public func apply(workspace: ConnectedWorkspace, selections: [DriftSelection]) throws -> OperationReport {
        // Reuse FileRestorer, SecretPolicy, and ManualTaskEngine.
    }
}
```

Implement promote as a preview-first workflow that writes candidate files into a staging area rather than auto-committing to the repo.

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorkspaceWorkflowTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Importers/WorkspaceApplyCoordinator.swift Sources/Exporters/WorkspacePromoteCoordinator.swift Sources/Core/FileRestorer.swift Sources/Core/ManualTaskEngine.swift Tests/ExporterImporterTests/WorkspaceWorkflowTests.swift
git commit -m "feat: add workspace apply and promote coordinators"
```

### Task 5: Add Repo-Centric Reports

**Files:**
- Modify: `Sources/Reporting/MarkdownReportWriter.swift`
- Modify: `Sources/Reporting/ReportFileWriter.swift`
- Test: `Tests/CoreTests/WorkspaceReportTests.swift`

**Step 1: Write the failing test**

```swift
import Testing
import SharedModels
@testable import Reporting

@Test func writesDriftSummaryWithStatusSections() throws {
    let markdown = MarkdownReportWriter().makeDriftSummary(from: [
        DriftItem(category: .dotfiles, identifier: ".zshrc", repoValue: .string("repo"), localValue: .string("local"), status: .modified, suggestedResolutions: [.apply, .promote])
    ])

    #expect(markdown.contains("Modified"))
    #expect(markdown.contains(".zshrc"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorkspaceReportTests`
Expected: FAIL because drift report rendering does not exist yet.

**Step 3: Write minimal implementation**

```swift
extension MarkdownReportWriter {
    func makeDriftSummary(from items: [DriftItem]) -> String {
        // Group by status and render markdown sections.
    }
}
```

Update file-writing paths for `scan-summary.md`, `drift-summary.md`, `apply-summary.md`, `promote-summary.md`, and `manual-tasks.md`.

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorkspaceReportTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Reporting/MarkdownReportWriter.swift Sources/Reporting/ReportFileWriter.swift Tests/CoreTests/WorkspaceReportTests.swift
git commit -m "feat: add workspace drift and apply reports"
```

### Task 6: Rewire App State and Tabs

**Files:**
- Modify: `Sources/App/AppState.swift`
- Modify: `Sources/App/ContentView.swift`
- Modify: `Sources/App/Tabs/OverviewTab.swift`
- Modify: `Sources/App/Tabs/ExportTab.swift`
- Modify: `Sources/App/Tabs/ImportTab.swift`
- Modify: `Sources/App/Tabs/ReportsTab.swift`
- Create: `Sources/App/Tabs/RepoTab.swift`
- Create: `Sources/App/Tabs/DriftTab.swift`
- Test: `Tests/AppTests/AppStateTests.swift`

**Step 1: Write the failing test**

```swift
import Testing
@testable import App

@MainActor
@Test func connectingWorkspaceUpdatesStatusAndDetectedTools() async throws {
    let state = AppState(initialMachineInfo: nil)
    // Inject stub services and expect workspace-specific status after connect.
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppStateTests`
Expected: FAIL because the app state still models export/import bundles rather than repo workflows.

**Step 3: Write minimal implementation**

```swift
@Published var connectedWorkspace: ConnectedWorkspace?
@Published var driftItems: [DriftItem] = []

func connectWorkspace(at url: URL) {
    // Detect repo tools, load snapshots, and refresh summaries.
}
```

Reframe the tabs around Overview, Repo, Drift, Apply/Promote, and Reports while preserving report previews and progress feedback.

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppStateTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/App/AppState.swift Sources/App/ContentView.swift Sources/App/Tabs/OverviewTab.swift Sources/App/Tabs/ExportTab.swift Sources/App/Tabs/ImportTab.swift Sources/App/Tabs/ReportsTab.swift Sources/App/Tabs/RepoTab.swift Sources/App/Tabs/DriftTab.swift Tests/AppTests/AppStateTests.swift
git commit -m "feat: rework app shell around repo control tower flows"
```

### Task 7: Update Docs and Fixtures

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/plan.md`
- Modify: `SampleExportBundle/Brewfile`
- Modify: `SampleExportBundle/manifest.json`

**Step 1: Write the failing doc check**

Run: `rg -n "export bundle|Import bundle" README.md docs/architecture.md`
Expected: find stale bundle-first language that no longer matches the product direction.

**Step 2: Update the docs and fixtures**

Document the repo-first workflow, supported repo conventions, drift policy, and revised reports. Adjust sample artifacts so they describe operation history rather than being the primary product model.

**Step 3: Run doc check again**

Run: `rg -n "export bundle|Import bundle" README.md docs/architecture.md`
Expected: no stale product-defining references remain, or remaining references are explicitly marked as legacy compatibility.

**Step 4: Commit**

```bash
git add README.md docs/architecture.md docs/plan.md SampleExportBundle/Brewfile SampleExportBundle/manifest.json
git commit -m "docs: document repo-first control tower workflow"
```

### Task 8: Full Verification

**Files:**
- Modify: no code changes expected

**Step 1: Run package build**

Run: `swift build`
Expected: BUILD SUCCEEDED with no new warnings.

**Step 2: Run all tests**

Run: `swift test`
Expected: PASS for `CoreTests`, `ExporterImporterTests`, `ManifestSchemaTests`, and `AppTests`.

**Step 3: Run repository verification scripts**

Run: `./scripts/check-project-source-drift.sh`
Expected: PASS

Run: `./scripts/xcodebuild-check.sh`
Expected: PASS on machines with full Xcode selected; if blocked, capture the exact missing prerequisite.

**Step 4: Commit verification note if needed**

```bash
git status --short
```

Expected: clean working tree, or only intentional doc/test updates if a follow-up fix was required.
