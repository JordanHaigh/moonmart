param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$projectRootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
$sourceRoot = Join-Path $projectRootFull "art_sources"
$sourceIgnore = Join-Path $sourceRoot ".gdignore"
$archivePath = Join-Path $sourceRoot "moonmart_tea_corner.ora"
if (-not (Test-Path -LiteralPath $sourceIgnore -PathType Leaf)) {
	throw "Editable art sources must remain outside Godot's runtime import scan: $sourceIgnore"
}
if (-not (Test-Path -LiteralPath $archivePath -PathType Leaf)) {
	throw "Missing editable Tea Corner OpenRaster source: $archivePath"
}

$expectedLayers = @(
	@{ name = "Architecture $([char]0x00B7) fixed structure"; entry = "data/architecture.png"; source = "assets/raster/environment/moonmart_tea_corner_architecture.png" },
	@{ name = "Exterior parallax $([char]0x00B7) fixed scenery"; entry = "data/exterior_parallax.png"; source = "assets/raster/environment/moonmart_tea_corner_exterior_parallax.png" },
	@{ name = "Night sky $([char]0x00B7) fixed scenery"; entry = "data/night_sky.png"; source = "assets/raster/environment/moonmart_tea_corner_night_sky.png" }
)
$expectedMergedSource = "assets/raster/environment/moonmart_tea_corner.png"
$archive = [System.IO.Compression.ZipFile]::OpenRead($archivePath)
try {
	if ($archive.Entries.Count -lt 6 -or $archive.Entries[0].FullName -ne "mimetype" -or $archive.Entries[0].CompressedLength -ne $archive.Entries[0].Length) {
		throw "OpenRaster source must start with an uncompressed mimetype entry and contain all layers."
	}
	$mimetypeReader = [System.IO.StreamReader]::new($archive.GetEntry("mimetype").Open())
	try { $mimetype = $mimetypeReader.ReadToEnd() } finally { $mimetypeReader.Dispose() }
	if ($mimetype -ne "image/openraster") { throw "Editable source has an invalid OpenRaster mimetype." }
	$thumbnailEntry = $archive.GetEntry("Thumbnails/thumbnail.png")
	if ($null -eq $thumbnailEntry) { throw "OpenRaster source is missing its required thumbnail." }
	$thumbnailStream = $thumbnailEntry.Open()
	try {
		$thumbnailMemory = [System.IO.MemoryStream]::new()
		try {
			$thumbnailStream.CopyTo($thumbnailMemory)
			$thumbnailBytes = $thumbnailMemory.ToArray()
		} finally { $thumbnailMemory.Dispose() }
	} finally { $thumbnailStream.Dispose() }
	$thumbnailWidth = ([int64]$thumbnailBytes[16] -shl 24) -bor ([int64]$thumbnailBytes[17] -shl 16) -bor ([int64]$thumbnailBytes[18] -shl 8) -bor [int64]$thumbnailBytes[19]
	$thumbnailHeight = ([int64]$thumbnailBytes[20] -shl 24) -bor ([int64]$thumbnailBytes[21] -shl 16) -bor ([int64]$thumbnailBytes[22] -shl 8) -bor [int64]$thumbnailBytes[23]
	if ($thumbnailWidth -ne 256 -or $thumbnailHeight -ne 144) {
		throw "OpenRaster thumbnail must preserve the 1600x900 aspect ratio at 256x144."
	}

	$stackReader = [System.IO.StreamReader]::new($archive.GetEntry("stack.xml").Open())
	try { [xml]$stackDocument = $stackReader.ReadToEnd() } finally { $stackReader.Dispose() }
	if ($stackDocument.image.w -ne "1600" -or $stackDocument.image.h -ne "900") {
		throw "Tea Corner source canvas must remain 1600x900."
	}
	$actualLayers = @($stackDocument.image.stack.layer)
	if ($actualLayers.Count -ne $expectedLayers.Count) {
		throw "Tea Corner source layer count changed; expected exactly three fixed-scene layers."
	}
	for ($index = 0; $index -lt $expectedLayers.Count; $index++) {
		$expected = $expectedLayers[$index]
		$actual = $actualLayers[$index]
		if ([string]$actual.name -ne $expected.name -or [string]$actual.src -ne $expected.entry -or [string]$actual.x -ne "0" -or [string]$actual.y -ne "0") {
			throw "Editable source layer order or placement differs at index $index."
		}
	}

	$entriesToVerify = @($expectedLayers) + @(@{ entry = "mergedimage.png"; source = $expectedMergedSource })
	foreach ($mapping in $entriesToVerify) {
		$entry = $archive.GetEntry([string]$mapping.entry)
		$sourcePath = Join-Path $projectRootFull ([string]$mapping.source)
		if ($null -eq $entry -or -not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
			throw "Editable source layer or approved raster input is missing: $($mapping.entry)"
		}
		$entryStream = $entry.Open()
		try {
			$memoryStream = [System.IO.MemoryStream]::new()
			try {
				$entryStream.CopyTo($memoryStream)
				$sha256 = [System.Security.Cryptography.SHA256]::Create()
				try {
					$embeddedHash = [System.BitConverter]::ToString($sha256.ComputeHash($memoryStream.ToArray())).Replace("-", "")
				} finally { $sha256.Dispose() }
			} finally { $memoryStream.Dispose() }
		} finally { $entryStream.Dispose() }
		$sourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
		if ($embeddedHash -ne $sourceHash) {
			throw "Editable source entry differs from its approved raster export: $($mapping.entry)"
		}
	}
} finally { $archive.Dispose() }

Write-Output "Editable source gate passed: Tea Corner's three fixed-scene layers and merged plate match their approved PNG exports byte-for-byte."
