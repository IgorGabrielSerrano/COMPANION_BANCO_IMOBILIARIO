param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'Godot_v4.7.2-stable_win64_console.exe'
}
$godotProject = Join-Path $projectRoot 'godot-web'
$exportDirectory = Join-Path $projectRoot 'build/game'
New-Item -ItemType Directory -Force -Path $exportDirectory | Out-Null
& $GodotPath --headless --path $godotProject --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $GodotPath --headless --path $godotProject --export-release Web (Join-Path $exportDirectory 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'Godot Web export failed.' }
$exportHtml = Join-Path $exportDirectory 'index.html'
$htmlSource = [System.IO.File]::ReadAllText($exportHtml).TrimEnd() + "`n"
[System.IO.File]::WriteAllText($exportHtml, $htmlSource, [System.Text.UTF8Encoding]::new($false))
