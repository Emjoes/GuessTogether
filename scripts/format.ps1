Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
  throw "dart not found on PATH (it comes with Flutter)."
}

dart format .

