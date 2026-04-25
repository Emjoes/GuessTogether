#!/usr/bin/env bash
set -euo pipefail

command -v flutter >/dev/null 2>&1 || { echo "flutter not found on PATH"; exit 1; }

flutter test
if [[ -d integration_test ]]; then
  flutter test integration_test
fi

