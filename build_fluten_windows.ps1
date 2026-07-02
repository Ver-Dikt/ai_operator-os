$ErrorActionPreference = "Stop"

$RepoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildRoot = $RepoRoot
$JunctionPath = "G:\AI\STUDIO_WORK"

function Use-RepoRoot($Path) {
  Set-Location -LiteralPath $Path
  $flutter = Join-Path $Path ".tools\flutter\bin\flutter.bat"
  if (-not (Test-Path -LiteralPath $flutter)) {
    Write-Host "Local Flutter not found: $flutter"
    exit 1
  }
  return $flutter
}

if ($RepoRoot -match "\s") {
  Write-Host "Repository path contains spaces. Trying no-spaces junction: $JunctionPath"
  if (Test-Path -LiteralPath $JunctionPath) {
    $item = Get-Item -LiteralPath $JunctionPath
    if ($item.LinkType -eq "Junction" -and $item.Target -eq $RepoRoot) {
      $BuildRoot = $JunctionPath
    } elseif ((Resolve-Path -LiteralPath $JunctionPath).Path -eq $RepoRoot) {
      $BuildRoot = $JunctionPath
    } else {
      Write-Host "Junction path already exists and points elsewhere. Building from repo root instead."
      Write-Host "If build fails, create a no-spaces checkout or junction manually:"
      Write-Host "  cmd /c mklink /J G:\AI\STUDIO_WORK `"$RepoRoot`""
    }
  } else {
    $parent = Split-Path -Parent $JunctionPath
    if (-not (Test-Path -LiteralPath $parent)) {
      New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $cmd = "mklink /J `"$JunctionPath`" `"$RepoRoot`""
    cmd /c $cmd
    if (Test-Path -LiteralPath $JunctionPath) {
      $BuildRoot = $JunctionPath
    } else {
      Write-Host "Could not create junction. Build will continue from repo root."
      Write-Host "Fallback: run PowerShell as a user allowed to create junctions, then retry."
    }
  }
}

$Flutter = Use-RepoRoot $BuildRoot

Write-Host "Running flutter pub get..."
& $Flutter pub get

Write-Host "Running flutter analyze --no-pub..."
& $Flutter analyze --no-pub

Write-Host "Building Windows release..."
& $Flutter build windows

$ExePath = Join-Path $BuildRoot "build\windows\x64\runner\Release\ai_operator_os.exe"
Write-Host ""
Write-Host "Release exe:"
Write-Host $ExePath
