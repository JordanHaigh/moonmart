param([Parameter(Mandatory=$true)][string]$ArtZip)
$ErrorActionPreference = "Stop"
if (-not (Test-Path -LiteralPath $ArtZip)) { throw "Artwork ZIP not found: $ArtZip" }
$repo = (git rev-parse --show-toplevel).Trim()
$target = Join-Path $repo "starter_original\assets"
$tmp = Join-Path $env:TEMP ("moonmart_import_" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
try {
    Expand-Archive -LiteralPath $ArtZip -DestinationPath $tmp -Force
    $source = Join-Path $tmp "modular_assets"
    if (-not (Test-Path (Join-Path $source "png\characters\player.png"))) {
        throw "ZIP does not contain the expected modular_assets directory."
    }
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Copy-Item -Path (Join-Path $source "*") -Destination $target -Recurse -Force
    git -C $repo add -- starter_original/assets
    git -C $repo commit -m "Restore original Moonmart modular PNG and SVG starter assets"
    git -C $repo push origin main
    Write-Host "Original starter assets pushed successfully."
} finally {
    Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
}
