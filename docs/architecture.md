# Mac Dev Env Mover Architecture

## Goal

Mac Dev Env Mover is a native macOS app that treats a developer environment repo as the primary source of truth, scans the current Mac for drift, and helps the user apply or promote environment changes locally. The product is intentionally narrower than full-machine migration: it captures developer tooling state, configuration, verification artifacts, and legacy bundle compatibility for same-category machine transfer.

## Current Focus

The current repository state includes the repo-first control tower baseline plus legacy bundle compatibility:

- the macOS app scaffold and SwiftUI shell for Overview, Repo, Drift, Export, Import, and Reports
- the shared manifest contract used across modules
- file-backed manifest persistence
- preflight checks for machine compatibility and destination writeability
- workspace detection for `chezmoi`, plain dotfiles, `Brewfile`, `mise`, `.tool-versions`, and VS Code repo files
- local environment scanning and drift calculation
- workspace apply/promote preview coordinators with backup-on-overwrite and secret exclusion
- Homebrew, dotfile allowlist, and Git global export/import services retained for legacy bundle compatibility
- VS Code export/import for settings, keybindings, snippets, and extensions retained for legacy bundle compatibility
- bundle preview loading for import selection so manual tasks, reports, and logs are visible before restore
- verify checks for Brew, dotfiles, Git global config, and VS Code extensions
- backup-on-overwrite safeguards and manual task surfacing
- Markdown reporting primitives and core workflow tests for workspace and legacy bundle flows

## Module Boundaries

- `App`
  SwiftUI entry point and the tabbed shell for Overview, Repo, Drift, Export, Import, and Reports.
- `SharedModels`
  Codable domain types for manifests, machine metadata, workspace snapshots, drift items, restore phases, manual tasks, and report payloads.
- `Core`
  Reusable services that avoid UI dependencies: filesystem access, manifest store, validators, workspace detection/scanning, drift logic, path helpers, restore planning, and restore safety helpers.
- `Reporting`
  Markdown rendering for preflight, workspace summaries, and operation summaries.
- `Exporters` and `Importers`
  Workflow-specific orchestration layered on top of the shared models and core services. These now include workspace apply/promote previews in addition to legacy bundle export/import.

## Data Contract

The manifest schema in `spec/manifest.schema.json` defines the intended external contract. The app mirrors that contract in `Sources/SharedModels/Manifest.swift`, and the current tests verify representative compatibility by decoding `spec/manifest.sample.json` plus validating core manifest invariants in Swift.

Important top-level fields:

- `schemaVersion`
- `exportedAt`
- `machine`
- `items`
- `restorePlan`
- `manualTasks`
- `reports`

Restore phases are ordered explicitly through `RestorePhase.order`, which allows `RestorePlanBuilder` to emit stable execution order while keeping the manifest readable.

## Data Flow

1. `RepoWorkspaceDetector` identifies supported repo conventions from a connected workspace path.
2. `RepoSnapshotLoader` normalizes repo state into `RepoSnapshot`.
3. `EnvironmentScanner` reads the current Mac into `EnvironmentSnapshot`.
4. `DriftEngine` compares repo and local snapshots into `DriftItem` records.
5. `ReportFileWriter` and `MarkdownReportWriter` render workspace scan/drift summaries for the control tower shell.
6. `WorkspaceApplyCoordinator` and `WorkspacePromoteCoordinator` prepare apply/promote previews while preserving backup and secret policies.
7. Legacy bundle export/import remains available through `ExportCoordinator`, `ImportCoordinator`, and `BundlePreviewService`.

## Safety Defaults

- secret-like material is excluded by default
- writes go through backup-on-overwrite helpers
- restore phases are explicit and testable
- reporting is human-readable so skipped or manual work stays visible
- workspace promote previews do not auto-commit or auto-push repo changes

## Testing Strategy

Current tests focus on deterministic behavior:

- manifest encode/decode and manifest file round-trips
- preflight parsing and machine/environment checks
- workspace model encode/decode and workflow result behavior
- repo detection, snapshot loading, local environment scanning, and drift classification
- workspace apply/promote preview behavior
- restore plan ordering
- backup filename generation and overwrite backup behavior
- path normalization
- Brewfile and Markdown report generation
- VS Code export/import paths and extension parsing
- verify report generation, including partial-failure cases

Integration-style tests cover the legacy exporter/importer baseline, and the app shell now consumes both workspace summaries and bundle previews through the same shared services.
