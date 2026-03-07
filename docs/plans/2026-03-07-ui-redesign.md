# UI Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Redesign the MacMover SwiftUI app from MVP GroupBox UI to polished material card UI with semantic colors, SF Symbol badges, progress indicators, and functional animations.

**Architecture:** Extract the monolithic ContentView.swift into separate tab files, shared theme/components, and a reusable CardView. All GroupBox instances replaced with material-backed cards. Preflight checks get icon+color badges. Export/Import get progress overlays. Reports get collapsible sections.

**Tech Stack:** SwiftUI, SF Symbols, SwiftUI Material (.regularMaterial), Swift Testing

---

### Task 1: Add AppState.isRunning property

AppState needs an `isRunning` bool so the UI can show progress overlays and disable buttons during export/import/verify.

**Files:**
- Modify: `Sources/App/AppState.swift`
- Test: `Tests/AppTests/AppStateTests.swift`

**Step 1: Write failing test**

Add to `Tests/AppTests/AppStateTests.swift`:

```swift
@Test
@MainActor
func isRunningDefaultsToFalse() {
    let appState = AppState(machineSummaryProvider: { "test" })
    #expect(appState.isRunning == false)
}
```

**Step 2: Run test to verify it fails**

Run: `swift test --filter AppTests`
Expected: FAIL - `AppState` has no member `isRunning`

**Step 3: Write minimal implementation**

In `Sources/App/AppState.swift`, add after the `statusMessage` property (line 21):

```swift
@Published var isRunning: Bool = false
```

Then wrap the async work in `runExport()`, `runImport()`, and `runVerify()` with:

```swift
// At start of Task block:
isRunning = true
defer { isRunning = false }
```

**Step 4: Run test to verify it passes**

Run: `swift test --filter AppTests`
Expected: PASS

**Step 5: Commit**

```bash
git add Sources/App/AppState.swift Tests/AppTests/AppStateTests.swift
git commit -m "feat: add isRunning property to AppState for progress UI"
```

---

### Task 2: Create Theme/AppColors.swift

**Files:**
- Create: `Sources/App/Theme/AppColors.swift`

**Step 1: Create the file**

```swift
import SwiftUI

extension Color {
    static let appAccent = Color.accentColor
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appDanger = Color.red
    static let appMuted = Color.secondary
}
```

**Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Theme/AppColors.swift
git commit -m "feat: add semantic color extensions"
```

---

### Task 3: Create Theme/CardView.swift

**Files:**
- Create: `Sources/App/Theme/CardView.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct CardView<Content: View>: View {
    let title: String?
    let icon: String?
    @ViewBuilder let content: () -> Content

    init(title: String? = nil, icon: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                HStack(spacing: 6) {
                    if let icon {
                        Image(systemName: icon)
                            .foregroundStyle(Color.appAccent)
                    }
                    Text(title).font(.headline)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Theme/CardView.swift
git commit -m "feat: add reusable CardView with material background"
```

---

### Task 4: Create Components/StatusBadge.swift

**Files:**
- Create: `Sources/App/Components/StatusBadge.swift`

**Step 1: Create the file**

```swift
import SwiftUI
import SharedModels

struct StatusBadge: View {
    let check: PreflightCheck

    private var icon: String {
        if check.passed { return "checkmark.circle.fill" }
        return check.blocking ? "xmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var color: Color {
        if check.passed { return .appSuccess }
        return check.blocking ? .appDanger : .appWarning
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 2) {
                Text(check.title)
                    .font(.body)
                Text(check.detail)
                    .font(.caption)
                    .foregroundStyle(.appMuted)
            }
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Components/StatusBadge.swift
git commit -m "feat: add StatusBadge component for preflight checks"
```

---

### Task 5: Create Components/ManualTaskRow.swift

**Files:**
- Create: `Sources/App/Components/ManualTaskRow.swift`

**Step 1: Create the file**

```swift
import SwiftUI
import SharedModels

struct ManualTaskRow: View {
    let task: ManualTask

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: task.blocking ? "exclamationmark.circle.fill" : "info.circle.fill")
                .foregroundStyle(task.blocking ? Color.appDanger : Color.appMuted)
                .imageScale(.medium)
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(.body)
                Text(task.reason)
                    .font(.caption)
                    .foregroundStyle(.appMuted)
                Text(task.action)
                    .font(.caption)
                    .foregroundStyle(.appAccent)
            }
        }
    }
}
```

**Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Components/ManualTaskRow.swift
git commit -m "feat: add ManualTaskRow component"
```

