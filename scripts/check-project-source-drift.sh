#!/usr/bin/env bash
set -euo pipefail

PROJECT_FILE="MacDevEnvMover.xcodeproj/project.pbxproj"

if [[ ! -f "${PROJECT_FILE}" ]]; then
  echo "Missing project file: ${PROJECT_FILE}"
  exit 1
fi

if ! command -v rg >/dev/null 2>&1; then
  echo "rg is required for project source drift checks."
  exit 1
fi

source_files=$(rg --files Sources -g '*.swift' | xargs -n1 basename | sort -u)
duplicate_names=$(rg --files Sources -g '*.swift' | xargs -n1 basename | sort | uniq -d)

if [[ -n "${duplicate_names}" ]]; then
  echo "Duplicate Swift source basenames are not supported by this guard:"
  printf '  %s\n' ${duplicate_names}
  exit 1
fi

project_sources=$(rg -o '/\* [^*]+\.swift in Sources \*/' "${PROJECT_FILE}" | sed -E 's#/\* (.+) in Sources \*/#\1#' | sort -u)

missing_in_project=$(comm -23 <(printf '%s\n' "${source_files}") <(printf '%s\n' "${project_sources}"))

if [[ -n "${missing_in_project}" ]]; then
  echo "Swift sources missing from Xcode project build phases:"
  printf '  %s\n' ${missing_in_project}
  exit 1
fi

echo "Project source drift check passed."
