param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Test-PathWithinRoot {
	param(
		[string]$RootPath,
		[string]$CandidatePath
	)
	$rootFullPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	$candidateFullPath = [System.IO.Path]::GetFullPath($CandidatePath)
	$rootPrefix = $rootFullPath + [System.IO.Path]::DirectorySeparatorChar
	return $candidateFullPath.StartsWith($rootPrefix, [System.StringComparison]::OrdinalIgnoreCase)
}

function Get-ProjectRelativePath {
	param(
		[string]$RootPath,
		[string]$TargetPath
	)

	$rootFullPath = [System.IO.Path]::GetFullPath($RootPath).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
	$rootUri = [System.Uri]::new($rootFullPath + [System.IO.Path]::DirectorySeparatorChar)
	$targetUri = [System.Uri]::new([System.IO.Path]::GetFullPath($TargetPath))
	$relativeUri = $rootUri.MakeRelativeUri($targetUri)
	return [System.Uri]::UnescapeDataString($relativeUri.ToString()).Replace('/', [string][System.IO.Path]::DirectorySeparatorChar)
}

function Get-PngDimensions {
	param([string]$Path)
	$stream = [System.IO.File]::OpenRead($Path)
	try {
		$reader = [System.IO.BinaryReader]::new($stream)
		try {
			$signature = $reader.ReadBytes(8)
			$expectedSignature = [byte[]](137, 80, 78, 71, 13, 10, 26, 10)
			$signatureMatches = $signature.Length -eq 8
			for ($index = 0; $signatureMatches -and $index -lt 8; $index++) {
				$signatureMatches = $signature[$index] -eq $expectedSignature[$index]
			}
			if (-not $signatureMatches) {
				return $null
			}
			$null = $reader.ReadBytes(4) # IHDR chunk length
			$chunkType = [System.Text.Encoding]::ASCII.GetString($reader.ReadBytes(4))
			if ($chunkType -ne "IHDR") { return $null }
			$dimensionBytes = $reader.ReadBytes(8)
			if ($dimensionBytes.Length -ne 8) { return $null }
			$width = ([int64]$dimensionBytes[0] -shl 24) -bor ([int64]$dimensionBytes[1] -shl 16) -bor ([int64]$dimensionBytes[2] -shl 8) -bor [int64]$dimensionBytes[3]
			$height = ([int64]$dimensionBytes[4] -shl 24) -bor ([int64]$dimensionBytes[5] -shl 16) -bor ([int64]$dimensionBytes[6] -shl 8) -bor [int64]$dimensionBytes[7]
			return @([int]$width, [int]$height)
		} finally {
			$reader.Dispose()
		}
	} finally {
		$stream.Dispose()
	}
}

