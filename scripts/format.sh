#!/usr/bin/env bash
set -euo pipefail

command -v dart >/dev/null 2>&1 || { echo "dart not found on PATH"; exit 1; }
dart format .

