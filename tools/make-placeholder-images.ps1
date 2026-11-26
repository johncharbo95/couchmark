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

# ----------------------------------------------------------------------------
# UI images: player icons, focus circle, progress knob, background fade
# ----------------------------------------------------------------------------

function New-Transparent([int]$w, [int]$h) {
    $bmp = New-Object System.Drawing.Bitmap $w, $h
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    $g.Clear([System.Drawing.Color]::Transparent)
    return $bmp, $g
}

function Save-Image($bmp, $g, [string]$name) {
    $bmp.Save((Join-Path $out $name), [System.Drawing.Imaging.ImageFormat]::Png)
    $g.Dispose(); $bmp.Dispose()
    Write-Host "wrote $name"
}

function Pt([float]$x, [float]$y) { return New-Object System.Drawing.PointF $x, $y }

$whiteBrush = New-Object System.Drawing.SolidBrush $white

# Play / pause
$bmp, $g = New-Transparent 64 64
$g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@((Pt 18 10), (Pt 18 54), (Pt 54 32)))
Save-Image $bmp $g 'ic_play.png'

$bmp, $g = New-Transparent 64 64
$g.FillRectangle($whiteBrush, 14, 10, 12, 44)
$g.FillRectangle($whiteBrush, 38, 10, 12, 44)
Save-Image $bmp $g 'ic_pause.png'

# Previous / next (bar + triangle)
$bmp, $g = New-Transparent 64 64
$g.FillRectangle($whiteBrush, 12, 12, 8, 40)
$g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@((Pt 52 12), (Pt 52 52), (Pt 22 32)))
Save-Image $bmp $g 'ic_prev.png'

$bmp, $g = New-Transparent 64 64
$g.FillRectangle($whiteBrush, 44, 12, 8, 40)
$g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@((Pt 12 12), (Pt 12 52), (Pt 42 32)))
Save-Image $bmp $g 'ic_next.png'

# Back 10 / forward 10: circular arrow with "10" inside
function Draw-Circular([bool]$forward, [string]$name) {
    $bmp, $g = New-Transparent 64 64
    $pen = New-Object System.Drawing.Pen $white, 5
    if ($forward) {
        $g.DrawArc($pen, 8, 8, 48, 48, 270, -290)
        $g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@((Pt 44 8), (Pt 30 0), (Pt 30 16)))
    } else {
        $g.DrawArc($pen, 8, 8, 48, 48, 270, 290)
        $g.FillPolygon($whiteBrush, [System.Drawing.PointF[]]@((Pt 20 8), (Pt 34 0), (Pt 34 16)))
    }
    $font = New-Object System.Drawing.Font 'Segoe UI', 17, ([System.Drawing.FontStyle]::Bold), ([System.Drawing.GraphicsUnit]::Pixel)
    $fmt = New-Object System.Drawing.StringFormat
    $fmt.Alignment = 'Center'; $fmt.LineAlignment = 'Center'
    $g.DrawString('10', $font, $whiteBrush, (New-Object System.Drawing.RectangleF 8, 10, 48, 46), $fmt)
    Save-Image $bmp $g $name
}
Draw-Circular $false 'ic_back10.png'
Draw-Circular $true  'ic_fwd10.png'

# Focus circle behind the selected player button, and the progress knob
$bmp, $g = New-Transparent 112 112
$g.FillEllipse((New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(70, 255, 255, 255))), 0, 0, 111, 111)
Save-Image $bmp $g 'btn_focus.png'

$bmp, $g = New-Transparent 28 28
$g.FillEllipse($whiteBrush, 1, 1, 26, 26)
Save-Image $bmp $g 'dot.png'

# Background fade: solid app background on the left and bottom, fading to
# transparent towards the top-right, so text stays readable over artwork.
# Drawn at half size; stretched to 1920x1080 on screen.
$bmp, $g = New-Transparent 960 540
$solid = [System.Drawing.Color]::FromArgb(255, 16, 20, 24)
$clear = [System.Drawing.Color]::FromArgb(0, 16, 20, 24)
$left = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 0, 620, 540), $solid, $clear, 0.0
$g.FillRectangle($left, 0, 0, 620, 540)
$bottom = New-Object System.Drawing.Drawing2D.LinearGradientBrush (New-Object System.Drawing.Rectangle 0, 240, 960, 300), $clear, $solid, 90.0
$g.FillRectangle($bottom, 0, 241, 960, 299)
Save-Image $bmp $g 'fade.png'
