param(
    [string]$Base64File = "",
    [string]$ZipFile = "",
    [string]$Destination = "art/concept"
)
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

if ([string]::IsNullOrWhiteSpace($Base64File) -eq [string]::IsNullOrWhiteSpace($ZipFile)) {
    throw "Provide exactly one of -Base64File or -ZipFile."
}
$root = (git rev-parse --show-toplevel).Trim()
if ($LASTEXITCODE -ne 0 -or -not $root) { throw "Run this from inside the Moonmart Git repository." }
$target = Join-Path $root $Destination
$tempDir = Join-Path ([IO.Path]::GetTempPath()) ("moonmart-art-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
try {
    $archive = Join-Path $tempDir "concept-art.zip"
    if ($Base64File) {
        if (-not (Test-Path -LiteralPath $Base64File -PathType Leaf)) { throw "Missing Base64 file: $Base64File" }
        $encoded = [IO.File]::ReadAllText((Resolve-Path -LiteralPath $Base64File).Path).Trim()
        [IO.File]::WriteAllBytes($archive, [Convert]::FromBase64String($encoded))
    } else {
        if (-not (Test-Path -LiteralPath $ZipFile -PathType Leaf)) { throw "Missing ZIP file: $ZipFile" }
        Copy-Item -LiteralPath $ZipFile -Destination $archive
    }

    Add-Type -AssemblyName System.IO.Compression
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        $entries = @($zip.Entries | Where-Object { $_.Name -ne "" })
        if ($entries.Count -eq 0) { throw "Archive contains no files." }
        foreach ($entry in $entries) {
            if ($entry.FullName -match '(^/|^\\|\.\.[/\\])') { throw "Unsafe archive entry: $($entry.FullName)" }
        }
        Write-Host "Archive validated: $($entries.Count) files."
    } finally { $zip.Dispose() }

    $staging = Join-Path $tempDir "extracted"
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Expand-Archive -LiteralPath $archive -DestinationPath $staging -Force
    New-Item -ItemType Directory -Path $target -Force | Out-Null
    Copy-Item -Path (Join-Path $staging "*") -Destination $target -Recurse -Force

    $count = @(Get-ChildItem -LiteralPath $target -Recurse -File).Count
    Write-Host "Copied $count files to $Destination"
    git -C $root add -- $Destination
    if ($LASTEXITCODE -ne 0) { throw "git add failed." }
    git -C $root diff --cached --quiet
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Nothing new to commit; art may already be imported."
        return
    }
    git -C $root commit -m "Import Moonmart concept art from verified archive"
    if ($LASTEXITCODE -ne 0) { throw "git commit failed." }
    git -C $root push origin HEAD:main
    if ($LASTEXITCODE -ne 0) { throw "git push failed. Commit remains local; check authentication or pull changes." }
    Write-Host "Moonmart concept art uploaded to GitHub."
} finally {
    Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
}
