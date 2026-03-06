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

## Remaining Focus

- Docker, JetBrains, Keychain, browser sessions, cloud sync
- automatic secret transfer
- broadening support beyond the existing v1 categories
- redesigning later-phase exporter or importer behavior before the next prompt

## Verification

- `swift build`
- `swift test`
- `./scripts/xcodebuild-check.sh`

In a Command Line Tools-only environment, `swift test` is expected to compile the test bundle without executing XCTest cases.
