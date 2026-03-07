# Mac Dev Env Mover

Local-only macOS app for recreating a personal developer environment on a new Mac without trying to clone the entire machine.

## Current Status

The repository now covers the Phase 1 foundation through the Phase 3 v1 workflow baseline:

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
- import bundle preview loading for manual tasks, reports, and logs before restore

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
2. `swift run MacMover`

### Xcode

1. Open `MacMover.xcodeproj`
2. Select the `MacMover` scheme or target
3. Build and run on macOS

## Setup

1. Install full Xcode if you want local `xcodebuild` and XCTest execution.
2. Select Xcode as the active developer directory:
   `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
3. Ensure Homebrew, Git, and VS Code are installed on the source or target Mac as needed for the workflows you want to run.
4. If you want VS Code extension restore, install the `code` CLI from inside VS Code.

## Local Checks

- `swift build`
- `swift test`
- `./scripts/check-project-source-drift.sh`
- `./scripts/xcodebuild-check.sh`

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

## Usage Flow

1. Launch the app and review the Overview tab to confirm the current machine metadata.
2. In Export, choose a destination folder and run export to create the bundle, manifest, Brewfile, reports, and logs.
3. Move the exported bundle to the target Mac using your preferred local transfer method.
4. In Import, choose the bundle folder and review preflight results plus manual tasks before running import.
5. After selecting a bundle, use Reports / Logs to preview the existing export, import, and verify summaries plus the latest log preview.
6. Run Import to apply supported items with backups and report generation.
7. Run Verify to regenerate `reports/verify-summary.md` against the target machine state when needed.

## Known Limitations

- v1 stays within Homebrew, dotfiles allowlist, Git global config, and VS Code.
- Secret-like content is excluded by default and must be transferred manually when needed.
- Docker, databases, JetBrains, browser sessions, Keychain, and other non-v1 categories are intentionally unsupported.
- Cross-architecture restores are surfaced with manual guidance, not automatic compatibility fixes.

## Sample Data

- `SampleExportBundle/` contains a sample export bundle
