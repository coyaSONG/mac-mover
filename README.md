# Mac Dev Env Mover

Local-only macOS app for managing a developer environment repo and recreating that environment on a Mac without trying to clone the entire machine.

## Current Status

The repository now covers the repo-first control tower baseline plus the legacy bundle compatibility flow:

- macOS app scaffold with SwiftUI tabs for Overview, Repo, Drift, Export, Import, and Reports
- shared manifest domain models for machine metadata, item kinds, restore phases, manual tasks, and reports
- manifest JSON read/write support
- Preflight checks for macOS version, CPU architecture, home directory, Homebrew, brew prefix, git, VS Code, `code`, and target path writeability
- repo workspace detection for `chezmoi`, plain dotfiles, `Brewfile`, `mise`, `.tool-versions`, and VS Code repo files
- local environment scanning plus drift calculation for Homebrew, dotfiles, Git global config, VS Code, and tool versions
- workspace apply/promote previews with backup-on-overwrite and manual secret handling
- Homebrew export/import through Brewfile plus formula, cask, tap, and service manifest items for legacy bundle compatibility
- dotfile export/import through the allowlist in `Sources/Core/DotfileAllowlist.swift` for legacy bundle compatibility
- Git global config export/import for legacy bundle compatibility
- backup-on-overwrite with timestamped `.bak` files
- Markdown report generation for workspace scan/drift plus legacy export/import/verify summaries
- unit and integration tests for preflight, manifest, restore safety, and exporter/importer behavior
- import bundle preview loading for manual tasks, reports, and logs before restore

## v1 Scope

- repo-first workspace scan/drift/reporting for supported dev-environment files
- Homebrew formula, cask, tap, and service metadata
- dotfiles allowlist plus minimal `chezmoi` compatibility
- tool version detection for `mise` and `.tool-versions`
- Git global config
- VS Code extensions, settings, keybindings, and snippets
- workspace scan, drift, apply preview, promote preview, export, import, and verify reports

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
- `Sources/Core` - preflight, manifest IO, validation, workspace detection/scanning, drift logic, filesystem helpers, restore planning, backup naming, and utilities
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

1. Launch the app and review the Overview tab to confirm the current machine metadata plus current workspace state.
2. In Repo, connect a local dev-environment repo and run a workspace scan.
3. Review Drift to see missing, extra, modified, manual, and unsupported items plus apply/promote previews.
4. Use Reports to inspect workspace scan/drift summaries and the legacy export/import/verify reports when present.
5. Use Export and Import when you need legacy bundle creation or same-category machine restore compatibility.
6. Run Verify against a selected legacy bundle when needed.

## Legacy Bundle Compatibility

The app still preserves the original bundle-based flow for same-category migration support:

1. In Export, choose a destination folder and run export to create the legacy bundle, manifest, Brewfile, reports, and logs.
2. Move the exported bundle to the target Mac using your preferred local transfer method.
3. In Import, choose the bundle folder and review preflight results plus manual tasks before running import.
4. Use Reports to preview the existing export, import, and verify summaries plus the latest log preview.
5. Run Import and Verify for legacy bundle restore and validation.

## Known Limitations

- v1 stays within Homebrew, dotfiles, Git global config, VS Code, and lightweight tool-version detection.
- The repo control tower currently supports apply/promote previews first; the full selection-driven control flow is still being built out.
- Secret-like content is excluded by default and must be transferred manually when needed.
- Docker, databases, JetBrains, browser sessions, Keychain, and other non-v1 categories are intentionally unsupported.
- Cross-architecture restores are surfaced with manual guidance, not automatic compatibility fixes.

## Sample Data

- `SampleExportBundle/` contains a legacy compatibility sample bundle artifact, not the primary repo-first workflow
