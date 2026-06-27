# Rebuild the Flutter web app and redeploy to GitHub Pages (gh-pages branch).
# Usage:  powershell -File scripts\deploy.ps1
$ErrorActionPreference = "Stop"
$repo = Split-Path -Parent $PSScriptRoot
$flutter = "C:\dev\flutter\bin\flutter.bat"

Set-Location $repo
& $flutter build web --base-href "/habit-companion/" --release

$tmp = Join-Path $env:TEMP ("ghp_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force $tmp | Out-Null
Copy-Item -Recurse "$repo\build\web\*" $tmp
New-Item -ItemType File -Force (Join-Path $tmp ".nojekyll") | Out-Null

Set-Location $tmp
git init -b gh-pages | Out-Null
git add .
git -c user.email="deploy@local" -c user.name="deploy" commit -q -m "redeploy web build"
git remote add origin "https://github.com/slpzjvl0102/habit-companion.git"
git push -f origin gh-pages

Write-Output "Deployed -> https://slpzjvl0102.github.io/habit-companion/  (live in ~1 min)"
