# Полная пересборка и публикация приложения.
#
# Адрес ИИ-прокси задаётся на этапе сборки через --dart-define, поэтому его
# легко забыть — и тогда помощник молча окажется отключён в продакшене.
# Скрипт существует, чтобы этого не случилось.
#
# Запуск:  .\deploy.ps1

$ErrorActionPreference = 'Stop'

$env:PATH = "H:\dev\flutter\bin;C:\Program Files\nodejs;$env:APPDATA\npm;$env:PATH"
$env:CHROME_EXECUTABLE = "C:\Program Files\Google\Chrome\Application\chrome.exe"

$aiProxy = 'https://child-health-ai.nickru777.workers.dev'

Set-Location $PSScriptRoot

Write-Host '--- Анализ ---' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { throw 'flutter analyze нашёл проблемы' }

Write-Host '--- Тесты ---' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { throw 'тесты не прошли' }

Write-Host '--- Сборка web ---' -ForegroundColor Cyan
flutter build web --release --dart-define=AI_PROXY_URL=$aiProxy
if ($LASTEXITCODE -ne 0) { throw 'сборка не удалась' }

Write-Host '--- Публикация ---' -ForegroundColor Cyan
& "$env:APPDATA\npm\firebase.cmd" deploy --only hosting --non-interactive
if ($LASTEXITCODE -ne 0) { throw 'деплой не удался' }

Write-Host ''
Write-Host 'Готово: https://child-health-tracker-7aad1.web.app' -ForegroundColor Green
