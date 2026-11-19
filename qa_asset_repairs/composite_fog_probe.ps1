param(
	[string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$qaRoot = Join-Path $ProjectRoot "qa_asset_repairs"
$candidates = @(
	@{ Source = "fog_overlay_probe_01_rejected_colored_edge_fringe.png"; Id = "01" },
	@{ Source = "fog_overlay_probe_02_rejected_bright_edge_halo.png"; Id = "02" },
	@{ Source = "fog_overlay_probe_03_rejected_ai_fringe.png"; Id = "03" },
	@{ Source = "fog_overlay_probe_04_rejected_refinement_fringe.png"; Id = "04" }
)
$locations = @(
	@{ Source = "moonwater_harbour.png"; Name = "moonwater_harbour" },
	@{ Source = "old_lighthouse.png"; Name = "old_lighthouse" }
)

foreach ($candidate in $candidates) {
	$fogPath = Join-Path $qaRoot $candidate.Source
	$fog = [System.Drawing.Bitmap]::new($fogPath)
	foreach ($location in $locations) {
		$platePath = Join-Path $ProjectRoot (Join-Path "assets/raster/environment" $location.Source)
		$plate = [System.Drawing.Bitmap]::new($platePath)
		$attributes = [System.Drawing.Imaging.ImageAttributes]::new()
		$matrix = [System.Drawing.Imaging.ColorMatrix]::new()
		$matrix.Matrix33 = 0.35
		$attributes.SetColorMatrix($matrix, [System.Drawing.Imaging.ColorMatrixFlag]::Default, [System.Drawing.Imaging.ColorAdjustType]::Bitmap)
		try {
			$graphics = [System.Drawing.Graphics]::FromImage($plate)
			try {
				$graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
				$graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
				$destination = [System.Drawing.Rectangle]::new(0, -270, $plate.Width, $plate.Height)
				$graphics.DrawImage($fog, $destination, 0, 0, $fog.Width, $fog.Height, [System.Drawing.GraphicsUnit]::Pixel, $attributes)
			}
			finally { $graphics.Dispose() }
			$outputName = "fog_probe_{0}_{1}_composite.png" -f $candidate.Id, $location.Name
			$plate.Save((Join-Path $qaRoot $outputName), [System.Drawing.Imaging.ImageFormat]::Png)
		}
		finally {
			$attributes.Dispose()
			$plate.Dispose()
		}
	}
	$fog.Dispose()
}

Write-Output "Created low-opacity fog composites for all candidates over Harbour and Lighthouse plates."
