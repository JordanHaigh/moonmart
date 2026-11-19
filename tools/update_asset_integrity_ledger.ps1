param(
	[Parameter(Mandatory = $true)]
	[string]$RecordedBy,
	[string]$ProjectRoot = ""
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
	$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
}
$manifestPath = Join-Path $ProjectRoot "assets/raster/asset_manifest.json"
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$rasterRoot = Join-Path $ProjectRoot "assets/raster"
$records = @()

foreach ($asset in $manifest.assets | Where-Object { $_.path -like "*.png" }) {
	$assetPath = Join-Path $rasterRoot ([string]$asset.path)
	if (-not (Test-Path -LiteralPath $assetPath -PathType Leaf)) { throw "Missing raster asset: $($asset.path)" }
	$sourceRecords = @()
	foreach ($match in [regex]::Matches([string]$asset.reference, 'art_import/[^;]+')) {
		$sourcePath = $match.Value.Trim()
		$fullSourcePath = Join-Path $ProjectRoot $sourcePath
		if (-not (Test-Path -LiteralPath $fullSourcePath -PathType Leaf)) { throw "Missing art source '$sourcePath' referenced by $($asset.path)" }
		$sourceRecords += [ordered]@{
			path = $sourcePath.Replace("\", "/")
			sha256 = (Get-FileHash -LiteralPath $fullSourcePath -Algorithm SHA256).Hash
		}
	}
	if ($sourceRecords.Count -eq 0) { throw "Raster has no art_import/ reference: $($asset.path)" }
	$previewRecords = @()
	$previewPaths = @()
	if ($asset.previews) { $previewPaths = @($asset.previews) }
	elseif ($asset.qa_previews) { $previewPaths = @($asset.qa_previews) }
	foreach ($preview in $previewPaths) {
		$previewRoot = $rasterRoot
		if ([string]$preview -like "qa_asset_repairs/*") { $previewRoot = $ProjectRoot }
		$fullPreviewPath = Join-Path $previewRoot ([string]$preview)
		if (-not (Test-Path -LiteralPath $fullPreviewPath -PathType Leaf)) { throw "Missing QA preview '$preview' for $($asset.path)" }
		$previewRecords += [ordered]@{
			path = ([string]$preview).Replace("\", "/")
			sha256 = (Get-FileHash -LiteralPath $fullPreviewPath -Algorithm SHA256).Hash
		}
	}
	$records += [ordered]@{
		path = ([string]$asset.path).Replace("\", "/")
		sha256 = (Get-FileHash -LiteralPath $assetPath -Algorithm SHA256).Hash
		sources = $sourceRecords
		previews = $previewRecords
	}
}

$ledger = [ordered]@{
	review_contract = [ordered]@{
		style_reference = "art_import/"
		integrity_recorded_by = $RecordedBy
		recorded_on = (Get-Date -Format "yyyy-MM-dd")
		visual_qa_basis = "Per-asset visual QA notes in asset_manifest.json; environment plates also use environment_visual_review.json. This ledger binds those records to the current files and does not replace pixel-level inspection."
		checklist = @(
			"Capture the current SHA-256 for each manifest raster and each cited art_import/ source.",
			"Capture the current SHA-256 for each paired dark-plum and warm-cream QA preview.",
			"Keep per-asset visual QA notes and the Section 27 environment signoff as the pixel-review record.",
			"Require fresh pixel-level inspection against art_import/ before accepting any changed raster or preview."
		)
	}
	approved_rasters = $records
}
$ledgerPath = Join-Path $rasterRoot "asset_visual_review.json"
$ledger | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath $ledgerPath -Encoding utf8
Write-Output "Wrote raster/source/preview integrity ledger for $($records.Count) assets: $ledgerPath"
