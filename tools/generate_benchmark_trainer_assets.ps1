$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing

$root = Split-Path -Parent $PSScriptRoot
$artDir = Join-Path $root "assets\art"
$outPath = Join-Path $artDir "benchmark_arena_bg.png"
$rand = [System.Random]::new(42917)

function New-Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function New-ColorAlpha($hex, $alpha) {
    $c = New-Color $hex
    return [System.Drawing.Color]::FromArgb($alpha, $c.R, $c.G, $c.B)
}

function New-Brush($hex, $alpha = 255) {
    return New-Object System.Drawing.SolidBrush (New-ColorAlpha $hex $alpha)
}

function New-Pen($hex, $width, $alpha = 255) {
    $pen = New-Object System.Drawing.Pen (New-ColorAlpha $hex $alpha), $width
    $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
    $pen.LineJoin = [System.Drawing.Drawing2D.LineJoin]::Round
    return $pen
}

function Get-Rand($min, $max) {
    return $min + ($script:rand.NextDouble() * ($max - $min))
}

function Draw-JitterLine($g, $x1, $y1, $x2, $y2, $hex, $width = 4, $alpha = 255, $jitter = 2.5, $segments = 9) {
    $pen = New-Pen $hex $width $alpha
    $dx = $x2 - $x1
    $dy = $y2 - $y1
    $len = [Math]::Sqrt(($dx * $dx) + ($dy * $dy))
    if ($len -lt 0.01) {
        $pen.Dispose()
        return
    }
    $nx = -$dy / $len
    $ny = $dx / $len
    $pts = New-Object System.Drawing.PointF[] ($segments + 1)
    for ($i = 0; $i -le $segments; $i++) {
        $t = $i / $segments
        $offset = if ($i -eq 0 -or $i -eq $segments) { 0 } else { Get-Rand (-$jitter) $jitter }
        $x = $x1 + ($dx * $t) + ($nx * $offset)
        $y = $y1 + ($dy * $t) + ($ny * $offset)
        $pts[$i] = [System.Drawing.PointF]::new([single]$x, [single]$y)
    }
    $g.DrawLines($pen, $pts)
    $pen.Dispose()
}

function Draw-ScribbleRect($g, $rect, $hex, $alpha = 62, $spacing = 18, $width = 3) {
    $oldClip = $g.Clip.Clone()
    $g.SetClip($rect)
    $pen = New-Pen $hex $width $alpha
    for ($x = $rect.Left - $rect.Height; $x -lt $rect.Right + $rect.Height; $x += $spacing) {
        $g.DrawLine($pen, [single]$x, [single]$rect.Bottom, [single]($x + $rect.Height), [single]$rect.Top)
    }
    $pen.Dispose()
    $g.Clip = $oldClip
    $oldClip.Dispose()
}

function Draw-WobblyRect($g, $x, $y, $w, $h, $fillHex, $borderHex = "#151515", $borderWidth = 6, $scribbleHex = $null) {
    $shadow = New-Brush "#000000" 24
    $g.FillRectangle($shadow, $x + 8, $y + 9, $w, $h)
    $shadow.Dispose()

    $brush = New-Brush $fillHex
    $rect = [System.Drawing.RectangleF]::new([single]$x, [single]$y, [single]$w, [single]$h)
    $g.FillRectangle($brush, $rect)
    $brush.Dispose()

    if ($scribbleHex -ne $null) {
        Draw-ScribbleRect $g $rect $scribbleHex 68 17 3
    }

    Draw-JitterLine $g $x $y ($x + $w) ($y + 1) $borderHex $borderWidth 255 2.0 12
    Draw-JitterLine $g ($x + $w) $y ($x + $w - 2) ($y + $h) $borderHex $borderWidth 255 2.0 9
    Draw-JitterLine $g ($x + $w) ($y + $h) $x ($y + $h - 1) $borderHex $borderWidth 255 2.0 12
    Draw-JitterLine $g $x ($y + $h) ($x + 1) $y $borderHex $borderWidth 255 2.0 9
}

