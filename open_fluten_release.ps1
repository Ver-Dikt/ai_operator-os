$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $RepoRoot "build\windows\x64\runner\Release\ai_operator_os.exe"

if (-not (Test-Path -LiteralPath $ExePath)) {
  Write-Host "Release build not found. Run build_fluten_windows.ps1 first."
  exit 1
}

Write-Host "Opening FLUTEN release..."
Start-Process -FilePath $ExePath -WorkingDirectory (Split-Path -Parent $ExePath)
