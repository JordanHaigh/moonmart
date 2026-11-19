param(
	[string]$ArtifactRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$qaRoot = Join-Path $ArtifactRoot "qa_asset_repairs"
$targets = @(
	@{
		Source = "fog_overlay_probe_01_rejected_colored_edge_fringe.png"
		Dark = "fog_overlay_probe_01_dark_plum.png"
		Cream = "fog_overlay_probe_01_warm_cream.png"
	},
	@{
		Source = "fog_overlay_probe_02_rejected_bright_edge_halo.png"
		Dark = "fog_overlay_probe_02_dark_plum.png"
		Cream = "fog_overlay_probe_02_warm_cream.png"
	},
	@{
		Source = "fog_overlay_probe_03_rejected_ai_fringe.png"
		Dark = "fog_overlay_probe_03_dark_plum.png"
		Cream = "fog_overlay_probe_03_warm_cream.png"
	},
	@{
		Source = "fog_overlay_probe_04_rejected_refinement_fringe.png"
		Dark = "fog_overlay_probe_04_dark_plum.png"
		Cream = "fog_overlay_probe_04_warm_cream.png"
	}
)

foreach ($target in $targets) {
	$sourcePath = Join-Path $qaRoot $target.Source
	if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
		throw "Missing fog probe: $sourcePath"
	}
	$source = [System.Drawing.Bitmap]::new($sourcePath)
	try {
		foreach ($preview in @(
			@{ Name = $target.Dark; Color = [System.Drawing.Color]::FromArgb(255, 31, 23, 43) },
			@{ Name = $target.Cream; Color = [System.Drawing.Color]::FromArgb(255, 248, 234, 215) }
		)) {
			$previewPath = Join-Path $qaRoot $preview.Name
			$canvas = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
			try {
				$graphics = [System.Drawing.Graphics]::FromImage($canvas)
				try {
					$graphics.Clear($preview.Color)
					$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
					$graphics.DrawImageUnscaled($source, 0, 0)
				}
				finally { $graphics.Dispose() }
				$canvas.Save($previewPath, [System.Drawing.Imaging.ImageFormat]::Png)
			}
			finally { $canvas.Dispose() }
		}
	}
	finally { $source.Dispose() }
}

Write-Output "Created dark-plum and warm-cream QA composites for all rejected fog probes."
