# ============================================================================
# make-placeholder-images.ps1
#
# Generates the placeholder channel icons, splash screens and loading spinner
# in images/. Replace the PNGs with real artwork any time; keep the sizes.
#
# Usage (Windows PowerShell 5.1 or later, from the repo root):
#     powershell -ExecutionPolicy Bypass -File tools/make-placeholder-images.ps1
# ============================================================================

Add-Type -AssemblyName System.Drawing

$out = Join-Path $PSScriptRoot '..\images'
New-Item -ItemType Directory -Force $out | Out-Null

$bg     = [System.Drawing.Color]::FromArgb(255, 16, 20, 24)    # #101418
$accent = [System.Drawing.Color]::FromArgb(255, 61, 126, 255)  # #3D7EFF
$white  = [System.Drawing.Color]::White

function New-Canvas([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    return $bmp, $g
}

# Logo = rounded accent square with a white "play" triangle, then the name.
function Draw-Logo($g, [int]$w, [int]$h, [bool]$withName) {
    $g.Clear($bg)
    $size = [int]([Math]::Min($w, $h) * 0.36)
    $x = [int](($w - $size) / 2)
    $y = if ($withName) { [int]($h * 0.22) } else { [int](($h - $size) / 2) }

    $r = [int]($size * 0.2)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($x, $y, $r, $r, 180, 90)
    $path.AddArc($x + $size - $r, $y, $r, $r, 270, 90)
    $path.AddArc($x + $size - $r, $y + $size - $r, $r, $r, 0, 90)
    $path.AddArc($x, $y + $size - $r, $r, $r, 90, 90)
    $path.CloseFigure()
    $g.FillPath((New-Object System.Drawing.SolidBrush $accent), $path)

    $t = $size * 0.32
    $cx = $x + $size / 2 + $t * 0.15
    $cy = $y + $size / 2
    $tri = [System.Drawing.PointF[]]@(
        (New-Object System.Drawing.PointF ($cx - $t * 0.6), ($cy - $t * 0.75)),
        (New-Object System.Drawing.PointF ($cx - $t * 0.6), ($cy + $t * 0.75)),
        (New-Object System.Drawing.PointF ($cx + $t * 0.75), $cy)
    )
    $g.FillPolygon((New-Object System.Drawing.SolidBrush $white), $tri)

    if ($withName) {
        $font = New-Object System.Drawing.Font 'Segoe UI Semibold', ([float]($h * 0.085)), ([System.Drawing.FontStyle]::Regular), ([System.Drawing.GraphicsUnit]::Pixel)
        $fmt = New-Object System.Drawing.StringFormat
        $fmt.Alignment = 'Center'
        $rect = New-Object System.Drawing.RectangleF 0, ($y + $size + $h * 0.06), $w, ($h * 0.2)
        $g.DrawString('Couchmark', $font, (New-Object System.Drawing.SolidBrush $white), $rect, $fmt)
    }
}

function Save-Logo([string]$name, [int]$w, [int]$h, [bool]$withName) {
    $bmp, $g = New-Canvas $w $h
    Draw-Logo $g $w $h $withName
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "wrote $name ($w x $h)"
}

# Sizes required by Roku for channel icons and splash screens.
Save-Logo 'icon_focus_fhd.png' 540 405 $true
Save-Logo 'icon_focus_hd.png'  290 218 $true
Save-Logo 'icon_focus_sd.png'  246 140 $true
Save-Logo 'splash_fhd.png' 1920 1080 $true
Save-Logo 'splash_hd.png'  1280 720  $true
Save-Logo 'splash_sd.png'  720  480  $true

# Spinner: transparent 96x96 ring with a gap (BusySpinner rotates it).
$bmp = New-Object System.Drawing.Bitmap 96, 96
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.Clear([System.Drawing.Color]::Transparent)
$pen = New-Object System.Drawing.Pen $accent, 9
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'
$g.DrawArc($pen, 8, 8, 80, 80, 0, 280)
$bmp.Save((Join-Path $out 'spinner.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host 'wrote spinner.png (96 x 96)'

# Watched badge: white check mark on an accent circle, 44x44 transparent.
$bmp = New-Object System.Drawing.Bitmap 44, 44
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.Clear([System.Drawing.Color]::Transparent)
$g.FillEllipse((New-Object System.Drawing.SolidBrush $accent), 1, 1, 42, 42)
$pen = New-Object System.Drawing.Pen $white, 5
$pen.StartCap = 'Round'; $pen.EndCap = 'Round'; $pen.LineJoin = 'Round'
$g.DrawLines($pen, [System.Drawing.PointF[]]@(
    (New-Object System.Drawing.PointF 12, 23),
    (New-Object System.Drawing.PointF 19, 30),
    (New-Object System.Drawing.PointF 32, 15)
))
$bmp.Save((Join-Path $out 'check.png'), [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose()
Write-Host 'wrote check.png (44 x 44)'
