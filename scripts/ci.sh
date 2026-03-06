#!/usr/bin/env bash
set -euo pipefail

echo "[ci] swift build"
swift build

echo "[ci] swift test"
swift test

echo "[ci] xcodebuild checks"
./scripts/xcodebuild-check.sh

echo "[ci] done"
