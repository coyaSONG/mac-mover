<div align="center">

# MacMover

**Recreate your dev environment on a new Mac — without cloning the whole machine.**

[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-black?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift 6.2](https://img.shields.io/badge/Swift-6.2-F05138?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-blue?logo=swift&logoColor=white)](https://developer.apple.com/xcode/swiftui/)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

A native macOS app that scans your dev environment repo, detects drift from your local machine, and helps you apply or export changes — all locally, with no cloud or account required.

</div>

---

## Features

- **Repo-first workflow** — Connect a dev-environment repo (chezmoi, plain dotfiles, Brewfile, mise, etc.) and use it as the source of truth
- **Drift detection** — See what's missing, extra, modified, or needs manual action compared to your repo
- **Apply & promote previews** — Preview exactly what will change before applying repo state to your machine or promoting local changes back
- **Homebrew** — Formulas, casks, taps, and services via Brewfile
- **Dotfiles** — Curated allowlist with chezmoi compatibility
- **Git global config** — `.gitconfig` export and restore
- **VS Code** — Extensions, settings, keybindings, and snippets
- **Tool versions** — `mise` and `.tool-versions` detection
- **Safe by default** — Secrets excluded, overwrites create `.bak` backups, no silent deletes
- **Legacy bundle export/import** — Full bundle-based migration for same-category machines
- **Markdown reports** — Workspace scan, drift, export, import, and verify summaries

## Quick Start

### Using SwiftPM

```bash
swift build
swift run MacMover
```

### Using Xcode

1. Open `MacMover.xcodeproj`
2. Select the **MacMover** scheme
3. Build & Run (macOS)

### Prerequisites

| Requirement | Notes |
|---|---|
| Xcode (full) | Required for `xcodebuild` and tests |
| Homebrew | For Homebrew-related workflows |
| Git | For Git global config and repo detection |
| VS Code + `code` CLI | For VS Code extension management |

> **Tip:** If you're on Command Line Tools only, switch to full Xcode:
> ```bash
> sudo xcode-select -s /Applications/Xcode.app/Contents/Developer
> ```

## How It Works

```
┌─────────────────────────────────────────────────┐
│                   MacMover App                  │
├──────────┬──────────┬───────────┬───────────────┤
│ Overview │   Repo   │   Drift   │    Reports    │
├──────────┴──────────┴───────────┴───────────────┤
│                                                 │
│  1. Connect your dev-environment repo           │
│  2. Scan workspace sources                      │
│  3. Detect drift against local machine          │
│  4. Preview & apply changes                     │
│                                                 │
│  ┌─────────────┐    ┌──────────────────┐        │
│  │  Your Repo  │◄──►│  Local Machine   │        │
│  │  (dotfiles, │    │  (Homebrew, git,  │        │
│  │  Brewfile,  │    │   VS Code, etc.) │        │
│  │  mise, etc.)│    │                  │        │
│  └─────────────┘    └──────────────────┘        │
└─────────────────────────────────────────────────┘
```

## Project Structure

```
Sources/
├── App/             # SwiftUI app shell and state
├── SharedModels/    # Manifest, report, and workflow models
├── Core/            # Preflight, scanning, drift, backup, utilities
├── Reporting/       # Markdown report generation
├── Exporters/       # Export orchestration
└── Importers/       # Import orchestration

Tests/               # XCTest coverage (Core, Exporters, Importers, Manifest, App)
spec/                # Manifest JSON schema and sample
docs/                # Architecture and implementation plans
```

## Running Tests

```bash
swift build
swift test
```

Additional project checks:

```bash
./scripts/check-project-source-drift.sh
./scripts/xcodebuild-check.sh
```

## Safety & Security

MacMover is designed with safety as a hard constraint:

- Secret-like content (tokens, private keys, credentials) is **excluded by default**
- Existing files are **never silently deleted**
- Every overwrite creates a **timestamped `.bak` backup** first
- Unsupported or sensitive items surface as **manual tasks** in reports
- **No cloud, no accounts, no network** — everything stays on your machine

## Non-Goals (v1)

MacMover intentionally does **not** handle:

Keychain / passwords / tokens / SSH keys — Docker — databases — JetBrains — Xcode settings — browser sessions — app licenses — system settings — LaunchAgents / LaunchDaemons — cloud sync

## Documentation

| Doc | Description |
|---|---|
| [`docs/architecture.md`](docs/architecture.md) | Architecture and data flow |
| [`docs/plan.md`](docs/plan.md) | Implementation plan and phase status |
| [`spec/manifest.schema.json`](spec/manifest.schema.json) | Manifest JSON schema |
| [`spec/manifest.sample.json`](spec/manifest.sample.json) | Sample manifest payload |

## Contributing

1. Fork the repo
2. Create a feature branch
3. Make sure `swift build` and `swift test` pass
4. Submit a PR

## License

MIT
