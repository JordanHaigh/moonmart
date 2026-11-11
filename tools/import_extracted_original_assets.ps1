param(
  [Parameter(Mandatory=$true)][string]$ExtractedFolder
)
$ErrorActionPreference = "Stop"
$repo = (git rev-parse --show-toplevel).Trim()
if (-not (Test-Path -LiteralPath $ExtractedFolder -PathType Container)) {
  throw "Folder not found: $ExtractedFolder"
}
$folder = (Resolve-Path -LiteralPath $ExtractedFolder).Path
$candidates = @(
  (Join-Path $folder "modular_assets"),
  $folder
)
$source = $null
foreach ($candidate in $candidates) {
  if (Test-Path (Join-Path $candidate "png\characters\player.png")) {
    $source = $candidate
    break
  }
}
if (-not $source) {
  $matches = @(Get-ChildItem -LiteralPath $folder -Recurse -File -Filter "player.png" | Where-Object { $_.FullName -match '[\\/]png[\\/]characters[\\/]player\.png$' })
  if ($matches.Count -eq 0) { throw "Could not find modular_assets/png/characters/player.png under $folder" }
  $source = Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $matches[0].FullName))
}
$target = Join-Path $repo "starter_original\assets"
New-Item -ItemType Directory -Path $target -Force | Out-Null
Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force
$png = @(Get-ChildItem -Path (Join-Path $target "png") -Filter "*.png" -Recurse -File)
$svg = @(Get-ChildItem -Path (Join-Path $target "svg") -Filter "*.svg" -Recurse -File)
if ($png.Count -lt 28 -or $svg.Count -lt 28) {
  throw "Expected at least 28 PNG and 28 SVG sprites; found $($png.Count) PNG and $($svg.Count) SVG. No push attempted."
}
git -C $repo add -- starter_original/assets
$changes = git -C $repo diff --cached --name-only
if ($changes) {
  git -C $repo commit -m "Import complete original Moonmart modular PNG and SVG assets"
  if ($LASTEXITCODE -ne 0) { throw "Commit failed" }
  git -C $repo push origin main
  if ($LASTEXITCODE -ne 0) { throw "Push failed" }
}
Write-Host "Verified original asset import: $($png.Count) PNG and $($svg.Count) SVG."
