Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
  throw "flutter not found on PATH."
}

flutter pub get
flutter run

