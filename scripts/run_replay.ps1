param([string]$LogPath="sample_logs/rotate_fail.log")
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$Root = Resolve-Path (Join-Path $ScriptDir "..")
Set-Location $Root
dart pub get | Out-Null
dart run tool/golden_replay.dart $LogPath -v
