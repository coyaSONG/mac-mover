# Dev Environment Control Tower Design

## Goal

Reposition Mac Dev Env Mover from a one-time export/import utility into a local-only macOS GUI control tower for managing a developer environment repo and applying that repo to a Mac.

## Product Model

The app should treat a connected environment repo as the primary source of truth for repeatable setup. The repo can contain:

- `chezmoi`-managed dotfiles or a plain dotfiles structure
- `Brewfile`
- `mise.toml` or `.tool-versions`
- Git global config files
- VS Code settings, keybindings, snippets, and extension declarations

The app should provide four primary operations:

- `Scan`: inspect the connected repo and the current Mac
- `Diff`: calculate drift between repo state and local state
- `Apply`: bring the local machine closer to the repo state
- `Promote`: turn local changes into repo-ready candidates

Existing export/import concepts remain useful, but they become secondary workflow names rather than the product identity.

## Sync Policy

The app should use `repo-first + drift detection`.

- The repo is the deployable source of truth.
- The local machine is the live execution environment.
- The app must not perform automatic bidirectional merge.
- Local drift should be visible before any destructive action.
- Users should explicitly choose to either apply repo changes locally or promote local drift back into the repo.

This model keeps reproducibility high without fighting normal developer behavior.

## Architecture

The current codebase already has reusable building blocks in `Core`, `Reporting`, `Exporters`, `Importers`, and `App`. The redesign should preserve those pieces where possible and add repo-centric layers on top.

### Recommended modules

- `RepoAdapters`
  Detect and parse supported repo conventions such as `chezmoi`, plain dotfiles layouts, `Brewfile`, `mise`, and VS Code files.
- `EnvironmentScanner`
  Read current machine state for the supported categories.
- `DiffEngine`
  Compare repo state and local state to classify drift.
- `ApplyEngine`
  Apply repo state to the local machine with backup-on-overwrite and manual task surfacing.
- `PromoteEngine`
  Gather local-only changes and write repo-ready candidates or previews.
- `VerifyEngine`
  Confirm that post-apply state matches expectations.
- `Reporting`
  Continue generating Markdown summaries and structured artifacts for trust and auditability.
- `App`
  Replace the export/import-focused shell with repo, drift, apply, promote, and reports views.

### Reuse from current implementation

- `Core/FileRestorer.swift` for safe overwrite behavior
- `Core/VerifyEngine.swift` for verification patterns
- `Core/ManualTaskEngine.swift` and `Core/SecretPolicy.swift` for exclusions and manual work
- `Reporting/*` for Markdown report generation
- Existing Homebrew, Git global, VS Code, and dotfile logic as starting points for scanners and adapters

## User Flow

The control tower workflow should be:

1. Connect a repo from a local path or Git URL.
2. Scan the repo and current machine state.
3. View drift grouped by category and severity.
4. Choose `Apply` or `Promote` from a preview screen.
5. Run `Verify` and inspect generated reports.

### Drift categories

- `missing`: defined in repo but missing locally
- `extra`: present locally but missing in repo
- `modified`: present in both places but different
- `manual`: intentionally not automated
- `unsupported`: detected but not yet supported

### Required safety behavior

- Create timestamped `.bak` files before overwriting user-managed files.
- Never auto-copy secrets, tokens, private keys, or keychain contents.
- Require preview before destructive apply operations.
- Surface unsupported work as explicit manual tasks.

## v1 Scope

The control tower v1 should support:

- Homebrew
  - formula
  - cask
  - tap
  - service
  - `Brewfile`-based scan and apply
- Dotfiles
  - `chezmoi` detection first
  - plain repo allowlist fallback
- CLI version management
  - `mise` first
  - `asdf` compatibility later
- Git global config
- VS Code
  - extensions
  - settings
  - keybindings
  - snippets
- Reports
  - scan
  - drift
  - apply
  - promote
  - verify
  - manual tasks

## v1 Non-Goals

- automatic secret transfer
- SSH private key migration
- Docker images, volumes, or containers
- local database data
- JetBrains, Xcode, browser sessions, or license migration
- custom LaunchAgents or LaunchDaemons migration
- repo auto-commit or auto-push
- automatic bidirectional sync

## Data Model

The repo should become the long-term state source. The app should keep lightweight operation artifacts for history and reporting.

### Suggested domain models

- `ConnectedWorkspace`
  - repo path or URL
  - detected tools
  - last scan timestamp
- `EnvironmentSnapshot`
  - local state captured at a point in time
- `RepoSnapshot`
  - normalized state extracted from the repo
- `DriftItem`
  - category
  - identifier
  - repo value
  - local value
  - status
  - suggested resolutions
- `OperationReport`
  - scan, apply, promote, or verify result
- `ManualTask`
  - secret, unsupported, or human-required follow-up

The existing manifest should evolve from an export bundle contract into an operation artifact contract that records what the app observed and attempted.

## Reports

Human-readable reports remain essential.

- `scan-summary.md`
- `drift-summary.md`
- `apply-summary.md`
- `promote-summary.md`
- `verify-summary.md`
- `manual-tasks.md`

These reports should explain what the app detected, what it changed, what it skipped, and what still requires manual action.

## Testing Strategy

Use fixture-driven tests to keep the repo-centric redesign stable.

- Unit tests
  - repo adapter parsing
  - diff classification
  - backup creation
  - manual task generation
- Integration tests
  - sample repo scan
  - apply then verify
  - promote preview generation
- App state tests
  - connected workspace loading
  - drift summary presentation
  - apply and promote flow state transitions

## Migration Notes

- Keep the app buildable after each phase.
- Avoid deleting the current bundle-based code in the first pass.
- Reframe existing exporters and importers as reusable category services while the new repo-centric coordinator is introduced.
- Preserve local-only guarantees and reporting quality throughout the redesign.
