#!/usr/bin/env bash
set -euo pipefail

echo "[ci] swift build"
swift build

echo "[ci] swift test"
swift test

echo "[ci] project source drift"
./scripts/check-project-source-drift.sh

echo "[ci] xcodebuild checks"
./scripts/xcodebuild-check.sh

echo "[ci] done"
