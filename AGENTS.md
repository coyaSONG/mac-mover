# Mac Dev Env Mover

## Product
Build a **local-only personal macOS app** that exports a developer environment from one Mac and imports it on another to recreate that environment as faithfully as practical.

This is **not** a full-Mac cloning app.
This **is** a developer-environment recreation app.

## v1 scope
Implement only the following in v1:
- Homebrew
  - formula
  - cask
  - tap
  - service
- dotfiles allowlist
- Git global config
- VS Code
  - extensions
  - user settings
  - keybindings
  - snippets
- export/import/verify reports

## v1 non-goals
Do not implement these in v1:
- Keychain migration
- passwords, tokens, sessions, cloud credentials
- SSH private key auto-migration
- Docker images/volumes/containers
- local DB data
- JetBrains support
- Xcode settings sync
- browser sessions/cookies
- app license state migration
- full system settings cloning
- custom LaunchAgents/LaunchDaemons migration
- cloud sync
- account system
- server backend
- background agent

## Security rules
- Treat secrets as excluded by default.
- Never auto-copy private keys, tokens, or keychain contents.
- Unsupported or secret items must appear as manual tasks in reports.
- Never silently delete user files.
- Before overwrite, create timestamped `.bak` backups.

## Technical stack
- Swift
- SwiftUI
- Swift Concurrency
- native macOS app

## Suggested structure
- App
- Core
- Exporters
- Importers
- Reporting
- SharedModels
- Tests

## Implementation rules
- Read `/docs` and `/spec` before changing code.
- Keep the app buildable after each phase.
- Prefer small, reviewable diffs.
- Use `Process` with argument arrays; avoid shell-string composition.
- Separate UI from core logic.
- Make core logic testable without UI.
- Update `README.md` when behavior changes.
- Add or update tests for new core logic.

## Data contract
Prefer the schema file in `/spec/manifest.schema.json`.
If missing, use these required top-level fields:
- schemaVersion
- exportedAt
- machine
- items
- restorePlan
- reports

## Workflow
1. Read AGENTS.md and project docs.
2. Write a brief implementation plan to `docs/plan.md`.
3. Execute the current phase only.
4. Run the smallest relevant build/tests.
5. Summarize changes, open issues, and next steps.

## Done criteria for v1
- app runs on macOS
- export folder can be created
- manifest, Brewfile, and reports are generated
- import works for same-category machine
- overwrite creates `.bak`
- unsupported/secrets/manual tasks are visible
- verify report is generated
- tests exist
- README documents scope and exclusions
