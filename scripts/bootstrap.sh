#!/usr/bin/env bash
set -euo pipefail

echo "== Guess Together bootstrap =="

command -v flutter >/dev/null 2>&1 || { echo "flutter not found on PATH"; exit 1; }

if [[ ! -d "./android" || ! -d "./ios" ]]; then
  echo "Platform folders missing. Generating with: flutter create ."
  flutter create .
fi

flutter pub get
echo "Done."

