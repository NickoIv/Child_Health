# Full rebuild and publish.
#
# The AI proxy URL is a build-time --dart-define, which is exactly the kind of
# flag that gets forgotten on a manual rebuild — and forgetting it silently
# ships the assistant switched off. This script exists so that cannot happen.
#
# Deliberately ASCII-only: Windows PowerShell 5.1 reads a .ps1 without a BOM
# as ANSI, which mangles Cyrillic and breaks parsing before the first command.
#
# Usage:  .\deploy.ps1

$ErrorActionPreference = 'Stop'

$env:PATH = "H:\dev\flutter\bin;C:\Program Files\nodejs;$env:APPDATA\npm;$env:PATH"
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$aiProxy = 'https://child-health-ai.nickru777.workers.dev'

Set-Location $PSScriptRoot

Write-Host '--- analyze ---' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported problems' }

Write-Host '--- test ---' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { throw 'tests failed' }

Write-Host '--- build web ---' -ForegroundColor Cyan
flutter build web --release --dart-define=AI_PROXY_URL=$aiProxy
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

Write-Host '--- deploy hosting ---' -ForegroundColor Cyan
& "$env:APPDATA\npm\firebase.cmd" deploy --only hosting --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'hosting deploy failed' }

Write-Host ''
Write-Host 'Done: https://child-health-tracker-7aad1.web.app' -ForegroundColor Green
