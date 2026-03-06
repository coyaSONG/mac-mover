# Mac Dev Env Mover (v1)

Local, single-user macOS app to export/import a personal development environment.

## Scope (v1)
- Homebrew: formula, cask, tap, service
- Dotfiles (allowlist only)
- Git global config
- VS Code: extensions, user settings, keybindings, snippets
- Export/Import/Verify markdown reports
- Manual task surfacing for unsupported or blocked steps

## Out of Scope (v1)
- Keychain content transfer
- Password/token/session migration
- Automatic SSH private key transfer
- Docker image/volume/container state
- Local database data
- JetBrains/Xcode/browser session migration
- System-wide macOS clone behavior

## Safety Policy
- Secret-like paths are excluded from automatic transfer.
- Existing files are never destructively deleted.
- On overwrite, a timestamped `.bak` file is created first.
- Partial failures are recorded and execution continues where possible.

## Project Structure
- `Sources/App` - SwiftUI app (Overview/Export/Import/Reports)
- `Sources/Core` - command runner, filesystem, preflight, manifest IO, validation, restore utilities
- `Sources/Exporters` - export orchestration and component exporters
- `Sources/Importers` - import orchestration and apply/verify flow
- `Sources/Reporting` - markdown report generation
- `Sources/SharedModels` - manifest/report/preflight domain models
- `Tests/*` - unit and integration tests (XCTest-gated)

## Build and Run
### SwiftPM
1. `swift build`
2. `swift run MacDevEnvMover`

### Xcode Project
1. Open `MacDevEnvMover.xcodeproj`
2. Select `MacDevEnvMover` target
3. Build/Run

## Automation
- `make build` - `swift build`
- `make test` - `swift test`
- `make ci` - Swift build/test + xcodebuild checks
- `./scripts/ci.sh` - same as CI local runner
- `./scripts/xcodebuild-check.sh` - app/test target build with `xcodebuild`

`xcodebuild` checks require full Xcode, not only Command Line Tools.
If full Xcode is installed, set:
`sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`

## GitHub Actions
- Workflow: `.github/workflows/macos-ci.yml`
- Runs on `macos-14`
- Executes `swift build`, `swift test`, and `scripts/xcodebuild-check.sh`

## Export Bundle Layout
- `manifest.json`
- `Brewfile`
- `files/dotfiles/...`
- `files/vscode/settings.json`
- `files/vscode/keybindings.json`
- `files/vscode/snippets/...`
- `reports/export-summary.md`
- `reports/import-summary.md` (after import)
- `reports/verify-summary.md`
- `logs/*.jsonl`

## Sample Bundle
- `SampleExportBundle/`

## Test Notes
Test files are included for:
- manifest encode/decode
- schema compatibility
- restore plan ordering
- dotfile backup naming
- path normalization
- manual task generation
- report generation
- parser/integration behavior via mock command runner

This environment uses Command Line Tools, so runtime test execution may be limited. In full Xcode environments, tests are available under the test target.
