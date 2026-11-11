param([Parameter(Mandatory=$true)][string]$ArtZip)
$ErrorActionPreference = 'Stop'
if (-not (Test-Path -LiteralPath $ArtZip -PathType Leaf)) { throw "Art ZIP not found: $ArtZip" }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead((Resolve-Path -LiteralPath $ArtZip).Path)
try {
    if ($archive.Entries.Count -eq 0) { throw "Art ZIP is empty: $ArtZip" }
} finally {
    $archive.Dispose()
}
$root = (Resolve-Path ".").Path
$target = Join-Path $root "art_import"
New-Item -ItemType Directory -Force -Path $target | Out-Null
Expand-Archive -LiteralPath $ArtZip -DestinationPath $target -Force
if (-not (Get-ChildItem -LiteralPath $target -Force -Recurse -File | Select-Object -First 1)) {
    throw "The archive extracted no files into $target."
}
git -C $root add -- art_import
if ($LASTEXITCODE -ne 0) { throw "git add failed with exit code $LASTEXITCODE." }
git -C $root diff --cached --quiet -- art_import
if ($LASTEXITCODE -eq 0) { throw "No new artwork changes were staged from $ArtZip." }
if ($LASTEXITCODE -ne 1) { throw "Could not check staged artwork changes (exit code $LASTEXITCODE)." }
git -C $root commit -m "Import original Moonmart concept artwork and prototype assets"
if ($LASTEXITCODE -ne 0) { throw "git commit failed with exit code $LASTEXITCODE." }
git -C $root push origin main
if ($LASTEXITCODE -ne 0) { throw "git push failed with exit code $LASTEXITCODE. The import commit remains local." }
Write-Host "Art imported into art_import/ and pushed to GitHub."
