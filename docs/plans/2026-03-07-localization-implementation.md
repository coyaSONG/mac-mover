# MacMover Localization Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add English and Korean localization across the SwiftUI app, runtime status messages, workflow-generated user-facing text, and markdown reports while preserving the current manifest contract and CLI build workflow.

**Architecture:** Introduce a dedicated `Localization` SwiftPM target with bundle-backed `.strings` and `.stringsdict` resources, then replace hard-coded user-facing strings with typed helper calls from `App`, `Reporting`, `Core`, `Exporters`, and `Importers`. Keep persisted manifest/report contracts unchanged in the first pass, but localize all newly generated UI and report scaffolding.

**Tech Stack:** Swift 6.2, SwiftUI, SwiftPM resources, Foundation localization APIs, Swift Testing, macOS app bundle Info.plist localization metadata

---

### Task 1: Add the Localization Module and Bundle Configuration

**Files:**
- Modify: `Package.swift`
- Modify: `Sources/App/Info.plist`
- Modify: `Xcode/App-Info.plist`
- Modify: `MacMover.xcodeproj/project.pbxproj`
- Create: `Sources/Localization/Localization.swift`
- Create: `Sources/Localization/Resources/en.lproj/Localizable.strings`
- Create: `Sources/Localization/Resources/ko.lproj/Localizable.strings`
- Create: `Sources/Localization/Resources/en.lproj/Localizable.stringsdict`
- Create: `Sources/Localization/Resources/ko.lproj/Localizable.stringsdict`
- Test: `Tests/CoreTests/LocalizationTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Localization

@Test func englishLookupReturnsDefaultText() {
    let locale = Locale(identifier: "en")
    #expect(L10n.string(.appTabOverview, locale: locale) == "Overview")
}

@Test func koreanLookupReturnsTranslatedText() {
    let locale = Locale(identifier: "ko")
    #expect(L10n.string(.appTabOverview, locale: locale) == "개요")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter LocalizationTests`
Expected: FAIL because the `Localization` target and `L10n` API do not exist yet.

**Step 3: Write minimal implementation**

```swift
public enum L10nKey: String {
    case appTabOverview = "app.tab.overview"
}

public enum L10n {
    public static func string(_ key: L10nKey, locale: Locale = .autoupdatingCurrent) -> String {
        String(
            localized: String.LocalizationValue(key.rawValue),
            bundle: .module,
            locale: locale
        )
    }
}
```

Also:

- add `defaultLocalization: "en"` to `Package.swift`
- add the `Localization` library target and target dependencies
- add app bundle localization metadata in both plist files
- register new source/resources in the Xcode project

**Step 4: Run test to verify it passes**

Run: `swift test --filter LocalizationTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Package.swift Sources/App/Info.plist Xcode/App-Info.plist MacMover.xcodeproj/project.pbxproj Sources/Localization Tests/CoreTests/LocalizationTests.swift
git commit -m "feat: add shared localization module"
```

### Task 2: Localize the App Shell and Tab Content

**Files:**
- Modify: `Sources/App/ContentView.swift`
- Modify: `Sources/App/Tabs/OverviewTab.swift`
- Modify: `Sources/App/Tabs/RepoTab.swift`
- Modify: `Sources/App/Tabs/DriftTab.swift`
- Modify: `Sources/App/Tabs/ExportTab.swift`
- Modify: `Sources/App/Tabs/ImportTab.swift`
- Modify: `Sources/App/Tabs/ReportsTab.swift`
- Modify: `Sources/App/Theme/CardView.swift`
- Test: `Tests/AppTests/AppStateTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Localization

@Test func tabTitleKeysResolveForEnglishAndKorean() {
    #expect(L10n.string(.appTabRepo, locale: Locale(identifier: "en")) == "Repo")
    #expect(L10n.string(.appTabRepo, locale: Locale(identifier: "ko")) == "저장소")
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppStateTests`
Expected: FAIL after adding key usage because the app views still contain hard-coded literals.

**Step 3: Write minimal implementation**

Replace direct literals such as:

```swift
Label("Repo", systemImage: "folder.badge.gearshape")
```

with:

```swift
Label(L10n.string(.appTabRepo), systemImage: "folder.badge.gearshape")
```

Cover:

