param(
    [string]$SourcePath = "qa_asset_repairs/source_inputs/characters/agnes_talk_pose_source.png",
    [string]$OutputPath = "assets/raster/characters/agnes_talk_pose.png",
    [string]$DarkPreviewPath = "assets/raster/characters/agnes_talk_pose_preview_dark.png",
    [string]$CreamPreviewPath = "assets/raster/characters/agnes_talk_pose_preview_cream.png"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$source = [System.Drawing.Bitmap]::new((Resolve-Path $SourcePath).Path)
try {
    if ($source.Width * 724 -ne $source.Height * 543) {
        throw "Source aspect ratio must match a 543 x 724 atlas cell."
    }

    $pose = [System.Drawing.Bitmap]::new(543, 724, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($pose)
        try {
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.DrawImage($source, [System.Drawing.Rectangle]::new(0, 0, 543, 724), 0, 0, $source.Width, $source.Height, [System.Drawing.GraphicsUnit]::Pixel)
        }
        finally { $graphics.Dispose() }
        $pose.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)

        foreach ($preview in @(
            @{ Path = $DarkPreviewPath; Color = [System.Drawing.Color]::FromArgb(255, 35, 27, 48) },
            @{ Path = $CreamPreviewPath; Color = [System.Drawing.Color]::FromArgb(255, 246, 233, 211) }
        )) {
            $canvas = [System.Drawing.Bitmap]::new(543, 724, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
            try {
                $canvasGraphics = [System.Drawing.Graphics]::FromImage($canvas)
                try {
                    $canvasGraphics.Clear($preview.Color)
                    $canvasGraphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                    $canvasGraphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                    $canvasGraphics.DrawImageUnscaled($pose, 0, 0)
                }
                finally { $canvasGraphics.Dispose() }
                $canvas.Save($preview.Path, [System.Drawing.Imaging.ImageFormat]::Png)
            }
            finally { $canvas.Dispose() }
        }
    }
    finally { $pose.Dispose() }
}
finally { $source.Dispose() }

Write-Output "Prepared Agnes talk pose: $OutputPath (543 x 724 RGBA)"
