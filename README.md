# Mac Dev Env Mover

Local-only macOS app for recreating a personal developer environment on a new Mac without trying to clone the entire machine.

## Current Status

The repository now covers the Phase 1 foundation plus the Phase 2 workflow baseline:

- macOS app scaffold with SwiftUI tabs for Overview, Export, Import, and Reports / Logs
- shared manifest domain models for machine metadata, item kinds, restore phases, manual tasks, and reports
- manifest JSON read/write support
- Preflight checks for macOS version, CPU architecture, home directory, Homebrew, brew prefix, git, VS Code, `code`, and target path writeability
- Homebrew export/import through Brewfile plus formula, cask, tap, and service manifest items
- dotfile export/import through the allowlist in `Sources/Core/DotfileAllowlist.swift`
- Git global config export/import
- backup-on-overwrite with timestamped `.bak` files
- Markdown report generation for preflight, export, import, and verify summaries
- unit and integration tests for preflight, manifest, restore safety, and exporter/importer behavior

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
- `Sources/Core` - preflight, manifest IO, validation, filesystem helpers, restore planning, backup naming, and utilities
- `Sources/Reporting` - Markdown report generation
- `Sources/Exporters` - export orchestration and exporters
- `Sources/Importers` - import orchestration and restorers
- `Tests` - XCTest coverage for current core behavior and integration scaffolding
- `spec` - manifest schema and sample manifest
- `docs` - architecture notes, implementation plan, and source product docs

## Documentation

- `docs/architecture.md` - current architecture and data flow
- `docs/plan.md` - current implementation plan and phase status
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
