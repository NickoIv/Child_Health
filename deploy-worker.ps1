# Publish the Cloudflare Worker: the AI proxy and the hourly reminder sweep.
#
# A separate script from deploy.ps1 on purpose. This one needs a Cloudflare
# login rather than a Firebase one, it is run far less often, and folding it
# into the app deploy would stop the app shipping whenever wrangler happened
# to be logged out.
#
# It is a script at all because the last thing left as "a step in the README"
# was firestore:rules, and it drifted for four days while «Пригласить» failed
# with permission-denied. Anything that has to be deployed gets a script.
#
# Deliberately ASCII-only, same reason as deploy.ps1: PowerShell 5.1 reads a
# .ps1 without a BOM as ANSI and mangles Cyrillic before the first command.
#
# Usage:  powershell -ExecutionPolicy Bypass -File .\deploy-worker.ps1

$ErrorActionPreference = 'Continue'
$env:PATH = "C:\Program Files\nodejs;$env:APPDATA\npm;$env:PATH"

Set-Location "$PSScriptRoot\worker"

Write-Host '--- secrets ---' -ForegroundColor Cyan
# Both are required, and each fails in its own quiet way when missing: without
# GEMINI_API_KEY the assistant answers with an explanation instead of an
# answer, and without FIREBASE_SERVICE_ACCOUNT the hourly sweep logs "not
# configured" and sends nothing at all. Neither is visible from the app.
$secrets = npx wrangler secret list 2>&1 | Out-String
foreach ($name in @('GEMINI_API_KEY', 'FIREBASE_SERVICE_ACCOUNT', 'FIREBASE_API_KEY', 'BREVO_API_KEY')) {
  if ($secrets -notmatch $name) {
    Write-Host ''
    Write-Host "MISSING SECRET: $name" -ForegroundColor Yellow
    if ($name -eq 'FIREBASE_SERVICE_ACCOUNT') {
      Write-Host '  Firebase Console -> Project settings -> Service accounts'
      Write-Host '  -> Generate new private key. Paste the whole JSON file.'
    }
    if ($name -eq 'FIREBASE_API_KEY') {
      Write-Host '  The web API key from lib/firebase/firebase_options.dart.'
      Write-Host '  Public by design - it only lets the Worker ask Google who'
      Write-Host '  an ID token belongs to.'
    }
    if ($name -eq 'BREVO_API_KEY') {
      Write-Host '  https://app.brevo.com -> SMTP & API -> Generate a new key.'
      Write-Host '  Free tier sends 300 letters a day from one verified sender.'
      Write-Host '  Verify your own address there first, then set MAIL_FROM in'
      Write-Host '  wrangler.toml to it.'
    }
    Write-Host "  npx wrangler secret put $name"
    Write-Host ''
    throw "$name is not set on the Worker"
  }
  Write-Host "    $name is set"
}

Write-Host '--- deploy ---' -ForegroundColor Cyan
npx wrangler deploy
if ($LASTEXITCODE -ne 0) { throw 'wrangler deploy failed' }

# The cron is what turns a proxy into a scheduler. It lives in wrangler.toml,
# so a deploy that succeeded has it - but it is worth printing, because a
# reminder that never arrives looks exactly like a reminder that was never
# scheduled.
Write-Host ''
Write-Host 'Deployed. Reminder sweep runs hourly (cron 0 * * * *).' -ForegroundColor Green
Write-Host 'Check it: https://dash.cloudflare.com -> Workers -> child-health-ai -> Logs'
