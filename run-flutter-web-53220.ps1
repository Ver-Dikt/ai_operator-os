$root = 'G:\AI\jule'
Set-Location $root
$env:GIT_CONFIG_GLOBAL = Join-Path $root '.codex-gitconfig'
$env:APPDATA = Join-Path $root '.codex-home\AppData\Roaming'
$env:LOCALAPPDATA = Join-Path $root '.codex-home\AppData\Local'
$env:USERPROFILE = Join-Path $root '.codex-home'
$env:FLUTTER_SUPPRESS_ANALYTICS = 'true'
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 53220 *> flutter-web-53220.live.log
