Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "== Guess Together bootstrap =="

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "flutter not found on PATH. Install Flutter SDK and restart your terminal."
}

if (-not (Test-Path -Path ".\android") -or -not (Test-Path -Path ".\ios")) {
  Write-Host "Platform folders missing. Generating with: flutter create ."
  flutter create .
}

flutter pub get
Write-Host "Done."

