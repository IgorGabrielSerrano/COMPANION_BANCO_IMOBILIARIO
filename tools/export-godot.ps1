param([string]$GodotPath)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if (-not $GodotPath) {
    $GodotPath = Join-Path $projectRoot 'Godot_v4.7.2-stable_win64_console.exe'
}
$godotProject = Join-Path $projectRoot 'godot-web'
& node (Join-Path $PSScriptRoot 'extract-bank-themes.cjs')
if ($LASTEXITCODE -ne 0) { throw 'Bank theme extraction failed.' }
$exportDirectory = Join-Path $projectRoot 'build/game'
New-Item -ItemType Directory -Force -Path $exportDirectory | Out-Null
& $GodotPath --headless --path $godotProject --editor --import --quit
if ($LASTEXITCODE -ne 0) { throw 'Godot import failed.' }
& $GodotPath --headless --path $godotProject --export-release Web (Join-Path $exportDirectory 'index.html')
if ($LASTEXITCODE -ne 0) { throw 'Godot Web export failed.' }
$exportHtml = Join-Path $exportDirectory 'index.html'
$htmlSource = [System.IO.File]::ReadAllText($exportHtml).TrimEnd() + "`n"
$packPath = Join-Path $exportDirectory 'index.pck'
$packHash = (Get-FileHash -LiteralPath $packPath -Algorithm SHA256).Hash.ToLower().Substring(0, 12)
$packName = "table-$packHash.pck"
Get-ChildItem -LiteralPath $exportDirectory -Filter 'table-*.pck' | Where-Object {
    $_.Name -match '^table-[0-9a-f]{12}\.pck$' -and $_.Name -ne $packName
} | ForEach-Object { Remove-Item -LiteralPath $_.FullName }
Copy-Item -LiteralPath $packPath -Destination (Join-Path $exportDirectory $packName) -Force
$htmlSource = $htmlSource.Replace('"index.pck"', '"' + $packName + '"')
$htmlSource = $htmlSource.Replace('engine.startGame({', "engine.startGame({`n`t`t`t'mainPack': '$packName',")
[System.IO.File]::WriteAllText($exportHtml, $htmlSource, [System.Text.UTF8Encoding]::new($false))
$mainHtml = Join-Path $projectRoot 'build/index.html'
$mainSource = [System.IO.File]::ReadAllText($mainHtml)
$mainSource = [regex]::Replace($mainSource, 'src="game/index\.html(?:\?v=[a-zA-Z0-9-]+)?"', ('src="game/index.html?v=' + $packHash + '"'))
[System.IO.File]::WriteAllText($mainHtml, $mainSource, [System.Text.UTF8Encoding]::new($false))
$fontDestination = Join-Path $projectRoot 'build/assets/fonts'
New-Item -ItemType Directory -Force -Path $fontDestination | Out-Null
Get-ChildItem -LiteralPath (Join-Path $godotProject 'fonts') -File | Where-Object {
    $_.Extension -in '.ttf', '.txt'
} | ForEach-Object { Copy-Item -LiteralPath $_.FullName -Destination $fontDestination -Force }