---

### Task 6: Create Components/ProgressOverlay.swift

**Files:**
- Create: `Sources/App/Components/ProgressOverlay.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct ProgressOverlay: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.large)
            Text(message)
                .font(.callout)
                .foregroundStyle(.appMuted)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
```

**Step 2: Build to verify it compiles**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Components/ProgressOverlay.swift
git commit -m "feat: add ProgressOverlay component"
```

---

### Task 7: Create Tabs/OverviewTab.swift

Extract and redesign the Overview tab from ContentView.swift.

**Files:**
- Create: `Sources/App/Tabs/OverviewTab.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct OverviewTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: "App Overview", icon: "info.circle") {
                    Text("Recreate a personal development environment (Homebrew, allowlisted dotfiles, Git global config, and VS Code) on a new Mac via export/import.")
                }

                CardView(title: "Current Machine", icon: "desktopcomputer") {
                    VStack(alignment: .leading, spacing: 8) {
                        machineRow(icon: "network", label: "Host", value: appState.machineHost)
                        machineRow(icon: "cpu", label: "Architecture", value: appState.machineArch)
                        machineRow(icon: "apple.logo", label: "macOS", value: appState.machineOS)
                        machineRow(icon: "house", label: "Home", value: appState.machineHome)
                        machineRow(icon: "mug", label: "Brew Prefix", value: appState.machineBrewPrefix)
                    }
                }

                CardView(title: "Recent Runs", icon: "clock") {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(appState.lastExportBundleURL?.path ?? "No export yet", systemImage: "square.and.arrow.up")
                            .foregroundStyle(appState.lastExportBundleURL != nil ? .primary : .appMuted)
                        Label(appState.lastImportBundleURL?.path ?? "No import yet", systemImage: "square.and.arrow.down")
                            .foregroundStyle(appState.lastImportBundleURL != nil ? .primary : .appMuted)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func machineRow(icon: String, label: String, value: String) -> some View {
        Label {
            HStack {
                Text(label)
                    .foregroundStyle(.appMuted)
                    .frame(width: 100, alignment: .leading)
                Text(value)
                    .textSelection(.enabled)
            }
        } icon: {
            Image(systemName: icon)
                .foregroundStyle(.appAccent)
                .frame(width: 20)
        }
    }
}
```

Note: This requires adding computed properties to AppState for individual machine fields. See Task 8.

**Step 2: Build (will fail until Task 8)**

Expected: Build fails - AppState missing machineHost etc.

---

### Task 8: Add machine info computed properties to AppState

The Overview tab needs individual machine fields instead of the single `machineSummary` string.

**Files:**
- Modify: `Sources/App/AppState.swift`

**Step 1: Add computed properties**

Add after the `machineSummary` property in AppState:

```swift
var machineHost: String { machineInfo?.hostname ?? "Unknown" }
var machineArch: String { machineInfo?.architecture.rawValue ?? "Unknown" }
var machineOS: String { machineInfo?.macosVersion ?? "Unknown" }
var machineHome: String { machineInfo?.homeDirectory ?? "Unknown" }
var machineBrewPrefix: String { machineInfo?.homebrewPrefix ?? "Unknown" }
```

Add a stored property:

```swift
@Published private(set) var machineInfo: MachineInfo?
```

Update `init` to also store the machine info:

```swift
let info = MachineInfoCollector().collect()
machineInfo = info
machineSummary = "Host: \(info.hostname)\nArchitecture: \(info.architecture.rawValue)\nmacOS: \(info.macosVersion)\nHome: \(info.homeDirectory)\nBrew Prefix: \(info.homebrewPrefix)"
```

But keep `machineSummaryProvider` for test injection. Add an optional `MachineInfo?` to the init:

```swift
init(
    // ... existing params ...
    initialMachineInfo: MachineInfo? = nil
) {
    // ... existing setup ...
    if let initialMachineInfo {
        machineInfo = initialMachineInfo
        machineSummary = // build from initialMachineInfo
    } else {
        let info = MachineInfoCollector().collect()
        machineInfo = info
        machineSummary = machineSummaryProvider()
    }
}
```

Actually, simpler approach: parse the existing `machineSummary` string is fragile. Instead, just collect MachineInfo directly:

```swift
@Published private(set) var machineInfo: MachineInfo?

