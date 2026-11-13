param(
    [string]$Root = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$sourcePath = Join-Path $Root "assets/raster/environment/bellwether_parallax.png"
$artifactDir = Join-Path $Root "qa_asset_repairs"
$backupPath = Join-Path $artifactDir "bellwether_parallax_before.png"
$candidatePath = Join-Path $artifactDir "bellwether_parallax_after.png"

if (-not (Test-Path -LiteralPath $backupPath)) {
    Copy-Item -LiteralPath $sourcePath -Destination $backupPath
}

function Read-RgbaBytes([string]$Path) {
    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $bitmap.Width, $bitmap.Height)
        $data = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try {
            $stride = [Math]::Abs($data.Stride)
            $bytes = New-Object byte[] ($stride * $bitmap.Height)
            [Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
            return [pscustomobject]@{ Width = $bitmap.Width; Height = $bitmap.Height; Stride = $stride; Bytes = $bytes }
        } finally { $bitmap.UnlockBits($data) }
    } finally { $bitmap.Dispose() }
}

function Write-RgbaBytes([string]$Path, [int]$Width, [int]$Height, [int]$Stride, [byte[]]$Bytes) {
    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    try {
        $rect = [System.Drawing.Rectangle]::new(0, 0, $Width, $Height)
        $data = $bitmap.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        try { [Runtime.InteropServices.Marshal]::Copy($Bytes, 0, $data.Scan0, $Stride * $Height) }
        finally { $bitmap.UnlockBits($data) }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $bitmap.Dispose() }
}

function Save-Composite([string]$InputPath, [string]$Path, [System.Drawing.Color]$Background) {
    $source = [System.Drawing.Bitmap]::new($InputPath)
    $canvas = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    try {
        $graphics = [System.Drawing.Graphics]::FromImage($canvas)
        try {
            $graphics.Clear($Background)
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
            $graphics.DrawImageUnscaled($source, 0, 0)
        } finally { $graphics.Dispose() }
        $canvas.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    } finally { $canvas.Dispose(); $source.Dispose() }
}

$original = Read-RgbaBytes $backupPath
$candidate = $original.Bytes.Clone()
$width = $original.Width
$height = $original.Height
$stride = $original.Stride
$changed = 0

# Clear only low-alpha cyan/blue fringe pixels on the alpha boundary. The predicate
# is alpha 1..16, B>=80, B>1.15*R, B>1.05*G, and at least one transparent 8-neighbor.
# RGB bytes are retained verbatim; all other alpha and RGB bytes remain untouched.
for ($y = 1; $y -lt $height - 1; $y++) {
    for ($x = 1; $x -lt $width - 1; $x++) {
        $offset = $y * $stride + $x * 4
        $blue = [int]$original.Bytes[$offset]
        $green = [int]$original.Bytes[$offset + 1]
        $red = [int]$original.Bytes[$offset + 2]
        $alpha = [int]$original.Bytes[$offset + 3]
        if ($alpha -lt 1 -or $alpha -gt 16 -or $blue -lt 80 -or $blue -le ($red * 1.15) -or $blue -le ($green * 1.05)) { continue }

        $touchesTransparent = $false
        for ($dy = -1; $dy -le 1 -and -not $touchesTransparent; $dy++) {
            for ($dx = -1; $dx -le 1; $dx++) {
                if ($dx -eq 0 -and $dy -eq 0) { continue }
                $neighbor = ($y + $dy) * $stride + ($x + $dx) * 4
                if ($original.Bytes[$neighbor + 3] -eq 0) { $touchesTransparent = $true; break }
            }
        }
        if ($touchesTransparent) {
            $candidate[$offset + 3] = 0
            $changed++
        }
    }
}

Write-RgbaBytes $candidatePath $width $height $stride $candidate
$written = Read-RgbaBytes $candidatePath
$violations = 0
for ($y = 0; $y -lt $height; $y++) {
    for ($x = 0; $x -lt $width; $x++) {
        $offset = $y * $stride + $x * 4
        for ($channel = 0; $channel -lt 3; $channel++) {
            if ($written.Bytes[$offset + $channel] -ne $original.Bytes[$offset + $channel]) { $violations++ }
        }
        $beforeAlpha = $original.Bytes[$offset + 3]
        $afterAlpha = $written.Bytes[$offset + 3]
        if ($beforeAlpha -eq $afterAlpha) { continue }
        if ($afterAlpha -ne 0 -or $beforeAlpha -lt 1 -or $beforeAlpha -gt 16) { $violations++ }
        if ($x -eq 0 -or $y -eq 0 -or $x -ge $width - 1 -or $y -ge $height - 1) { $violations++ }
        $blue = [int]$original.Bytes[$offset]; $green = [int]$original.Bytes[$offset + 1]; $red = [int]$original.Bytes[$offset + 2]
        if ($blue -lt 80 -or $blue -le ($red * 1.15) -or $blue -le ($green * 1.05)) { $violations++ }
        $touchesTransparent = $false
        for ($dy = -1; $dy -le 1 -and -not $touchesTransparent; $dy++) {
            for ($dx = -1; $dx -le 1; $dx++) {
                if ($dx -eq 0 -and $dy -eq 0) { continue }
                $neighbor = ($y + $dy) * $stride + ($x + $dx) * 4
                if ($original.Bytes[$neighbor + 3] -eq 0) { $touchesTransparent = $true; break }
            }
        }
        if (-not $touchesTransparent) { $violations++ }
    }
}
if ($violations -ne 0) { throw "Pixel verification found $violations unexpected changes; source file was not replaced." }

$darkPreview = Join-Path $artifactDir "bellwether_parallax_dark_plum.png"
$creamPreview = Join-Path $artifactDir "bellwether_parallax_warm_cream.png"
$beforeDarkPreview = Join-Path $artifactDir "bellwether_parallax_before_dark_plum.png"
$beforeCreamPreview = Join-Path $artifactDir "bellwether_parallax_before_warm_cream.png"
Save-Composite $candidatePath $darkPreview ([System.Drawing.Color]::FromArgb(255, 31, 23, 43))
Save-Composite $candidatePath $creamPreview ([System.Drawing.Color]::FromArgb(255, 248, 234, 215))
Save-Composite $backupPath $beforeDarkPreview ([System.Drawing.Color]::FromArgb(255, 31, 23, 43))
Save-Composite $backupPath $beforeCreamPreview ([System.Drawing.Color]::FromArgb(255, 248, 234, 215))

[pscustomobject]@{
    width = $width
    height = $height
    changed_alpha_pixels = $changed
    rgb_bytes_changed = 0
    unexpected_differences = $violations
    predicate = "A=1..16; B>=80; B>1.15*R; B>1.05*G; at least one 8-neighbor has A=0; set A=0 only"
    backup = $backupPath
    candidate = $candidatePath
    previews_after = @($darkPreview, $creamPreview)
    previews_before = @($beforeDarkPreview, $beforeCreamPreview)
} | ConvertTo-Json -Depth 4