$manifestPath = Join-Path $ProjectRoot "assets/raster/asset_manifest.json"
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
	throw "Section 27 check cannot find $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$environmentRecords = @($manifest.assets | Where-Object { $_.path -like "environment/*" })
$visualReviewRelativePath = [string]$manifest.environment_visual_review_ledger
$visualReviewPath = Join-Path (Join-Path $ProjectRoot "assets/raster") $visualReviewRelativePath
$problems = [System.Collections.Generic.List[string]]::new()
$rasterRoot = Join-Path $ProjectRoot "assets/raster"
$artImportRoot = Join-Path $ProjectRoot "art_import"
$rasterRootFull = [System.IO.Path]::GetFullPath($rasterRoot).TrimEnd([System.IO.Path]::DirectorySeparatorChar, [System.IO.Path]::AltDirectorySeparatorChar)
$rasterPrefix = $rasterRootFull + [System.IO.Path]::DirectorySeparatorChar
$environmentLayers = @(
	"architecture", "transparent_architecture_modules", "optional_room_architecture",
	"district_background", "interior_background", "story_background", "night_sky", "exterior_parallax"
)
$previewRecordCount = 0

foreach ($styleReference in $manifest.style_references) {
	$styleReferencePath = Join-Path $ProjectRoot ([string]$styleReference)
	if (-not (Test-PathWithinRoot -RootPath $artImportRoot -CandidatePath $styleReferencePath)) {
		$problems.Add("Style reference must resolve inside art_import/: $styleReference")
	} elseif (-not (Test-Path -LiteralPath $styleReferencePath -PathType Leaf)) {
		$problems.Add("Style reference is missing: $styleReference")
	}
}

if ([string]::IsNullOrWhiteSpace($visualReviewRelativePath) -or $visualReviewRelativePath.Contains("..") -or -not (Test-Path -LiteralPath $visualReviewPath -PathType Leaf)) {
	throw "Section 27 check cannot find the required visual signoff ledger: $visualReviewPath"
}
$visualReview = Get-Content -LiteralPath $visualReviewPath -Raw | ConvertFrom-Json
$reviewContract = $visualReview.review_contract
$environmentChecklistText = (@($reviewContract.checklist) -join "`n").ToLowerInvariant()
$requiredEnvironmentReviewTerms = @(
	"light rays or light particles",
	"animated or switchable glow",
	"changeable weather effects",
	"story vfx",
	"independently switchable",
	"fixed scenic moons, stars, clouds, and distant haze"
)
foreach ($requiredTerm in $requiredEnvironmentReviewTerms) {
	if (-not $environmentChecklistText.Contains($requiredTerm)) {
		$problems.Add("Section 27 visual review checklist must explicitly check for '$requiredTerm'")
	}
}
$requiredBackgroundExclusions = @("light_rays", "light_particles", "animated_or_switchable_glow", "changeable_weather_effects", "story_vfx")
$backgroundExclusions = @($manifest.layer_contract.background_excludes)
foreach ($requiredExclusion in $requiredBackgroundExclusions) {
	if ($requiredExclusion -notin $backgroundExclusions) {
		$problems.Add("Section 27 manifest must exclude '$requiredExclusion' from environment plates")
	}
}
$requiredFixedScenery = @("moon_and_astronomical_stars", "static_clouds_and_distant_haze", "fixed_fixture_illumination", "painted_reflections")
$fixedSceneryAllowed = @($manifest.layer_contract.fixed_scenery_allowed)
foreach ($sceneryType in $requiredFixedScenery) {
	if ($sceneryType -notin $fixedSceneryAllowed) {
		$problems.Add("Section 27 manifest must explicitly account for fixed scenery '$sceneryType'")
	}
}
if ([string]$manifest.layer_contract.fixed_scenery_condition -notmatch "unchanged by weather, story state, upgrades, and accessibility settings") {
	$problems.Add("Section 27 must constrain allowed fixed scenery to details unaffected by weather, story state, upgrades, and accessibility settings")
}
$approvedEnvironmentImages = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($reviewedImage in $reviewContract.approved_environment_images) {
	$reviewedPath = ([string]$reviewedImage.path).Replace("\", "/")
	if ($approvedEnvironmentImages.ContainsKey($reviewedPath)) {
		$problems.Add("Visual signoff ledger contains duplicate approval: $reviewedPath")
		continue
	}
	$approvedEnvironmentImages.Add($reviewedPath, [string]$reviewedImage.sha256)
}
if ([string]$reviewContract.style_reference -ne "art_import/" -or @($reviewContract.checklist).Count -lt 4 -or [string]::IsNullOrWhiteSpace([string]$reviewContract.reviewed_by) -or [string]$reviewContract.reviewed_by -match '^(todo|unknown|n/?a)$') {
	$problems.Add("Visual signoff ledger must record its reviewer, review date, art_import/ comparison, and complete Section 27 checklist")
}
$parsedReviewDate = [datetime]::MinValue
if (-not [datetime]::TryParseExact([string]$reviewContract.reviewed_on, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$parsedReviewDate)) {
	$problems.Add("Visual signoff ledger review date must be a valid calendar date in YYYY-MM-DD format")
}
$sourceHashes = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($sourceHashProperty in $reviewContract.source_sha256.PSObject.Properties) {
	$sourceHashes.Add([string]$sourceHashProperty.Name, [string]$sourceHashProperty.Value)
}
foreach ($styleReference in $manifest.style_references) {
	$normalizedSourceReference = ([string]$styleReference).Replace("\", "/")
	if (-not $sourceHashes.ContainsKey($normalizedSourceReference)) {
		$problems.Add("Visual signoff ledger has no source hash for style reference: $normalizedSourceReference")
		continue
	}
	$sourcePath = Join-Path $ProjectRoot $normalizedSourceReference
	if (Test-Path -LiteralPath $sourcePath -PathType Leaf) {
		$actualSourceHash = (Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash
		if ($actualSourceHash -ne $sourceHashes[$normalizedSourceReference]) {
			$problems.Add("Style reference changed after visual review; review dependent artwork and update its SHA-256: $normalizedSourceReference")
		}
	}
}
$sourceIntegrityContract = $visualReview.source_integrity_pins
if ([string]$sourceIntegrityContract.purpose -ne "File identity only; these hashes do not record visual review or approval.") {
	$problems.Add("Source integrity pins must state that hashes do not imply visual review or approval")
}
$sourceIntegrityHashes = [System.Collections.Generic.Dictionary[string,string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($sourceHashProperty in $sourceIntegrityContract.art_import_sha256.PSObject.Properties) {
	$normalizedSourcePath = ([string]$sourceHashProperty.Name).Replace("\", "/")
	if (-not (Test-PathWithinRoot -RootPath $artImportRoot -CandidatePath (Join-Path $ProjectRoot $normalizedSourcePath))) {
		$problems.Add("Source integrity path escapes art_import/: $normalizedSourcePath")
		continue
	}
	if ($sourceIntegrityHashes.ContainsKey($normalizedSourcePath)) {
		$problems.Add("Source integrity pins contain a duplicate path: $normalizedSourcePath")
		continue
	}
	$sourceIntegrityHashes.Add($normalizedSourcePath, [string]$sourceHashProperty.Value)
	$sourceFilePath = Join-Path $ProjectRoot $normalizedSourcePath
	if (-not (Test-Path -LiteralPath $sourceFilePath -PathType Leaf)) {
		$problems.Add("Missing art_import source pinned for identity: $normalizedSourcePath")
		continue
	}
	$actualSourceHash = (Get-FileHash -LiteralPath $sourceFilePath -Algorithm SHA256).Hash
	if ($actualSourceHash -ne $sourceIntegrityHashes[$normalizedSourcePath]) {
		$problems.Add("art_import source changed after identity pinning: $normalizedSourcePath")
	}
}
foreach ($sourceFile in Get-ChildItem -LiteralPath $artImportRoot -File -Filter "*.png" -Recurse) {
	$relativeSourcePath = (Get-ProjectRelativePath -RootPath $ProjectRoot -TargetPath $sourceFile.FullName).Replace("\", "/")
	if (-not $sourceIntegrityHashes.ContainsKey($relativeSourcePath)) {
		$problems.Add("art_import PNG has no source integrity pin: $relativeSourcePath")
	}
}

foreach ($asset in $environmentRecords) {
	$assetPath = Join-Path (Join-Path $ProjectRoot "assets/raster") $asset.path
	if (-not (Test-PathWithinRoot -RootPath $rasterRoot -CandidatePath $assetPath)) {
		$problems.Add("Environment asset path escapes assets/raster/: $($asset.path)")
		continue
	}
	if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
		$problems.Add("Missing environment asset: $($asset.path)")
	}
	if ($asset.layer -notin $environmentLayers) {
		$problems.Add("Unrecognized environment layer '$($asset.layer)' on $($asset.path)")
	}
	if ($null -eq $asset.PSObject.Properties["contains_vfx"] -or $asset.contains_vfx -ne $false) {
		$problems.Add("Environment art must explicitly declare contains_vfx=false: $($asset.path)")
	}
	$normalizedAssetPath = ([string]$asset.path).Replace("\", "/")
	if (-not $approvedEnvironmentImages.ContainsKey($normalizedAssetPath)) {
		$problems.Add("Environment asset has no current visual signoff against art_import/: $normalizedAssetPath")
	} elseif (Test-Path -LiteralPath $assetPath -PathType Leaf) {
		$actualHash = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
		if ($actualHash -ne $approvedEnvironmentImages[$normalizedAssetPath]) {
			$problems.Add("Environment asset changed after visual review; review it and update the SHA-256 signoff: $normalizedAssetPath")
		}
	}
	$reference = [string]$asset.reference
	if ([string]::IsNullOrWhiteSpace($reference) -or $reference -notmatch "art_import/") {
		$source = [string]$asset.source
		if ([string]::IsNullOrWhiteSpace($source) -or $source -notmatch "environment/") {
			$problems.Add("Environment art must cite art_import/ or a derived environment source: $($asset.path)")
		}
	}
}

foreach ($reviewedPath in $approvedEnvironmentImages.Keys) {
	if (-not ($environmentRecords | Where-Object { ([string]$_.path).Replace("\", "/") -eq $reviewedPath })) {
		$problems.Add("Visual signoff ledger references an asset that is not an environment record: $reviewedPath")
	}
}
if ($approvedEnvironmentImages.Count -ne $environmentRecords.Count) {
	$problems.Add("Every environment asset must have exactly one visual signoff record")
}

foreach ($asset in $manifest.assets | Where-Object { $_.path -like "*.png" }) {
	$assetLayer = [string]$asset.layer
	$assetContainsVfx = $null -ne $asset.PSObject.Properties["contains_vfx"] -and $asset.contains_vfx -eq $true
	$layerDeclaresVfx = $assetLayer -match "(^|_)vfx$"
	$assetPathDeclaresVfx = ([string]$asset.path) -match "(^|/)effects/"
	if ($layerDeclaresVfx -and -not $assetContainsVfx) {
		$problems.Add("Raster layer '$assetLayer' declares an effect, so contains_vfx must be true: $($asset.path)")
	}
	if ($assetContainsVfx -and -not $layerDeclaresVfx) {
		$problems.Add("Raster marked as VFX must use a dedicated '*_vfx' layer role: $($asset.path)")
	}
	if ($assetContainsVfx -and -not $assetPathDeclaresVfx) {
		$problems.Add("VFX raster must live under assets/raster/effects/ so it cannot be mistaken for scenery: $($asset.path)")
	}
	if ($assetPathDeclaresVfx -and -not $assetContainsVfx) {
		$problems.Add("Raster in the effects directory must explicitly declare contains_vfx=true: $($asset.path)")
	}
	$assetPath = Join-Path $rasterRoot ([string]$asset.path)
	if (-not (Test-PathWithinRoot -RootPath $rasterRoot -CandidatePath $assetPath)) {
		$problems.Add("Manifest PNG path escapes assets/raster/: $($asset.path)")
		continue
	}
	if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) {
		$problems.Add("Manifest PNG is missing from the raster pack: $($asset.path)")
		continue
	}
	$actualDimensions = Get-PngDimensions -Path $assetPath
	if ($null -eq $actualDimensions) {
		$problems.Add("Manifest raster is not a readable PNG with an IHDR header: $($asset.path)")
	} else {
		$declaredSize = @($asset.size)
		if ($declaredSize.Count -ne 2 -or [int]$declaredSize[0] -ne $actualDimensions[0] -or [int]$declaredSize[1] -ne $actualDimensions[1]) {
			$problems.Add("Manifest raster size does not match its PNG dimensions for $($asset.path): declared=$($declaredSize -join 'x') actual=$($actualDimensions -join 'x')")
		}
		$grid = @($asset.grid)
		$cellSize = @($asset.cell_size)
		if ($null -ne $asset.grid -or $null -ne $asset.cell_size) {
			if ($grid.Count -ne 2 -or [int]$grid[0] -le 0 -or [int]$grid[1] -le 0) {
				$problems.Add("Atlas metadata needs a positive two-dimensional grid: $($asset.path)")
			} elseif ($null -ne $asset.cell_size) {
				if ($cellSize.Count -ne 2 -or [double]$cellSize[0] -le 0 -or [double]$cellSize[1] -le 0) {
					$problems.Add("Atlas metadata needs positive two-dimensional cell_size values: $($asset.path)")
				} elseif ([double]$grid[0] * [double]$cellSize[0] -ne $actualDimensions[0] -or [double]$grid[1] * [double]$cellSize[1] -ne $actualDimensions[1]) {
					$problems.Add("Atlas grid and cell_size do not tile the PNG exactly: $($asset.path)")
				}
			} elseif ($actualDimensions[0] % [int]$grid[0] -ne 0 -or $actualDimensions[1] % [int]$grid[1] -ne 0) {
				$problems.Add("Atlas grid does not divide the PNG into exact integer cells: $($asset.path)")
			}
		}
	}
	if ([string]$asset.reference -notmatch "art_import/") {
		$problems.Add("Raster art must cite an art_import/ reference: $($asset.path)")
	} else {
		$referencePaths = @([regex]::Matches([string]$asset.reference, 'art_import/[^;]+') | ForEach-Object { $_.Value.Trim() })
		if ($referencePaths.Count -eq 0) {
			$problems.Add("Raster art reference could not be parsed: $($asset.path)")
		}
		foreach ($referencePath in $referencePaths) {
			$resolvedReferencePath = Join-Path $ProjectRoot $referencePath
			if (-not (Test-PathWithinRoot -RootPath $artImportRoot -CandidatePath $resolvedReferencePath)) {
				$problems.Add("Raster art reference escapes art_import/: '$referencePath' on $($asset.path)")
			} elseif (-not (Test-Path -LiteralPath $resolvedReferencePath -PathType Leaf)) {
				$problems.Add("Raster art cites a missing art_import/ reference '$referencePath': $($asset.path)")
			} elseif (-not $sourceHashes.ContainsKey($referencePath)) {
				$problems.Add("Visual signoff ledger has no source hash for '$referencePath' used by $($asset.path)")
			} else {
				$sourceHash = (Get-FileHash -LiteralPath $resolvedReferencePath -Algorithm SHA256).Hash
				if ($sourceHash -ne $sourceHashes[$referencePath]) {
					$problems.Add("Art source changed after review; update the visual signoff for '$referencePath' used by $($asset.path)")
				}
			}
		}
	}
	$requiresPreviews = ($null -ne $asset.PSObject.Properties["grid"]) -or ($asset.transparent_background -eq $true) -or ($asset.alpha -eq $true)
	if (-not $requiresPreviews) { continue }
	$previewPaths = @()
	if ($asset.previews) { $previewPaths = @($asset.previews) }
	elseif ($asset.qa_previews) { $previewPaths = @($asset.qa_previews) }
	if ($previewPaths.Count -lt 2) {
		$problems.Add("Atlas/transparent PNG needs paired dark-plum and warm-cream preview paths: $($asset.path)")
		continue
	}
	$previewRecordCount++
	foreach ($previewPath in $previewPaths) {
		$previewRoot = Join-Path $ProjectRoot "assets/raster"
		if ([string]$previewPath -like "qa_asset_repairs/*") { $previewRoot = $ProjectRoot }
		if (-not (Test-Path -LiteralPath (Join-Path $previewRoot ([string]$previewPath)) -PathType Leaf)) {
			$problems.Add("Missing preview for $($asset.path): $previewPath")
		}
	}
}

$integrityLedgerPath = Join-Path $rasterRoot "asset_visual_review.json"
if (-not (Test-Path -LiteralPath $integrityLedgerPath -PathType Leaf)) {
	$problems.Add("Missing hash-bound Section 28 visual review ledger: $integrityLedgerPath")
} else {
	$integrityLedger = Get-Content -LiteralPath $integrityLedgerPath -Raw | ConvertFrom-Json
	$integrityContract = $integrityLedger.review_contract
	if ([string]$integrityContract.style_reference -ne "art_import/" -or [string]::IsNullOrWhiteSpace([string]$integrityContract.integrity_recorded_by) -or [string]::IsNullOrWhiteSpace([string]$integrityContract.visual_qa_basis) -or @($integrityContract.checklist).Count -lt 4) {
		$problems.Add("Section 28 integrity ledger must identify its art_import/ source, QA basis, recorder, and pixel-review requirements")
	}
	$integrityDate = [datetime]::MinValue
	if (-not [datetime]::TryParseExact([string]$integrityContract.recorded_on, "yyyy-MM-dd", [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::None, [ref]$integrityDate)) {
		$problems.Add("Section 28 integrity ledger date must be a valid calendar date in YYYY-MM-DD format")
	}
	$approvedRasters = [System.Collections.Generic.Dictionary[string,object]]::new([System.StringComparer]::OrdinalIgnoreCase)
	foreach ($reviewedRaster in $integrityLedger.approved_rasters) {
		$reviewedPath = ([string]$reviewedRaster.path).Replace("\", "/")
		if ($approvedRasters.ContainsKey($reviewedPath)) {
			$problems.Add("Section 28 integrity ledger contains duplicate raster approval: $reviewedPath")
			continue
		}
		$approvedRasters.Add($reviewedPath, $reviewedRaster)
	}
	foreach ($asset in $manifest.assets | Where-Object { $_.path -like "*.png" }) {
		$assetRelativePath = ([string]$asset.path).Replace("\", "/")
		if (-not $approvedRasters.ContainsKey($assetRelativePath)) {
			$problems.Add("Section 28 integrity ledger has no current review for raster: $assetRelativePath")
			continue
		}
		$reviewedRaster = $approvedRasters[$assetRelativePath]
		$assetFullPath = Join-Path $rasterRoot $assetRelativePath
		if (Test-Path -LiteralPath $assetFullPath -PathType Leaf) {
			$actualRasterHash = (Get-FileHash -LiteralPath $assetFullPath -Algorithm SHA256).Hash
			if ($actualRasterHash -ne [string]$reviewedRaster.sha256) {
				$problems.Add("Raster changed after its Section 28 visual review; inspect against art_import/ and refresh the ledger: $assetRelativePath")
			}
		}
		$expectedSources = @([regex]::Matches([string]$asset.reference, 'art_import/[^;]+') | ForEach-Object { $_.Value.Trim().Replace("\", "/") })
		$reviewedSources = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
		foreach ($reviewedSource in $reviewedRaster.sources) {
			$sourceRelativePath = ([string]$reviewedSource.path).Replace("\", "/")
			$reviewedSources.Add($sourceRelativePath) | Out-Null
			$sourceFullPath = Join-Path $ProjectRoot $sourceRelativePath
			if (-not (Test-PathWithinRoot -RootPath $artImportRoot -CandidatePath $sourceFullPath)) {
				$problems.Add("Section 28 review source escapes art_import/: $sourceRelativePath on $assetRelativePath")
			} elseif (-not (Test-Path -LiteralPath $sourceFullPath -PathType Leaf)) {
				$problems.Add("Section 28 review source is missing: $sourceRelativePath on $assetRelativePath")
			} else {
				$actualSourceHash = (Get-FileHash -LiteralPath $sourceFullPath -Algorithm SHA256).Hash
				if ($actualSourceHash -ne [string]$reviewedSource.sha256) {
					$problems.Add("Art source changed after Section 28 review; inspect dependent art and refresh the ledger: $sourceRelativePath")
				}
			}
		}
		foreach ($expectedSource in $expectedSources) {
			if (-not $reviewedSources.Contains($expectedSource)) {
				$problems.Add("Section 28 review does not bind cited art_import/ source $expectedSource used by $assetRelativePath")
			}
		}
		$expectedPreviewPaths = @()
		if ($asset.previews) { $expectedPreviewPaths = @($asset.previews | ForEach-Object { ([string]$_).Replace("\", "/") }) }
		elseif ($asset.qa_previews) { $expectedPreviewPaths = @($asset.qa_previews | ForEach-Object { ([string]$_).Replace("\", "/") }) }
		$reviewedPreviewPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
		foreach ($reviewedPreview in $reviewedRaster.previews) {
			$previewRelativePath = ([string]$reviewedPreview.path).Replace("\", "/")
			$previewRoot = $rasterRoot
			if ($previewRelativePath -like "qa_asset_repairs/*") { $previewRoot = $ProjectRoot }
			$previewFullPath = Join-Path $previewRoot $previewRelativePath
			$reviewedPreviewPaths.Add($previewRelativePath) | Out-Null
			if (-not (Test-PathWithinRoot -RootPath $previewRoot -CandidatePath $previewFullPath)) {
				$problems.Add("Section 28 QA preview escapes its approved source root: $previewRelativePath for $assetRelativePath")
			} elseif (-not (Test-Path -LiteralPath $previewFullPath -PathType Leaf)) {
				$problems.Add("Section 28 QA preview is missing: $previewRelativePath for $assetRelativePath")
			} else {
				$actualPreviewHash = (Get-FileHash -LiteralPath $previewFullPath -Algorithm SHA256).Hash
				if ($actualPreviewHash -ne [string]$reviewedPreview.sha256) {
					$problems.Add("Section 28 QA preview changed after review; recheck it over both backgrounds: $previewRelativePath")
				}
			}
		}
		foreach ($expectedPreviewPath in $expectedPreviewPaths) {
			if (-not $reviewedPreviewPaths.Contains($expectedPreviewPath)) {
				$problems.Add("Section 28 integrity ledger does not hash the manifest QA preview $expectedPreviewPath for $assetRelativePath")
			}
		}
		if ($reviewedPreviewPaths.Count -ne $expectedPreviewPaths.Count) {
			$problems.Add("Section 28 integrity ledger preview paths do not exactly match manifest QA previews for $assetRelativePath")
		}
		$needsPairedPreviews = ($null -ne $asset.PSObject.Properties["grid"]) -or ($asset.transparent_background -eq $true) -or ($asset.alpha -eq $true)
		if ($needsPairedPreviews -and @($reviewedRaster.previews).Count -lt 2) {
			$problems.Add("Section 28 review must hash both dark-plum and warm-cream previews for transparent/atlas raster: $assetRelativePath")
		} elseif ($needsPairedPreviews) {
			$previewNames = (@($reviewedRaster.previews | ForEach-Object { ([string]$_.path).ToLowerInvariant() }) -join " ")
			if ($previewNames -notmatch "dark|plum" -or $previewNames -notmatch "cream|light") {
				$problems.Add("Section 28 preview pair must include dark-plum and warm-cream background checks: $assetRelativePath")
			}
		}
	}
	foreach ($reviewedPath in $approvedRasters.Keys) {
		if (-not ($manifest.assets | Where-Object { ([string]$_.path).Replace("\", "/") -eq $reviewedPath })) {
			$problems.Add("Section 28 integrity ledger references an uncatalogued raster: $reviewedPath")
		}
	}
	if ($approvedRasters.Count -ne @($manifest.assets | Where-Object { $_.path -like "*.png" }).Count) {
		$problems.Add("Every catalogued raster PNG must have exactly one hash-bound Section 28 review")
	}
}

$manifestPngPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($asset in $manifest.assets | Where-Object { $_.path -like "*.png" }) {
	$manifestPngPaths.Add(([string]$asset.path).Replace("\", "/")) | Out-Null
}
foreach ($rasterFile in Get-ChildItem -LiteralPath $rasterRoot -Filter "*.png" -File -Recurse) {
	$fullFilePath = [System.IO.Path]::GetFullPath($rasterFile.FullName)
	$relativePath = $fullFilePath.Substring($rasterPrefix.Length).Replace("\", "/")
	if (-not $manifestPngPaths.Contains($relativePath)) {
		$problems.Add("Raster PNG is not catalogued in the manifest: $relativePath")
	}
}

$runtimeFiles = [System.Collections.Generic.List[string]]::new()
$runtimeSceneFiles = [System.Collections.Generic.List[string]]::new()
$runtimeSourceExtensions = @(".gd", ".tscn", ".tres", ".gdshader", ".shader", ".cs")
$excludedSourcePathPattern = '[\\/](\.git|\.godot|tests|test_run_logs|godot_task_state|qa_asset_repairs|script_templates|starter_original)[\\/]'
foreach ($runtimeSource in Get-ChildItem -LiteralPath $ProjectRoot -File -Recurse) {
	if ($runtimeSource.Extension -notin $runtimeSourceExtensions) { continue }
	if ($runtimeSource.FullName -match $excludedSourcePathPattern) { continue }
	$runtimeFiles.Add($runtimeSource.FullName)
	if ($runtimeSource.Extension -eq ".tscn") {
		$runtimeSceneFiles.Add($runtimeSource.FullName)
	}
}
foreach ($dataFile in Get-ChildItem -LiteralPath (Join-Path $ProjectRoot "data") -Filter "*.json" -File -Recurse) {
	$runtimeFiles.Add($dataFile.FullName)
}
$runtimeFiles.Add((Join-Path $ProjectRoot "project.godot"))
$runtimeLightConstructors = 0
$runtimeParticleConstructors = 0
$ungatedSceneEffectNodes = [System.Collections.Generic.List[string]]::new()
$sceneNodeHeaderPattern = '^\[node\b.*\]$'

foreach ($sceneFilePath in $runtimeSceneFiles) {
	foreach ($line in Get-Content -LiteralPath $sceneFilePath) {
		if ($line -match $sceneNodeHeaderPattern) {
			$nodeNameMatch = [regex]::Match($line, '\bname="([^"]*)"')
			$nodeTypeMatch = [regex]::Match($line, '\btype="([^"]+)"')
			$nodeParentMatch = [regex]::Match($line, '\bparent="([^"]*)"')
			if (-not $nodeNameMatch.Success -or -not $nodeTypeMatch.Success) { continue }
			$nodeName = [string]$nodeNameMatch.Groups[1].Value
			$nodeType = [string]$nodeTypeMatch.Groups[1].Value
			$nodeParent = [string]$nodeParentMatch.Groups[1].Value
			if ($nodeType -match '^(PointLight2D|DirectionalLight2D|Light2D|CPUParticles2D|GPUParticles2D)$' -and $nodeParent -notmatch '(^|/)(SeparateLightingLayer|WindowEffectsLayer|WeatherEffectsLayer|StoryEffectsLayer|ForegroundEffectsLayer|PropEffectsLayer)(/|$)') {
				$relativeScene = (Get-ProjectRelativePath -RootPath $ProjectRoot -TargetPath $sceneFilePath).Replace([string][System.IO.Path]::DirectorySeparatorChar, "/")
				$ungatedSceneEffectNodes.Add("$($relativeScene):$nodeName ($nodeType under $nodeParent)")
			}
		}
	}
}
foreach ($runtimeFile in $runtimeFiles) {
	if (-not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)) { continue }
	$content = Get-Content -LiteralPath $runtimeFile -Raw
	$runtimeLightConstructors += [regex]::Matches($content, '\b(?:PointLight2D|DirectionalLight2D|Light2D)\.new\s*\(').Count
	$runtimeParticleConstructors += [regex]::Matches($content, '\b(?:CPUParticles2D|GPUParticles2D)\.new\s*\(').Count
}
$mainScriptContent = Get-Content -LiteralPath (Join-Path $ProjectRoot "scripts/main.gd") -Raw
$requiredEffectParentContracts = @(
	'separate_lighting_layer.add_child(moon_glow)',
	'separate_lighting_layer.add_child(pip_glow)',
	'lighting_layer.add_child(placed_fixture_light)',
	'var weather_layer_name := "WindowEffectsLayer" if is_tea_corner else "WeatherEffectsLayer"',
	'var weather_layer := current_location_scene.get_node_or_null(weather_layer_name) as Node2D',
	'"KettleSteamVFX", prop_effects_layer)',
	'"PhotographStarSparkle", prop_effects_layer)'
)
foreach ($effectParentContract in $requiredEffectParentContracts) {
	if (-not $mainScriptContent.Contains($effectParentContract)) {
		$problems.Add("Section 27 runtime effect producer must remain attached to its dedicated gated layer: missing '$effectParentContract'")
	}
}
if ($runtimeLightConstructors -ne 3) {
	$problems.Add("Section 27 expects exactly the three reviewed runtime Light2D constructors (shop halo, Pip story glow, and placed fixture); found $runtimeLightConstructors. Review and explicitly layer-gate every new light.")
}
if ($runtimeParticleConstructors -gt 0) {
	$problems.Add("Section 27 currently approves no runtime CPUParticles2D/GPUParticles2D constructors; use the reviewed raster effect layers or explicitly review and gate every new particle producer.")
}
foreach ($ungatedEffectNode in $ungatedSceneEffectNodes) {
	$problems.Add("Section 27 scene effect node must be parented to a dedicated gated layer: $ungatedEffectNode")
}
$mainScriptPath = Join-Path $ProjectRoot "scripts/main.gd"
if (Test-Path -LiteralPath $mainScriptPath -PathType Leaf) {
	$requiredLayerControlContract = @(
		'func set_environment_layer_enabled(',
		'environment_layer_overrides[layer_name] = enabled',
		'layers["location_night_sky"] = current_location_scene.get_node_or_null("NightSkyLayer")',
		'layers["location_exterior_parallax"] = current_location_scene.get_node_or_null("ExteriorParallaxLayer")',
		'"NightSkyLayer": return "location_night_sky"',
		'"ExteriorParallaxLayer": return "location_exterior_parallax"',
		'if layer_name in ["NightSkyLayer", "ExteriorParallaxLayer"]:',
		'_apply_environment_layer_visibility(_location_layer_setting_name(String(layer_name)), layer)'
	)
	foreach ($requiredControl in $requiredLayerControlContract) {
		if (-not $mainScriptContent.Contains($requiredControl)) {
			$problems.Add("Section 27 requires district sky/parallax layers to be independently switchable and retain per-layer overrides: missing '$requiredControl'")
		}
	}
	foreach ($receiverRange in $manifest.layer_contract.light_receiver_z_ranges.PSObject.Properties) {
		$lightNode = [string]$receiverRange.Name
		$bounds = @($receiverRange.Value)
		if ($bounds.Count -ne 2) {
			$problems.Add("Section 27 light receiver range for $lightNode must contain [z_min, z_max]")
			continue
		}
		$minAssignment = "$lightNode.range_z_min = $($bounds[0])"
		$maxAssignment = "$lightNode.range_z_max = $($bounds[1])"
		if (-not $mainScriptContent.Contains($minAssignment) -or -not $mainScriptContent.Contains($maxAssignment)) {
			$problems.Add("Section 27 Light2D receiver range differs from the manifest for $lightNode")
		}
	}
} else {
	$problems.Add("Section 27 requires scripts/main.gd to enforce Light2D receiver ranges")
}
$referencedEnvironmentPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($runtimeFile in $runtimeFiles) {
	if (-not (Test-Path -LiteralPath $runtimeFile -PathType Leaf)) { continue }
	$content = Get-Content -LiteralPath $runtimeFile -Raw
	if ($content -match 'res://[^"\s]*\.svg') {
		$problems.Add("Runtime art must use the raster production pack, not SVG: $runtimeFile")
	}
	foreach ($match in [regex]::Matches($content, 'res://assets/raster/environment/([^"\s]+)')) {
		$referencedEnvironmentPaths.Add("environment/$($match.Groups[1].Value)") | Out-Null
	}
}

$manifestPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($asset in $environmentRecords) { $manifestPaths.Add([string]$asset.path) | Out-Null }
foreach ($assetPath in $referencedEnvironmentPaths) {
	if (-not $manifestPaths.Contains($assetPath)) {
		$problems.Add("Runtime environment art is missing from the manifest: $assetPath")
	}
}

$editableSourceValidatorPath = Join-Path $PSScriptRoot "validate_art_sources.ps1"
if (Test-Path -LiteralPath $editableSourceValidatorPath -PathType Leaf) {
	& $editableSourceValidatorPath -ProjectRoot $ProjectRoot
} else {
	$problems.Add("Section 32 editable raster sources require tools/validate_art_sources.ps1")
}

if ($problems.Count -gt 0) {
	$problems | ForEach-Object { Write-Error $_ }
	throw "Section 27 metadata gate failed with $($problems.Count) issue(s). Review the image itself for baked light rays, particles, changing glow, weather effects, or story VFX as well."
}

Write-Output "Section 27/28 art gate passed for $($environmentRecords.Count) visually reviewed clean environment plates, $(@($manifest.assets | Where-Object { $_.path -like '*.png' }).Count) hash-bound raster assets, and $previewRecordCount paired atlas/transparent previews. New or revised art requires fresh visual review against art_import/."
