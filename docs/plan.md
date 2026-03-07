# Implementation Plan

## Goal

Deliver Mac Dev Env Mover incrementally while keeping scope limited to the v1 categories and preserving local-only safety defaults.

## Completed

### Phase 1

1. Keep the macOS app scaffold and SwiftUI shell aligned with the requested sections.
2. Ensure the shared manifest models cover machine metadata, item kinds, restore phases, manual tasks, and reports.
3. Verify manifest read/write support through `ManifestStore`.
4. Keep Markdown reporting focused on readable export, import, and verify summaries.
5. Maintain test coverage for core manifest and filesystem utilities.
6. Document the repository architecture, scope, and local verification boundaries.

### Phase 2

1. Add preflight checks for machine compatibility and destination writeability.
2. Support Homebrew export/import through Brewfile and manifest items.
3. Support dotfile export/import through the allowlist.
4. Support Git global config export/import.
5. Keep backup-on-overwrite and manual task generation visible in reports.
6. Expand tests for preflight checks, overwrite backups, Brewfile output, and report generation.

### Phase 3

1. Support VS Code export/import for settings, keybindings, snippets, and extensions.
2. Keep verify coverage for Brew, dotfiles, Git global config, and VS Code extensions.
3. Surface export/import/verify reports plus logs through the SwiftUI shell.
4. Load selected import bundles into a preview state before restore so preflight checks and manual tasks are visible.
5. Maintain sample bundle data and broaden tests for verify and partial-failure reporting.
6. Finalize README usage flow, setup notes, and scope boundaries for the v1 baseline.

## Remaining Focus

- Docker, JetBrains, Keychain, browser sessions, cloud sync
- automatic secret transfer
- broadening support beyond the existing v1 categories
- redesigning later-phase exporter or importer behavior before the next prompt

## Optional Cleanup

No open optional cleanup items are tracked right now.

## Verification

- `swift build`
- `swift test`
- `./scripts/check-project-source-drift.sh`
- `./scripts/xcodebuild-check.sh`

## Current Verification Task

1. Run `swift build` and capture success or failure plus any warnings emitted by the compiler.
2. Run `swift test` and confirm all four test targets execute successfully: `CoreTests`, `ExporterImporterTests`, `ManifestSchemaTests`, and `AppTests`.
3. If either command fails, fix the reported issue with the smallest reviewable change.
4. Re-run `swift build` and `swift test` after each fix until both pass cleanly.
5. Summarize final status as `[pass]`, `[fail]`, or `[blocked]` for build, tests, and warning inventory.