function Draw-Polygon($g, $points, $fillHex, $borderHex = "#151515", $width = 6, $scribbleHex = $null) {
    $pts = New-Object System.Drawing.PointF[] $points.Count
    for ($i = 0; $i -lt $points.Count; $i++) {
        $pts[$i] = [System.Drawing.PointF]::new([single]$points[$i][0], [single]$points[$i][1])
    }
    $brush = New-Brush $fillHex
    $g.FillPolygon($brush, $pts)
    $brush.Dispose()
    if ($scribbleHex -ne $null) {
        $bounds = [System.Drawing.RectangleF]::Empty
        foreach ($pt in $pts) {
            if ($bounds.IsEmpty) {
                $bounds = [System.Drawing.RectangleF]::new($pt.X, $pt.Y, 1, 1)
            } else {
                $bounds = [System.Drawing.RectangleF]::Union($bounds, [System.Drawing.RectangleF]::new($pt.X, $pt.Y, 1, 1))
            }
        }
        Draw-ScribbleRect $g $bounds $scribbleHex 52 18 3
    }
    $pen = New-Pen $borderHex $width
    $g.DrawPolygon($pen, $pts)
    $pen.Dispose()
}

function Draw-StarBurst($g, $cx, $cy, $r, $hex, $alpha = 230) {
    for ($i = 0; $i -lt 10; $i++) {
        $angle = [Math]::PI * 2 * $i / 10
        $x1 = $cx + [Math]::Cos($angle) * ($r * 0.38)
        $y1 = $cy + [Math]::Sin($angle) * ($r * 0.38)
        $x2 = $cx + [Math]::Cos($angle) * $r
        $y2 = $cy + [Math]::Sin($angle) * $r
        Draw-JitterLine $g $x1 $y1 $x2 $y2 $hex 5 $alpha 1.2 3
    }
}

function Draw-SoftPaperTexture($g, $w, $h) {
    $bg = New-Brush "#fff1cf"
    $g.FillRectangle($bg, 0, 0, $w, $h)
    $bg.Dispose()

    $palette = @("#ffd65b", "#65cfff", "#ff8a6f", "#72d66f", "#b893ff")
    for ($i = 0; $i -lt 220; $i++) {
        $color = $palette[$rand.Next(0, $palette.Count)]
        $x = Get-Rand (-40) $w
        $y = Get-Rand (-30) $h
        $x2 = $x + (Get-Rand 80 220)
        $y2 = $y + (Get-Rand (-26) 26)
        Draw-JitterLine $g $x $y $x2 $y2 $color (Get-Rand 1.5 4.0) 28 8.0 5
    }

    for ($i = 0; $i -lt 120; $i++) {
        $brush = New-Brush "#151515" 14
        $s = Get-Rand 2 6
        $g.FillEllipse($brush, (Get-Rand 0 $w), (Get-Rand 0 $h), $s, $s)
        $brush.Dispose()
    }
}

function Draw-Robot($g, $x, $y, $scale, $alpha = 210) {
    Draw-WobblyRect $g $x $y (126 * $scale) (94 * $scale) "#9be9ff" "#151515" (6 * $scale) "#4bc3eb"
    Draw-WobblyRect $g ($x + 22 * $scale) ($y + 22 * $scale) (82 * $scale) (46 * $scale) "#dffbff" "#151515" (3 * $scale) $null
    $eyeBrush = New-Brush "#151515" $alpha
    $g.FillEllipse($eyeBrush, ($x + 44 * $scale), ($y + 42 * $scale), (10 * $scale), (10 * $scale))
    $g.FillEllipse($eyeBrush, ($x + 75 * $scale), ($y + 42 * $scale), (10 * $scale), (10 * $scale))
    $eyeBrush.Dispose()
    Draw-JitterLine $g ($x + 52 * $scale) ($y + 61 * $scale) ($x + 78 * $scale) ($y + 61 * $scale) "#151515" (4 * $scale) $alpha 1.0 5
    Draw-JitterLine $g ($x + 63 * $scale) ($y) ($x + 63 * $scale) ($y - 28 * $scale) "#151515" (5 * $scale) $alpha 0.8 3
    $red = New-Brush "#ff595e" $alpha
    $g.FillEllipse($red, ($x + 54 * $scale), ($y - 42 * $scale), (18 * $scale), (18 * $scale))
    $red.Dispose()
}

