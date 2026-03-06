# Phase 1 Implementation Plan

## Goal

Deliver the app foundation for Mac Dev Env Mover without expanding into unsupported migration categories or secret handling.

## Planned Work

1. Keep the existing macOS app scaffold and SwiftUI shell aligned with the requested Phase 1 sections.
2. Ensure the shared manifest models cover the schema fields needed for machine metadata, item kinds, restore phases, manual tasks, and reports.
3. Verify manifest read/write support through `ManifestStore`.
4. Keep Markdown report generation in `Reporting` focused on readable export, import, and verify summaries.
5. Keep the XCTest suite in place for full Xcode environments and cover the required Phase 1 utilities.
6. Add the missing Phase 1 docs: `docs/architecture.md` and this plan file.
7. Refresh `README.md` so the repository documents Phase 1 scope, safety boundaries, and local verification commands.

## Out of Scope For This Phase

- Docker, JetBrains, Keychain, browser sessions, cloud sync
- automatic secret transfer
- broadening support beyond the existing v1 categories
- redesigning later-phase exporter or importer behavior

## Verification

- `swift build`
- `swift test`
- `./scripts/xcodebuild-check.sh`

In a Command Line Tools-only environment, `swift test` is expected to compile the test bundle without executing XCTest cases.
