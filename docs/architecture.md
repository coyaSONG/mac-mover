# Mac Dev Env Mover Architecture

## Goal

Mac Dev Env Mover is a native macOS app that exports a personal development environment into a local bundle and later imports that bundle onto another Mac. The product is intentionally narrower than full-machine migration: it captures developer tooling state, configuration, and verification artifacts.

## Phase 1 Focus

Phase 1 provides the foundation the later export/import workflows depend on:

- the macOS app scaffold and SwiftUI shell
- the shared manifest contract used across modules
- file-backed manifest persistence
- Markdown reporting primitives
- core utilities and tests for restore ordering, backup naming, and path handling

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

The manifest schema in `spec/manifest.schema.json` defines the intended external contract. The app mirrors that contract in `Sources/SharedModels/Manifest.swift`, and the current Phase 1 tests verify representative compatibility by decoding `spec/manifest.sample.json` plus validating core manifest invariants in Swift.

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

1. The app gathers machine metadata and exported items.
2. Shared models encode that state into a manifest.
3. `ManifestStore` writes the manifest JSON into the bundle.
4. `MarkdownReportWriter` renders human-readable summaries into `reports/`.
5. During import and verification, the same manifest models drive restore ordering and reporting.

## Safety Defaults

- secret-like material is excluded by default
- writes go through backup-on-overwrite helpers
- restore phases are explicit and testable
- reporting is human-readable so skipped or manual work stays visible

## Testing Strategy

Phase 1 tests focus on deterministic behavior:

- manifest encode/decode and manifest file round-trips
- restore plan ordering
- backup filename generation
- path normalization
- Markdown report generation

Integration-style tests exist for later workflow scaffolding, but the Phase 1 baseline is the shared contract and utility layer.
