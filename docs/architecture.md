# Mac Dev Env Mover Architecture

## Goal

Mac Dev Env Mover is a native macOS app that exports a personal development environment into a local bundle and later imports that bundle onto another Mac. The product is intentionally narrower than full-machine migration: it captures developer tooling state, configuration, and verification artifacts.

## Phase 2 Focus

The current repository state includes the Phase 1 foundation and the Phase 2 workflow baseline:

- the macOS app scaffold and SwiftUI shell
- the shared manifest contract used across modules
- file-backed manifest persistence
- preflight checks for machine compatibility and destination writeability
- Homebrew, dotfile allowlist, and Git global export/import services
- backup-on-overwrite safeguards and manual task surfacing
- Markdown reporting primitives and core workflow tests

## Module Boundaries

- `App`
  SwiftUI entry point and the tabbed shell for Overview, Export, Import, and Reports / Logs.
- `SharedModels`
  Codable domain types for manifests, machine metadata, item kinds, restore phases, manual tasks, and report payloads.
- `Core`
  Reusable services that avoid UI dependencies: filesystem access, manifest store, validators, path helpers, restore planning, and restore safety helpers.
- `Reporting`
  Markdown rendering for preflight and operation summaries.
- `Exporters` and `Importers`
  Workflow-specific orchestration layered on top of the shared models and core services.

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

1. `PreflightService` gathers machine metadata and checks whether export or import can proceed safely.
2. Export services gather Homebrew, dotfile, Git, and later IDE items into manifest entries.
3. `ManifestStore` writes the manifest JSON into the bundle.
4. `ReportFileWriter` and `MarkdownReportWriter` render human-readable summaries into `reports/`.
5. During import, the same manifest models drive package restore, file restore with backups, manual task surfacing, and verification.

## Safety Defaults

- secret-like material is excluded by default
- writes go through backup-on-overwrite helpers
- restore phases are explicit and testable
- reporting is human-readable so skipped or manual work stays visible

## Testing Strategy

Current tests focus on deterministic behavior:

- manifest encode/decode and manifest file round-trips
- preflight parsing and machine/environment checks
- restore plan ordering
- backup filename generation and overwrite backup behavior
- path normalization
- Brewfile and Markdown report generation

Integration-style tests cover the Phase 2 exporter/importer baseline, while later IDE-specific behavior remains for the next phase.
