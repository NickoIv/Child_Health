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

# No --pwa-strategy here, deliberately. The flag is what df3c6b9 relied on
# ('built with --pwa-strategy=none from here on'), Flutter already prints a
# deprecation notice for it, and the day it is removed a build that passes it
# fails outright on an unknown option. So the result is produced rather than
# requested: build the ordinary way, then take the service worker out.
#
# Why it must come out at all: index.html unregisters service workers on load,
# and a bootstrap that registers a fresh one on the same load put the app
# shell straight back. That is how three deploys reached the bucket and never
# reached a phone. Offline reads come from Firestore's own cache; the worker
# only ever held the shell.
flutter build web --release --dart-define=AI_PROXY_URL=$aiProxy --dart-define=FCM_VAPID_KEY=$vapidKey
if ($LASTEXITCODE -ne 0) { throw 'build failed' }

# The registration is one argument on the last call of the bootstrap:
# `_flutter.loader.load({serviceWorkerSettings:{serviceWorkerVersion:"..."}})`.
# Rewritten to the bare call, which is exactly what the flag used to emit.
#
# Matched on that call rather than on the word `serviceWorkerSettings`: the
# loader's own source is inlined into this file and destructures an argument
# of that name in every build ever made. The inner brace belongs to the
# settings object, so the lazy match has to run on to the brace that is
# actually followed by the closing paren.
$bootstrapPath = 'build\web\flutter_bootstrap.js'
$bootstrap = [System.IO.File]::ReadAllText((Resolve-Path $bootstrapPath))
$stripped = [regex]::Replace(
  $bootstrap,
  '_flutter\.loader\.load\(\s*\{[\s\S]*?\}\s*\)\s*;',
  '_flutter.loader.load();'
)
if ($stripped -ne $bootstrap) {
  # No BOM: this is served as JavaScript, and Set-Content would add one.
  [System.IO.File]::WriteAllText(
    (Resolve-Path $bootstrapPath),
    $stripped,
    (New-Object System.Text.UTF8Encoding $false)
  )
  Write-Host '    service worker registration stripped from flutter_bootstrap.js'
}

# Whatever the tool did, this is the state that gets published.
if (-not (Select-String -Path $bootstrapPath -Pattern '_flutter\.loader\.load\(\)\;' -Quiet)) {
  throw 'flutter_bootstrap.js does not end in a bare load() - a service worker is being registered'
}

# And the orphan itself does not get published: nothing may serve a file that
# must never run.
if (Test-Path build\web\flutter_service_worker.js) {
  Remove-Item build\web\flutter_service_worker.js -Force
}

# Rules and indexes first, and from now on every time.
#
# They were a manual step documented in the README, so they drifted: the
# family_members block was added to firestore.rules on 6 August and never
# reached the project, which left «Пригласить» failing with permission-denied
# for four days against rules that had no idea the collection existed. A
# script that publishes the client but not the rules it was written against
# ships half a system.
#
# Deployed before hosting on purpose: a bundle that expects new rules must
# never be live while the old ones are, and if this step fails nothing else
# goes out.
Write-Host '--- deploy firestore rules and indexes ---' -ForegroundColor Cyan
& "$env:APPDATA\npm\firebase.cmd" deploy --only firestore:rules,firestore:indexes --non-interactive
if ($LASTEXITCODE -ne 0) {
  throw 'firestore rules/indexes deploy failed - if it says credentials are no longer valid, run: firebase login --reauth'
}

Write-Host '--- deploy hosting ---' -ForegroundColor Cyan
& "$env:APPDATA\npm\firebase.cmd" deploy --only hosting --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'hosting deploy failed' }

Write-Host ''
Write-Host 'Done: https://child-health-tracker-7aad1.web.app' -ForegroundColor Green
