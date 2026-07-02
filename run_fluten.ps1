$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location -LiteralPath $RepoRoot

$Flutter = Join-Path $RepoRoot ".tools\flutter\bin\flutter.bat"
if (-not (Test-Path -LiteralPath $Flutter)) {
  Write-Host "Local Flutter not found: $Flutter"
  exit 1
}

if (-not (Test-Path -LiteralPath (Join-Path $RepoRoot ".dart_tool\package_config.json"))) {
  Write-Host "Running flutter pub get..."
  & $Flutter pub get
}

Write-Host "Starting FLUTEN in Windows dev mode..."
& $Flutter run -d windows