- tab labels
- card titles
- button labels
- placeholders
- overview labels such as Host, Architecture, Home, Brew Prefix

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppStateTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/App/ContentView.swift Sources/App/Tabs/OverviewTab.swift Sources/App/Tabs/RepoTab.swift Sources/App/Tabs/DriftTab.swift Sources/App/Tabs/ExportTab.swift Sources/App/Tabs/ImportTab.swift Sources/App/Tabs/ReportsTab.swift Sources/App/Theme/CardView.swift Tests/AppTests/AppStateTests.swift
git commit -m "feat: localize app shell and tab content"
```

### Task 3: Localize AppState Status Messages and Preview Summaries

**Files:**
- Modify: `Sources/App/AppState.swift`
- Modify: `Sources/Localization/Localization.swift`
- Modify: `Sources/Localization/Resources/en.lproj/Localizable.strings`
- Modify: `Sources/Localization/Resources/ko.lproj/Localizable.strings`
- Modify: `Sources/Localization/Resources/en.lproj/Localizable.stringsdict`
- Modify: `Sources/Localization/Resources/ko.lproj/Localizable.stringsdict`
- Test: `Tests/AppTests/AppStateTests.swift`

**Step 1: Write the failing test**

```swift
@Test
@MainActor
func connectWorkspaceUsesLocalizedStatusAndPreviewHeadings() async throws {
    let appState = AppState(/* existing mocks */)
    await appState.connectWorkspace(at: URL(fileURLWithPath: "/tmp/dev-env-repo"))

    #expect(appState.statusMessage == "Workspace scan completed with drift")
    #expect(appState.workspaceApplySummary.contains("Workspace Apply Preview"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppStateTests`
Expected: FAIL after moving `AppState` to localized status generation.

**Step 3: Write minimal implementation**

Add typed keys for:

- idle/default placeholders
- export/import/verify running/completed/failed states
- workspace scan states
- preview headings
- pluralized counts such as `ready items`

Use formatting helpers for error-bearing strings:

```swift
statusMessage = L10n.format(.statusImportFailed, error.localizedDescription)
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppStateTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/App/AppState.swift Sources/Localization/Localization.swift Sources/Localization/Resources/en.lproj/Localizable.strings Sources/Localization/Resources/ko.lproj/Localizable.strings Sources/Localization/Resources/en.lproj/Localizable.stringsdict Sources/Localization/Resources/ko.lproj/Localizable.stringsdict Tests/AppTests/AppStateTests.swift
git commit -m "feat: localize app state messages and previews"
```

### Task 4: Localize Markdown Report Rendering

**Files:**
- Modify: `Sources/Reporting/MarkdownReportWriter.swift`
- Modify: `Sources/Reporting/ReportFileWriter.swift`
- Modify: `Sources/Localization/Localization.swift`
- Modify: `Sources/Localization/Resources/en.lproj/Localizable.strings`
- Modify: `Sources/Localization/Resources/ko.lproj/Localizable.strings`
- Test: `Tests/CoreTests/WorkspaceReportTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Reporting

@Test func koreanWorkspaceDriftReportUsesTranslatedSections() {
    let writer = MarkdownReportWriter(locale: Locale(identifier: "ko"))
    let markdown = writer.renderWorkspaceDriftSummary(driftItems: [], manualTasks: [])

    #expect(markdown.contains("## 수정됨"))
    #expect(markdown.contains("## 수동 작업"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter WorkspaceReportTests`
Expected: FAIL because the report writer still emits English literals and has no locale-aware initializer.

**Step 3: Write minimal implementation**

Introduce a locale-aware initializer:

```swift
public struct MarkdownReportWriter {
    private let locale: Locale

    public init(locale: Locale = .autoupdatingCurrent) {
        self.locale = locale
    }
}
```

Then replace hard-coded headings and section labels with `L10n` lookups.

**Step 4: Run test to verify it passes**

Run: `swift test --filter WorkspaceReportTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Reporting/MarkdownReportWriter.swift Sources/Reporting/ReportFileWriter.swift Sources/Localization/Localization.swift Sources/Localization/Resources/en.lproj/Localizable.strings Sources/Localization/Resources/ko.lproj/Localizable.strings Tests/CoreTests/WorkspaceReportTests.swift
git commit -m "feat: localize markdown report rendering"
```

### Task 5: Localize Core, Exporter, and Importer User-Facing Text

**Files:**
- Modify: `Sources/Core/PreflightService.swift`
- Modify: `Sources/Core/ManualTaskEngine.swift`
- Modify: `Sources/Core/VerifyEngine.swift`
- Modify: `Sources/Core/ErrorTypes.swift`
- Modify: `Sources/Core/BundlePreviewService.swift`
- Modify: `Sources/Exporters/ExportCoordinator.swift`
- Modify: `Sources/Exporters/HomebrewExporter.swift`
- Modify: `Sources/Exporters/DotfilesExporter.swift`
- Modify: `Sources/Exporters/GitGlobalExporter.swift`
- Modify: `Sources/Exporters/VSCodeExporter.swift`
- Modify: `Sources/Exporters/WorkspacePromoteCoordinator.swift`
- Modify: `Sources/Importers/ImportCoordinator.swift`
- Modify: `Sources/Importers/WorkspaceApplyCoordinator.swift`
- Modify: `Sources/Localization/Localization.swift`
- Modify: `Sources/Localization/Resources/en.lproj/Localizable.strings`
- Modify: `Sources/Localization/Resources/ko.lproj/Localizable.strings`
- Modify: `Sources/Localization/Resources/en.lproj/Localizable.stringsdict`
- Modify: `Sources/Localization/Resources/ko.lproj/Localizable.stringsdict`
- Test: `Tests/CoreTests/CoreBehaviorTests.swift`
- Test: `Tests/ExporterImporterTests/IntegrationTests.swift`

**Step 1: Write the failing test**

```swift
import Foundation
import Testing
@testable import Core

@Test func preflightUsesLocalizedCheckTitles() {
    let service = PreflightService()
    let result = service.run(mode: .export(destination: URL(fileURLWithPath: "/tmp/export")))

    #expect(result.checks.contains(where: { $0.title == "macOS version" }))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter CoreBehaviorTests`
Expected: FAIL once titles and details move behind localization helpers.

**Step 3: Write minimal implementation**

Localize all user-facing strings generated in workflow layers:

- `PreflightCheck.title` and `detail`
- `ManualTask.title`, `reason`, and `action`
- `OperationReport.title`
- `StepResult.title` and `detail`
- `CoreError.localizedDescription`

Keep raw file paths, command output, and manifest identifiers untranslated inside the formatted string values.

**Step 4: Run test to verify it passes**

Run: `swift test --filter CoreBehaviorTests`
Run: `swift test --filter IntegrationTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/Core/PreflightService.swift Sources/Core/ManualTaskEngine.swift Sources/Core/VerifyEngine.swift Sources/Core/ErrorTypes.swift Sources/Core/BundlePreviewService.swift Sources/Exporters/ExportCoordinator.swift Sources/Exporters/HomebrewExporter.swift Sources/Exporters/DotfilesExporter.swift Sources/Exporters/GitGlobalExporter.swift Sources/Exporters/VSCodeExporter.swift Sources/Exporters/WorkspacePromoteCoordinator.swift Sources/Importers/ImportCoordinator.swift Sources/Importers/WorkspaceApplyCoordinator.swift Sources/Localization/Localization.swift Sources/Localization/Resources/en.lproj/Localizable.strings Sources/Localization/Resources/ko.lproj/Localizable.strings Sources/Localization/Resources/en.lproj/Localizable.stringsdict Sources/Localization/Resources/ko.lproj/Localizable.stringsdict Tests/CoreTests/CoreBehaviorTests.swift Tests/ExporterImporterTests/IntegrationTests.swift
git commit -m "feat: localize workflow-generated messages"
```

### Task 6: Update Tests to Assert Behavior, Not Source Literals

**Files:**
- Modify: `Tests/AppTests/AppStateTests.swift`
- Modify: `Tests/CoreTests/WorkspaceReportTests.swift`
- Modify: `Tests/ExporterImporterTests/WorkspaceWorkflowTests.swift`
- Modify: `Tests/ManifestSchemaTests/ManifestTests.swift`

**Step 1: Write the failing test**

```swift
@Test
@MainActor
func contentViewLocalizationDoesNotDependOnInlineEnglishSourceLiterals() throws {
    let sourceRoot = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .deletingLastPathComponent()
    let contentViewURL = sourceRoot.appendingPathComponent("Sources/App/ContentView.swift")
    let content = try String(contentsOf: contentViewURL, encoding: .utf8)

    #expect(content.contains("L10n.string"))
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppStateTests`
Expected: FAIL until tests are rewritten away from inline English assertions.

**Step 3: Write minimal implementation**

Update tests so they validate:

- localized output content for explicit locales
- workflow state transitions
- report generation semantics
- manifest compatibility remains unchanged

Avoid brittle checks that parse source files for English literals.

**Step 4: Run test to verify it passes**

Run: `swift test`
Expected: PASS

**Step 5: Commit**

```bash
git add Tests/AppTests/AppStateTests.swift Tests/CoreTests/WorkspaceReportTests.swift Tests/ExporterImporterTests/WorkspaceWorkflowTests.swift Tests/ManifestSchemaTests/ManifestTests.swift
git commit -m "test: align coverage with localized output"
```

### Task 7: Document Localization Scope and Limitations

**Files:**
- Modify: `README.md`
- Modify: `docs/architecture.md`
- Modify: `docs/plan.md`

**Step 1: Write the failing documentation expectation**

Add a checklist note locally before editing:

- README mentions English/Korean support
- architecture doc explains localization module ownership
- plan doc links to approved design and implementation plan

**Step 2: Verify docs are missing the new details**

Run: `rg -n "Localization|Korean|한국어|English" README.md docs/architecture.md docs/plan.md`
Expected: incomplete or missing coverage.

**Step 3: Write minimal implementation**

Document:

- supported languages
- system-language selection behavior
- localized reports are generated in the current machine language
- older bundle artifacts remain in their original language

**Step 4: Run lightweight verification**

Run: `rg -n "Localization|Korean|한국어|English" README.md docs/architecture.md docs/plan.md`
Expected: matching lines in all three documents.

**Step 5: Commit**

```bash
git add README.md docs/architecture.md docs/plan.md
git commit -m "docs: document localization scope and behavior"
```

### Final Verification

1. Run `swift build` and confirm the package target graph resolves with the new `Localization` module.
2. Run `swift test` and confirm all test targets pass, including new localization coverage.
3. Run `./scripts/check-project-source-drift.sh` and confirm newly added source/resource files are registered.
4. Run `./scripts/xcodebuild-check.sh` and confirm the Xcode project still builds.
5. Manually launch the app once in English and once in Korean system language to verify tab labels, status text, and generated reports.
