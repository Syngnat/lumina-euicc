#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <Gradle release runtime dependency report>" >&2
  exit 2
fi

report="$1"
if [[ ! -s "${report}" ]]; then
  echo "Gradle dependency report is missing or empty: ${report}" >&2
  exit 1
fi

forbidden_pattern='com\.google\.mlkit:|com\.google\.android\.gms:play-services-mlkit-|com\.google\.android\.libraries\.barhopper:'
matches="$(grep -Ei "${forbidden_pattern}" "${report}" || true)"
if [[ -n "${matches}" ]]; then
  echo "Forbidden proprietary/bundled ML Kit runtime dependencies were resolved:" >&2
  printf '%s\n' "${matches}" | LC_ALL=C sort -u >&2
  exit 1
fi

echo "Gradle release runtime dependency policy passed (no ML Kit/Barhopper coordinates)."
