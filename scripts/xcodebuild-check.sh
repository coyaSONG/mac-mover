#!/usr/bin/env bash
set -euo pipefail

PROJECT="MacDevEnvMover.xcodeproj"
CONFIGURATION="Debug"
SDK="macosx"
REQUIRE_XCODEBUILD="${REQUIRE_XCODEBUILD:-0}"

if ! command -v xcodebuild >/dev/null 2>&1; then
  echo "xcodebuild not found."
  if [[ "${REQUIRE_XCODEBUILD}" == "1" ]]; then
    exit 1
  fi
  exit 0
fi

if ! xcodebuild -version >/dev/null 2>&1; then
  echo "xcodebuild is unavailable (likely Command Line Tools without full Xcode)."
  echo "Install full Xcode and run: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
  if [[ "${REQUIRE_XCODEBUILD}" == "1" ]]; then
    exit 1
  fi
  exit 0
fi

if [[ ! -d "${PROJECT}" ]]; then
  echo "Missing project: ${PROJECT}"
  exit 1
fi

COMMON_FLAGS=(
  -project "${PROJECT}"
  -configuration "${CONFIGURATION}"
  -sdk "${SDK}"
  CODE_SIGNING_ALLOWED=NO
)

echo "[xcodebuild] Build app target"
xcodebuild "${COMMON_FLAGS[@]}" -target MacDevEnvMover build

echo "[xcodebuild] Build test target"
xcodebuild "${COMMON_FLAGS[@]}" -target MacDevEnvMoverTests build

echo "xcodebuild checks completed."