// Keep machineSummary for backward compat with existing tests/tabs
var machineHost: String { machineInfo?.hostname ?? "Unknown" }
var machineArch: String { machineInfo?.architecture.rawValue ?? "Unknown" }
var machineOS: String { machineInfo?.macosVersion ?? "Unknown" }
var machineHome: String { machineInfo?.homeDirectory ?? "Unknown" }
var machineBrewPrefix: String { machineInfo?.homebrewPrefix ?? "Unknown" }
```

In init, add after `machineSummary = machineSummaryProvider()`:

```swift
machineInfo = MachineInfoCollector().collect()
```

For tests, add an `initialMachineInfo` parameter with nil default, and set `machineInfo = initialMachineInfo` when provided. Skip the collector call in that case.

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeded

**Step 3: Run existing tests**

Run: `swift test --filter AppTests`
Expected: PASS (existing test still works)

**Step 4: Commit**

```bash
git add Sources/App/AppState.swift Sources/App/Tabs/OverviewTab.swift
git commit -m "feat: add OverviewTab with machine info cards"
```

---

### Task 9: Create Tabs/ExportTab.swift

**Files:**
- Create: `Sources/App/Tabs/ExportTab.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct ExportTab: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                CardView(title: "Export Destination", icon: "folder") {
                    HStack {
                        TextField("Export path", text: $appState.exportPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse", action: appState.chooseExportFolder)
                    }
                    Button(action: appState.runExport) {
                        Label("Run Export", systemImage: "square.and.arrow.up")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .disabled(appState.isRunning)
                }
                .overlay {
                    if appState.isRunning && appState.statusMessage.contains("Export") {
                        ProgressOverlay(message: appState.statusMessage)
                    }
                }

                if appState.exportSummary != "No export executed" {
                    CardView(title: "Summary", icon: "doc.text") {
                        ScrollView {
                            Text(appState.exportSummary)
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 300)
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Tabs/ExportTab.swift
git commit -m "feat: add ExportTab with material cards and progress overlay"
```

---

### Task 10: Create Tabs/ImportTab.swift

**Files:**
- Create: `Sources/App/Tabs/ImportTab.swift`

**Step 1: Create the file**

```swift
import SwiftUI

struct ImportTab: View {
    @EnvironmentObject private var appState: AppState

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

                if !appState.preflightChecks.isEmpty {
                    CardView(title: "Preflight Results", icon: "checklist") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(appState.preflightChecks, id: \.id) { check in
                                StatusBadge(check: check)
                            }
                        }
                    }
                }

                if !appState.manualTasks.isEmpty {
                    CardView(title: "Manual Tasks", icon: "hand.raised") {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(appState.manualTasks, id: \.id) { task in
                                ManualTaskRow(task: task)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Tabs/ImportTab.swift
git commit -m "feat: add ImportTab with status badges and manual task rows"
```

---

### Task 11: Create Tabs/ReportsTab.swift

**Files:**
- Create: `Sources/App/Tabs/ReportsTab.swift`

**Step 1: Create the file**

```swift
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
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeded

**Step 3: Commit**

```bash
git add Sources/App/Tabs/ReportsTab.swift
git commit -m "feat: add ReportsTab with collapsible disclosure groups"
```

---

### Task 12: Rewrite ContentView.swift as tab container

Replace the monolithic ContentView with a slim container that references the new tab files. Remove the old inline tab structs.

**Files:**
- Modify: `Sources/App/ContentView.swift`

**Step 1: Replace ContentView.swift entirely**

```swift
import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(spacing: 0) {
            header
            TabView {
                OverviewTab()
                    .tabItem { Label("Overview", systemImage: "house") }
                ExportTab()
                    .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                ImportTab()
                    .tabItem { Label("Import", systemImage: "square.and.arrow.down") }
                ReportsTab()
                    .tabItem { Label("Reports", systemImage: "doc.text") }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .frame(minWidth: 900, minHeight: 620)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("MacMover")
                    .font(.title2)
                    .bold()
                Text(appState.statusMessage)
                    .font(.callout)
                    .foregroundStyle(.appMuted)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.2), value: appState.statusMessage)
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 4)
    }
}
```

**Step 2: Build to verify**

Run: `swift build`
Expected: Build succeeded

**Step 3: Run all tests**

Run: `swift test`
Expected: All tests PASS

**Step 4: Commit**

```bash
git add Sources/App/ContentView.swift
git commit -m "refactor: slim ContentView to tab container only"
```

---

### Task 13: Add animations

Add staggered card entrance animation to each tab and symbol effects to StatusBadge.

**Files:**
- Modify: `Sources/App/Tabs/OverviewTab.swift`
- Modify: `Sources/App/Tabs/ExportTab.swift`
- Modify: `Sources/App/Tabs/ImportTab.swift`
- Modify: `Sources/App/Components/StatusBadge.swift`

**Step 1: Add appear animation to OverviewTab**

In OverviewTab, add a `@State private var appeared = false` property. Wrap each CardView with `.opacity(appeared ? 1 : 0).offset(y: appeared ? 0 : 10)`. Add `.onAppear { withAnimation(.easeOut(duration: 0.3)) { appeared = true } }` to the outer VStack.

Apply same pattern to ExportTab and ImportTab.

**Step 2: Add symbol effect to StatusBadge**

In StatusBadge, add to the Image:
```swift
.symbolEffect(.bounce, value: check.passed)
```

**Step 3: Build and run**

Run: `swift build`
Expected: Build succeeded

**Step 4: Commit**

```bash
git add Sources/App/Tabs/ Sources/App/Components/StatusBadge.swift
git commit -m "feat: add functional animations to tabs and status badges"
```

---

### Task 14: Clean up MacMoverApp.swift

Remove the `NSApplication.shared.activate` workaround that was added for `swift run` — Xcode handles activation.

**Files:**
- Modify: `Sources/App/MacMoverApp.swift`

**Step 1: Simplify the file**

```swift
import SwiftUI

@main
struct MacMoverApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .defaultSize(width: 960, height: 700)
    }
}
```

**Step 2: Build and run all tests**

Run: `swift test`
Expected: All tests PASS

**Step 3: Commit**

```bash
git add Sources/App/MacMoverApp.swift
git commit -m "chore: remove swift-run activation workaround"
```

---

### Task 15: Final verification

**Step 1: Run full test suite**

Run: `swift test`
Expected: All tests PASS

**Step 2: Open in Xcode and run**

Run: `open Package.swift`
Select MacMover scheme, Cmd+R. Verify:
- All 4 tabs render with material cards
- Overview shows machine info with SF Symbol labels
- Export shows path field, browse, prominent run button
- Import shows status badges with colored icons
- Reports shows collapsible disclosure groups
- Dark mode works (System Settings > Appearance > Dark)
- Animations play on tab switch

**Step 3: Final commit if any fixes needed**

```bash
git add -A
git commit -m "fix: final UI polish adjustments"
```
