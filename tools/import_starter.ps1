param(
  [Parameter(Mandatory=$true)][string]$Archive,
  [string]$Destination = "imported_starter"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $Archive)) { throw "Missing archive: $Archive" }
$root = (Get-Location).Path
$dest = Join-Path $root $Destination
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Expand-Archive -LiteralPath $Archive -DestinationPath $dest -Force
git add -- $Destination
git commit -m "Import Moonmart starter archive contents"
git push origin main
Write-Host "Imported into $Destination and pushed to GitHub."
