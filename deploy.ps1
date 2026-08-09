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

# Deliberately not 'Stop'. Every step here is a native executable, and
# PowerShell 5.1 turns anything they write to stderr into a terminating error
# under 'Stop' - which killed a perfectly good build over a Wasm advisory note
# printed on the way out. Each step is checked by its exit code instead, which
# is the only thing that actually says whether it worked.
$ErrorActionPreference = 'Continue'

$env:PATH = "H:\dev\flutter\bin;C:\Program Files\nodejs;$env:APPDATA\npm;$env:PATH"
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$aiProxy = 'https://child-health-ai.nickru777.workers.dev'

# Web push sender identity. Public by design — it is not a credential.
# Firebase console -> Project settings -> Cloud Messaging -> Web Push
# certificates -> "Key pair". Empty means push stays switched off and the
# settings screen says so, rather than failing silently.
$vapidKey = 'BNr32NxhIUlx_8iABBx5NmOnn1um1TJtwEUA26ZJd5KOXpySuzTlMeNZrGYv9zqKiaf99SLqlfuT5HVVKZ_44Lg'

Set-Location $PSScriptRoot

Write-Host '--- analyze ---' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze reported problems' }

Write-Host '--- test ---' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { throw 'tests failed' }

Write-Host '--- build web ---' -ForegroundColor Cyan
# Emptied first: flutter build web writes over what it produces and leaves
# everything else alone, so a file a previous build made - the service worker
# below is exactly that - would otherwise sit in build/web forever and get
# deployed again by a script that never asked for it.
if (Test-Path build\web) { Remove-Item build\web -Recurse -Force }

# --pwa-strategy=none, and this is the flag the whole caching story turns on.
# It was declared in df3c6b9 ('built with --pwa-strategy=none from here on')
# and only ever applied to web/index.html; the script kept building the
# default way, so every deploy since shipped flutter_service_worker.js and
# flutter_bootstrap.js registered it. index.html unregisters service workers
# on load and the bootstrap installed a fresh one on the same load, which is
# how an app shell nobody wanted kept coming back. Offline reads come from
# Firestore's own cache; the service worker only ever held the shell.
flutter build web --release --pwa-strategy=none --dart-define=AI_PROXY_URL=$aiProxy --dart-define=FCM_VAPID_KEY=$vapidKey
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

# The tool still writes flutter_service_worker.js either way; what decides
# whether a browser installs one is whether the bootstrap asks it to. With the
# flag the file ends in a bare `_flutter.loader.load()`, and without it in
# `load({serviceWorkerSettings:{serviceWorkerVersion:"..."}})`. So that is what
# is checked - the file's presence never meant anything.
# Matched on the final call, not on the word: the loader's own source is
# inlined into this file and destructures a `serviceWorkerSettings` argument,
# so searching for the name matches every build ever made.
if (-not (Select-String -Path build\web\flutter_bootstrap.js -Pattern '_flutter\.loader\.load\(\)\;' -Quiet)) {
  throw 'flutter_bootstrap.js does not end in a bare load() - a service worker is being registered'
}

# And the orphan itself does not get published: nothing may serve a file that
# must never run.
if (Test-Path build\web\flutter_service_worker.js) {
  Remove-Item build\web\flutter_service_worker.js -Force
}

Write-Host '--- deploy hosting ---' -ForegroundColor Cyan
& "$env:APPDATA\npm\firebase.cmd" deploy --only hosting --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'hosting deploy failed' }

Write-Host ''
Write-Host 'Done: https://child-health-tracker-7aad1.web.app' -ForegroundColor Green
