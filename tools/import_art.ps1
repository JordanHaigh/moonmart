param([Parameter(Mandatory=$true)][string]$ArtZip)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path $ArtZip)) { throw "Art ZIP not found: $ArtZip" }
$root = (Resolve-Path ".").Path
$target = Join-Path $root "art_import"
New-Item -ItemType Directory -Force -Path $target | Out-Null
Expand-Archive -LiteralPath $ArtZip -DestinationPath $target -Force
git add art_import
git commit -m "Import original Moonmart concept artwork and prototype assets"
git push origin main
Write-Host "Art imported into art_import/ and pushed to GitHub."
