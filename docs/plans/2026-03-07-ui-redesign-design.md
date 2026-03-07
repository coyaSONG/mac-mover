# MacMover UI Redesign Design

## Goal

Redesign the MacMover macOS SwiftUI app from MVP-level UI to a polished, professional utility app following 2025-2026 macOS design trends.

## Direction

- Utility app style: tab-based with material cards
- SwiftUI Material (`.regularMaterial`) for glassmorphic card backgrounds
- Semantic color system for status indicators
- Functional animations for state changes
- Dark/light mode via system automatic handling

## File Structure

```
Sources/App/
  MacMoverApp.swift
  AppState.swift
  ContentView.swift              (tab container only)
  Theme/
    AppColors.swift              (semantic color extensions)
    CardView.swift               (reusable material card component)
  Tabs/
    OverviewTab.swift
    ExportTab.swift
    ImportTab.swift
    ReportsTab.swift
  Components/
    StatusBadge.swift            (preflight check icon+color badge)
    ManualTaskRow.swift          (manual task row)
    ProgressOverlay.swift        (export/import progress indicator)
```

## Design Tokens

```swift
extension Color {
    static let appAccent = Color.accentColor
    static let appSuccess = Color.green
    static let appWarning = Color.orange
    static let appDanger = Color.red
    static let appMuted = Color.secondary
}
```

System colors only. No custom hex values. Dark/light automatic.

## CardView Component

Replaces all GroupBox instances:

- `.regularMaterial` background
- 12pt corner radius
- 16pt padding
- Optional title with SF Symbol icon
- Full-width layout

## Tab Designs

### Overview
- App description card (concise)
- Current Machine card: Label rows with SF Symbols (desktopcomputer, cpu, apple.logo)
- Recent Runs card: icon + date, muted text if none

### Export
- Path selection card: TextField + Browse button
- Run Export button: `.borderedProminent`, full width
- Progress: ProgressView + status text overlay during execution
- Summary card: monospaced report after completion

### Import
- Path selection + Browse/Run Import/Run Verify buttons in top card
- Preflight Results card: StatusBadge per check
  - Pass: green checkmark.circle.fill
  - Warn: orange exclamationmark.triangle.fill
  - Block: red xmark.circle.fill
- Manual Tasks card: ManualTaskRow with blocking badge

### Reports
- DisclosureGroup cards for Export/Import/Verify/Logs
- Export expanded by default, others collapsed
- Monospaced font + text selection preserved

## Animations

- Tab transition: `.easeInOut(duration: 0.2)` fade
- Card entrance: staggered fade-in from top (0.05s delay each)
- Progress: `.transition(.opacity)`, checkmark on completion
- Preflight rows: sequential appear + `.symbolEffect(.bounce)`
- Status message: `.contentTransition(.numericText())`

All animations are functional (communicate state changes), not decorative.

## Dark/Light Mode

No extra work needed. `.regularMaterial` and system colors auto-adapt.
macOS 26 Liquid Glass applies to window chrome automatically.

## Summary

| Area | Current | New |
|------|---------|-----|
| File structure | 1 file (ContentView.swift) | 9 files separated by concern |
| Container | GroupBox | Material card (CardView) |
| Colors | None defined | 4 semantic colors |
| Preflight | Text [OK]/[WARN]/[BLOCK] | SF Symbol + color badge |
| Progress | None | ProgressView overlay |
| Reports | 4 stacked GroupBox | DisclosureGroup collapsible |
| Animation | None | Tab, card, status transitions |
| Dark/Light | Default | System automatic |
