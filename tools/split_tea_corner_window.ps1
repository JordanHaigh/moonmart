param(
    [string]$SourcePath = "assets/raster/environment/moonmart_tea_corner.png",
    [string]$OutputDirectory = "assets/raster/environment"
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing
Add-Type -ReferencedAssemblies @([System.Drawing.Bitmap].Assembly.Location) -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Imaging;
using System.IO;

public static class TeaCornerWindowSplit
{
    private static readonly Point[][] Panes = new Point[][]
    {
        new Point[] { new Point(792,252), new Point(792,237), new Point(799,220), new Point(812,204), new Point(830,191), new Point(850,182), new Point(875,178), new Point(875,252) },
        new Point[] { new Point(894,179), new Point(968,179), new Point(968,252), new Point(894,252) },
        new Point[] { new Point(992,179), new Point(1058,179), new Point(1058,252), new Point(992,252) },
        new Point[] { new Point(1080,178), new Point(1100,182), new Point(1118,191), new Point(1135,204), new Point(1148,220), new Point(1153,237), new Point(1153,252), new Point(1080,252) },
        new Point[] { new Point(770,268), new Point(874,268), new Point(874,335), new Point(770,335) },
        new Point[] { new Point(895,268), new Point(968,268), new Point(968,335), new Point(895,335) },
        new Point[] { new Point(992,268), new Point(1058,268), new Point(1058,335), new Point(992,335) },
        new Point[] { new Point(1081,268), new Point(1150,268), new Point(1150,335), new Point(1081,335) },
        new Point[] { new Point(770,354), new Point(874,354), new Point(874,425), new Point(770,425) },
        new Point[] { new Point(895,354), new Point(968,354), new Point(968,425), new Point(895,425) },
        new Point[] { new Point(992,354), new Point(1058,354), new Point(1058,425), new Point(992,425) },
        new Point[] { new Point(1081,354), new Point(1150,354), new Point(1150,425), new Point(1081,425) }
    };

    private static bool Contains(Point[] polygon, double x, double y)
    {
        bool inside = false;
        int j = polygon.Length - 1;
        for (int i = 0; i < polygon.Length; i++)
        {
            double xi = polygon[i].X, yi = polygon[i].Y;
            double xj = polygon[j].X, yj = polygon[j].Y;
            if ((yi > y) != (yj > y) && x < (xj - xi) * (y - yi) / (yj - yi) + xi)
                inside = !inside;
            j = i;
        }
        return inside;
    }

    private static bool IsPane(int x, int y)
    {
        foreach (Point[] polygon in Panes)
            if (Contains(polygon, x + 0.5, y + 0.5)) return true;
        return false;
    }

    private static bool IsPaintedFrame(Color p)
    {
        // Warm/coral joinery has a red-over-green edge; keep those pixels on
        // the architecture layer even where conservative pane masks touch it.
        return (p.R < 235 && p.G < 160 && p.R - p.G > 25 && p.R - p.B > 30 && p.B < p.R * 0.82);
    }

    public static string Run(string sourcePath, string outputDirectory)
    {
        using (Bitmap source = new Bitmap(sourcePath))
        {
            if (source.Width != 1600 || source.Height != 900)
                throw new InvalidDataException("Expected 1600x900 source plate, got " + source.Width + "x" + source.Height + ".");

            using (Bitmap architecture = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            using (Bitmap sky = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            using (Bitmap parallax = new Bitmap(source.Width, source.Height, PixelFormat.Format32bppArgb))
            {
                int skyCount = 0, parallaxCount = 0;
                for (int y = 0; y < source.Height; y++)
                for (int x = 0; x < source.Width; x++)
                {
                    Color p = source.GetPixel(x, y);
                    if (IsPane(x, y) && !IsPaintedFrame(p))
                    {
                        // Clear alpha only on the derived architecture texture; RGB is retained.
                        architecture.SetPixel(x, y, Color.FromArgb(0, p.R, p.G, p.B));
                        if (p.B < 145 && p.R < 140) { parallax.SetPixel(x, y, p); parallaxCount++; }
                        else { sky.SetPixel(x, y, p); skyCount++; }
                    }
                    else
                    {
                        architecture.SetPixel(x, y, p);
                        sky.SetPixel(x, y, Color.Transparent);
                        parallax.SetPixel(x, y, Color.Transparent);
                    }
                }

                int changed = 0;
                for (int y = 0; y < source.Height; y++)
                for (int x = 0; x < source.Width; x++)
                {
                    Color basePixel = architecture.GetPixel(x, y);
                    Color skyPixel = sky.GetPixel(x, y);
                    Color parallaxPixel = parallax.GetPixel(x, y);
                    Color composed = parallaxPixel.A > 0 ? parallaxPixel : (skyPixel.A > 0 ? skyPixel : basePixel);
                    if (composed.ToArgb() != source.GetPixel(x, y).ToArgb()) changed++;
                }
                if (changed != 0) throw new InvalidDataException("Exact recomposition failed; changed pixel count: " + changed + ".");

                RequireLayer(architecture, sky, parallax, 930, 210, "night sky");
                RequireLayer(architecture, sky, parallax, 1020, 220, "night sky");
                RequireLayer(architecture, sky, parallax, 1120, 220, "exterior parallax");
                RequireLayer(architecture, sky, parallax, 850, 180, "architecture");
                RequireLayer(architecture, sky, parallax, 885, 200, "architecture");

                Directory.CreateDirectory(outputDirectory);
                architecture.Save(Path.Combine(outputDirectory, "moonmart_tea_corner_architecture.png"), ImageFormat.Png);
                sky.Save(Path.Combine(outputDirectory, "moonmart_tea_corner_night_sky.png"), ImageFormat.Png);
                parallax.Save(Path.Combine(outputDirectory, "moonmart_tea_corner_exterior_parallax.png"), ImageFormat.Png);
                return "Exact 1600x900 split verified; recomposition changed pixels: 0; sky pixels: " + skyCount + "; parallax pixels: " + parallaxCount + ".";
            }
        }
    }

    private static void RequireLayer(Bitmap architecture, Bitmap sky, Bitmap parallax, int x, int y, string expected)
    {
        bool inArchitecture = architecture.GetPixel(x, y).A > 0;
        bool inSky = sky.GetPixel(x, y).A > 0;
        bool inParallax = parallax.GetPixel(x, y).A > 0;
        bool valid = expected == "architecture" ? inArchitecture && !inSky && !inParallax
            : expected == "night sky" ? !inArchitecture && inSky && !inParallax
            : !inArchitecture && !inSky && inParallax;
        if (!valid) throw new InvalidDataException("Representative pixel (" + x + "," + y + ") is not assigned to " + expected + ".");
    }
}
'@

$sourceAbsolute = (Resolve-Path -LiteralPath $SourcePath).Path
$outputAbsolute = (Resolve-Path -LiteralPath $OutputDirectory).Path
[TeaCornerWindowSplit]::Run($sourceAbsolute, $outputAbsolute)