function Draw-BenchmarkBackground {
    $w = 1280
    $h = 720
    $bmp = New-Object System.Drawing.Bitmap($w, $h)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    Draw-SoftPaperTexture $g $w $h

    Draw-WobblyRect $g 48 22 250 132 "#e6f7ff" "#151515" 6 "#65cfff"
    Draw-Robot $g 82 102 0.82 210
    Draw-StarBurst $g 252 66 35 "#ff595e" 180

    Draw-WobblyRect $g 928 54 268 148 "#fffdf3" "#151515" 6 "#b893ff"
    Draw-JitterLine $g 970 94 1150 94 "#151515" 4 190 2 8
    Draw-JitterLine $g 970 122 1112 122 "#151515" 4 190 2 8
    Draw-JitterLine $g 970 150 1142 150 "#151515" 4 190 2 8
    $barColors = @("#65cfff", "#ffef5f", "#58d96b", "#ff8a6f")
    for ($i = 0; $i -lt 4; $i++) {
        $bh = 28 + ($i * 18)
        Draw-WobblyRect $g (982 + $i * 40) (190 - $bh) 24 $bh $barColors[$i] "#151515" 3 $barColors[$i]
    }

    Draw-WobblyRect $g 74 272 162 126 "#fffdf3" "#151515" 6 "#ffef5f"
    Draw-JitterLine $g 104 324 180 324 "#151515" 6 210 2 6
    Draw-JitterLine $g 104 358 195 358 "#151515" 6 210 2 6
    Draw-JitterLine $g 104 392 166 392 "#151515" 6 210 2 6
    Draw-StarBurst $g 215 295 28 "#65cfff" 180

    Draw-WobblyRect $g 1038 268 150 136 "#e9fff0" "#151515" 6 "#58d96b"
    Draw-Polygon $g @(@(1086, 300), @(1148, 340), @(1085, 381), @(1100, 341)) "#ffef5f" "#151515" 6 "#ffef5f"
    Draw-JitterLine $g 1098 341 1160 341 "#151515" 4 210 2 5

    Draw-WobblyRect $g 16 548 1248 188 "#f7b46a" "#151515" 8 "#ff8a4b"
    Draw-WobblyRect $g 364 582 172 86 "#fffdf3" "#151515" 6 "#65cfff"
    Draw-WobblyRect $g 552 574 188 98 "#fff2b7" "#151515" 6 "#ffef5f"
    Draw-WobblyRect $g 758 588 160 78 "#e9fff0" "#151515" 6 "#58d96b"

    Draw-JitterLine $g 406 628 504 606 "#ff595e" 8 215 3 7
    Draw-JitterLine $g 406 628 504 650 "#58d96b" 8 215 3 7
    Draw-JitterLine $g 594 616 696 616 "#151515" 5 210 2 8
    Draw-JitterLine $g 594 642 672 642 "#151515" 5 210 2 8
    Draw-StarBurst $g 834 622 34 "#ff595e" 180

    Draw-Robot $g 1074 586 0.72 210
    Draw-StarBurst $g 1128 548 30 "#ffef5f" 190

    $g.Dispose()
    $bmp.Save($outPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

Draw-BenchmarkBackground
Write-Host "Saved $outPath"
