# Mac Dev Env Mover

Local-only macOS app for recreating a personal developer environment on a new Mac without trying to clone the entire machine.

## Phase 1 Status

Phase 1 establishes the foundation:

- macOS app scaffold with SwiftUI tabs for Overview, Export, Import, and Reports / Logs
- shared manifest domain models for machine metadata, item kinds, restore phases, manual tasks, and reports
- manifest JSON read/write support
- Markdown report generation for preflight and operation summaries
- unit and integration tests for core manifest and filesystem behavior

The repository already contains additional exporter/importer scaffolding, but the Phase 1 baseline is the app shell, manifest contract, reporting, and tests.

## v1 Scope

- Homebrew formula, cask, tap, and service metadata
- dotfiles allowlist
- Git global config
- VS Code extensions, settings, keybindings, and snippets
- export, import, and verify reports

## v1 Non-Goals

- Keychain migration
- passwords, tokens, sessions, or cloud credentials
- SSH private key auto-migration
- Docker images, volumes, or containers
- local database data
- JetBrains support
- Xcode settings sync
- browser sessions or cookies
- app license state migration
- full system settings cloning
- custom LaunchAgents or LaunchDaemons migration
- cloud sync, account systems, or any server backend

## Safety Rules

- Secret-like content is excluded by default.
- Existing files are never silently deleted.
- Overwrites create timestamped `.bak` backups first.
- Unsupported or sensitive items should surface as manual tasks in reports.

## Repo Layout

- `Sources/App` - SwiftUI app shell and app state
- `Sources/SharedModels` - manifest, report, and workflow domain models
- `Sources/Core` - manifest IO, validation, filesystem helpers, restore planning, backup naming, and utilities
- `Sources/Reporting` - Markdown report generation
- `Sources/Exporters` - export orchestration and exporters
- `Sources/Importers` - import orchestration and restorers
- `Tests` - XCTest coverage for Phase 1 behavior and later integration scaffolding
- `spec` - manifest schema and sample manifest
- `docs` - architecture notes, implementation plan, and source product docs

## Documentation

- `docs/architecture.md` - current architecture and data flow
- `docs/plan.md` - Phase 1 implementation plan
- `spec/manifest.schema.json` - manifest contract
- `spec/manifest.sample.json` - sample manifest payload

## Build and Run

### SwiftPM

1. `swift build`
2. `swift run MacDevEnvMover`

### Xcode

1. Open `MacDevEnvMover.xcodeproj`
2. Select the `MacDevEnvMover` scheme or target
3. Build and run on macOS

## Local Checks

- `swift build`
- `swift test`
- `./scripts/xcodebuild-check.sh`

With Command Line Tools only, `swift test` compiles the test targets but does not execute the XCTest cases. Full Xcode is required to run the test suite.

`xcodebuild` requires full Xcode. If the machine is using Command Line Tools only, select full Xcode first:

`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## Export Bundle Shape

- `manifest.json`
- `Brewfile`
- `files/dotfiles/...`
- `files/vscode/settings.json`
- `files/vscode/keybindings.json`
- `files/vscode/snippets/...`
- `reports/export-summary.md`
- `reports/verify-summary.md` (placeholder until import/verify runs on the target machine)
- `logs/*.jsonl`

After import runs on the target machine, the bundle also contains `reports/import-summary.md`.

## Sample Data

- `SampleExportBundle/` contains a sample export bundle
