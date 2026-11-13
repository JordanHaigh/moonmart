param(
    [string]$SourcePath = "assets/raster/environment/old_lighthouse.png",
    [string]$OutputDirectory = "qa_asset_repairs/district_sky_probe",
    [int]$MinBlueRedDelta = 18,
    [int]$MinBlueGreenDelta = 8,
    [int]$MinAverage = 38,
    [int]$MaxY = 100000
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
$systemDrawingDirectory = Split-Path -Parent ([System.Drawing.Bitmap].Assembly.Location)
$gdiPlusReference = Join-Path $systemDrawingDirectory "System.Private.Windows.GdiPlus.dll"
$windowsCoreReference = Join-Path $systemDrawingDirectory "System.Private.Windows.Core.dll"
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location, [System.Drawing.Color].Assembly.Location, $gdiPlusReference, $windowsCoreReference) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class DistrictSkySplitProbe
{
    private static bool IsSkyColor(Color p, int minBlueRedDelta, int minBlueGreenDelta, int minAverage)
    {
        // Conservative blue-violet night-sky range, broad enough for painted
        // tonal variation while excluding warm roofs, grass, and foliage.
        // The connected-component pass prevents isolated blue fixtures from
        // being mistaken for sky.
        int average = (p.R + p.G + p.B) / 3;
        return p.A > 0 && p.B >= p.R + minBlueRedDelta && p.B >= p.G + minBlueGreenDelta && average >= minAverage && p.R <= 150 && p.G <= 155;
    }

    private static Bitmap Composite(Bitmap foreground, Color background)
    {
        Bitmap result = new Bitmap(foreground.Width, foreground.Height, PixelFormat.Format32bppArgb);
        for (int y = 0; y < foreground.Height; y++)
        for (int x = 0; x < foreground.Width; x++)
        {
            Color p = foreground.GetPixel(x, y);
            result.SetPixel(x, y, p.A > 0 ? p : background);
        }
        return result;
    }

    public static string Run(string sourcePath, string outputDirectory, int minBlueRedDelta, int minBlueGreenDelta, int minAverage, int maxY)
    {
        using (Bitmap source = new Bitmap(sourcePath))
        {
            using (Bitmap architecture = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            using (Bitmap sky = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            {
                int pixelCount = source.Width * source.Height;
                bool[] selected = new bool[pixelCount];
                bool[] queued = new bool[pixelCount];
                int[] queue = new int[pixelCount];
                int head = 0, tail = 0;

                // Start from all classifiable top-edge sky pixels and walk the
                // four-connected region. No non-connected color-matched pixels
                // can be cleared from the architecture plate.
                for (int x = 0; x < source.Width; x++)
                {
                    if (!IsSkyColor(source.GetPixel(x, 0), minBlueRedDelta, minBlueGreenDelta, minAverage)) continue;
                    int index = x;
                    if (!queued[index]) { queued[index] = true; queue[tail++] = index; }
                }
                while (head < tail)
                {
                    int index = queue[head++];
                    int x = index % source.Width;
                    int y = index / source.Width;
                    if (y > maxY) continue;
                    if (!IsSkyColor(source.GetPixel(x, y), minBlueRedDelta, minBlueGreenDelta, minAverage)) continue;
                    selected[index] = true;
                    if (x > 0 && !queued[index - 1]) { queued[index - 1] = true; queue[tail++] = index - 1; }
                    if (x + 1 < source.Width && !queued[index + 1]) { queued[index + 1] = true; queue[tail++] = index + 1; }
                    if (y > 0 && !queued[index - source.Width]) { queued[index - source.Width] = true; queue[tail++] = index - source.Width; }
                    if (y + 1 < source.Height && y + 1 <= maxY && !queued[index + source.Width]) { queued[index + source.Width] = true; queue[tail++] = index + source.Width; }
                }

                int selectedCount = 0;
                for (int y = 0; y < source.Height; y++)
                for (int x = 0; x < source.Width; x++)
                {
                    Color p = source.GetPixel(x, y);
                    int index = y * source.Width + x;
                    if (selected[index])
                    {
                        sky.SetPixel(x, y, p);
                        architecture.SetPixel(x, y, Color.FromArgb(0, p.R, p.G, p.B));
                        selectedCount++;
                    }
                    else
                    {
                        sky.SetPixel(x, y, Color.Transparent);
                        architecture.SetPixel(x, y, p);
                    }
                }

                int changed = 0;
                for (int y = 0; y < source.Height; y++)
                for (int x = 0; x < source.Width; x++)
                {
                    Color a = architecture.GetPixel(x, y);
                    Color s = sky.GetPixel(x, y);
                    Color recomposed = s.A > 0 ? s : a;
                    if (recomposed.ToArgb() != source.GetPixel(x, y).ToArgb()) changed++;
                }
                if (changed != 0) throw new InvalidDataException("Exact source-over recomposition failed; changed pixels: " + changed);
                if (selectedCount < 10000) throw new InvalidDataException("Sky flood-fill selected too few pixels to be a useful layer: " + selectedCount);

                Directory.CreateDirectory(outputDirectory);
                string assetName = Path.GetFileNameWithoutExtension(sourcePath);
                architecture.Save(Path.Combine(outputDirectory, assetName + "_architecture_candidate.png"), ImageFormat.Png);
                sky.Save(Path.Combine(outputDirectory, assetName + "_sky_candidate.png"), ImageFormat.Png);
                using (Bitmap dark = Composite(architecture, Color.FromArgb(255, 39, 29, 54)))
                    dark.Save(Path.Combine(outputDirectory, assetName + "_architecture_dark_plum.png"), ImageFormat.Png);
                using (Bitmap cream = Composite(sky, Color.FromArgb(255, 247, 238, 220)))
                    cream.Save(Path.Combine(outputDirectory, assetName + "_sky_warm_cream.png"), ImageFormat.Png);
                return "QA-only split; RGB thresholds: B-R >= " + minBlueRedDelta + ", B-G >= " + minBlueGreenDelta + ", mean >= " + minAverage + ", y <= " + Math.Min(maxY, source.Height - 1) + "; selected connected pixels: " + selectedCount + "; exact source-over recomposition changed pixels: 0.";
            }
        }
    }
}
'@

$projectRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot "..")).Path
$sourceAbsolute = (Resolve-Path -LiteralPath (Join-Path $projectRoot $SourcePath)).Path
$qaRoot = [System.IO.Path]::GetFullPath((Join-Path $projectRoot "qa_asset_repairs"))
$outputAbsolute = [System.IO.Path]::GetFullPath((Join-Path $projectRoot $OutputDirectory))
if (-not $outputAbsolute.StartsWith($qaRoot + [System.IO.Path]::DirectorySeparatorChar, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw "QA prototype output must remain inside qa_asset_repairs/: $outputAbsolute"
}
[DistrictSkySplitProbe]::Run($sourceAbsolute, $outputAbsolute, $MinBlueRedDelta, $MinBlueGreenDelta, $MinAverage, $MaxY)
