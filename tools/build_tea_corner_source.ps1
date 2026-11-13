param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
	[string]$OutputPath = "art_sources/moonmart_tea_corner.ora"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
Add-Type -AssemblyName System.Drawing

$projectRootFull = [System.IO.Path]::GetFullPath($ProjectRoot)
$outputFull = [System.IO.Path]::GetFullPath((Join-Path $projectRootFull $OutputPath))
$sourceFiles = [ordered]@{
	"data/architecture.png" = "assets/raster/environment/moonmart_tea_corner_architecture.png"
	"data/exterior_parallax.png" = "assets/raster/environment/moonmart_tea_corner_exterior_parallax.png"
	"data/night_sky.png" = "assets/raster/environment/moonmart_tea_corner_night_sky.png"
	"mergedimage.png" = "assets/raster/environment/moonmart_tea_corner.png"
}
$sourcePaths = @{}
foreach ($entryName in $sourceFiles.Keys) {
	$sourcePath = Join-Path $projectRootFull $sourceFiles[$entryName]
	if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
		throw "Editable source package is missing its approved raster layer: $sourcePath"
	}
	$bytes = [System.IO.File]::ReadAllBytes($sourcePath)
	if ($bytes.Length -lt 24 -or [System.Text.Encoding]::ASCII.GetString($bytes, 1, 3) -ne "PNG") {
		throw "Expected a PNG layer: $sourcePath"
	}
	$width = ([int64]$bytes[16] -shl 24) -bor ([int64]$bytes[17] -shl 16) -bor ([int64]$bytes[18] -shl 8) -bor [int64]$bytes[19]
	$height = ([int64]$bytes[20] -shl 24) -bor ([int64]$bytes[21] -shl 16) -bor ([int64]$bytes[22] -shl 8) -bor [int64]$bytes[23]
	if ($width -ne 1600 -or $height -ne 900) {
		throw "Expected 1600x900 for all exact-split layers, got ${width}x${height}: $sourcePath"
	}
	$sourcePaths[$entryName] = $sourcePath
}

$outputDirectory = Split-Path -Parent $outputFull
New-Item -ItemType Directory -Force -Path $outputDirectory | Out-Null
if (Test-Path -LiteralPath $outputFull -PathType Leaf) {
	Remove-Item -LiteralPath $outputFull -Force
}

$fileStream = [System.IO.File]::Open($outputFull, [System.IO.FileMode]::CreateNew, [System.IO.FileAccess]::ReadWrite, [System.IO.FileShare]::None)
try {
	$archive = [System.IO.Compression.ZipArchive]::new($fileStream, [System.IO.Compression.ZipArchiveMode]::Create, $true)
	try {
		$mimetypeEntry = $archive.CreateEntry("mimetype", [System.IO.Compression.CompressionLevel]::NoCompression)
		$mimetypeStream = $mimetypeEntry.Open()
		try {
			$mimetypeBytes = [System.Text.Encoding]::ASCII.GetBytes("image/openraster")
			$mimetypeStream.Write($mimetypeBytes, 0, $mimetypeBytes.Length)
		} finally { $mimetypeStream.Dispose() }

		$stackXml = @'
<?xml version="1.0" encoding="UTF-8"?>
<image version="0.0.1" w="1600" h="900" name="Moonmart Tea Corner · Section 27 layered environment">
  <stack>
    <layer name="Architecture · fixed structure" src="data/architecture.png" x="0" y="0" opacity="1.0" visibility="visible" composite-op="svg:src-over" />
    <layer name="Exterior parallax · fixed scenery" src="data/exterior_parallax.png" x="0" y="0" opacity="1.0" visibility="visible" composite-op="svg:src-over" />
    <layer name="Night sky · fixed scenery" src="data/night_sky.png" x="0" y="0" opacity="1.0" visibility="visible" composite-op="svg:src-over" />
  </stack>
</image>
'@
		$stackEntry = $archive.CreateEntry("stack.xml", [System.IO.Compression.CompressionLevel]::Optimal)
		$stackStream = $stackEntry.Open()
		try {
			$stackBytes = [System.Text.UTF8Encoding]::new($false).GetBytes($stackXml.TrimStart())
			$stackStream.Write($stackBytes, 0, $stackBytes.Length)
		} finally { $stackStream.Dispose() }

		foreach ($entryName in $sourceFiles.Keys) {
			$entry = $archive.CreateEntry($entryName, [System.IO.Compression.CompressionLevel]::NoCompression)
			$entryStream = $entry.Open()
			try {
				$sourceStream = [System.IO.File]::OpenRead($sourcePaths[$entryName])
				try { $sourceStream.CopyTo($entryStream) } finally { $sourceStream.Dispose() }
			} finally { $entryStream.Dispose() }
		}

		$thumbnail = [System.Drawing.Bitmap]::new(256, 144)
		$graphics = [System.Drawing.Graphics]::FromImage($thumbnail)
		$mergedImage = [System.Drawing.Image]::FromFile($sourcePaths["mergedimage.png"])
		try {
			$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
			$graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
			$graphics.DrawImage($mergedImage, 0, 0, 256, 144)
			$thumbnailStream = [System.IO.MemoryStream]::new()
			try {
				$thumbnail.Save($thumbnailStream, [System.Drawing.Imaging.ImageFormat]::Png)
				$thumbnailEntry = $archive.CreateEntry("Thumbnails/thumbnail.png", [System.IO.Compression.CompressionLevel]::Optimal)
				$thumbnailEntryStream = $thumbnailEntry.Open()
				try {
					$thumbnailBytes = $thumbnailStream.ToArray()
					$thumbnailEntryStream.Write($thumbnailBytes, 0, $thumbnailBytes.Length)
				} finally { $thumbnailEntryStream.Dispose() }
			} finally { $thumbnailStream.Dispose() }
		} finally {
			$mergedImage.Dispose()
			$graphics.Dispose()
			$thumbnail.Dispose()
		}
	} finally { $archive.Dispose() }
} finally { $fileStream.Dispose() }

Write-Output "Built editable Tea Corner OpenRaster source from four unchanged, 1600x900 PNG files: $outputFull"
