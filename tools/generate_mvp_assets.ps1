$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.Drawing
[System.Drawing.Drawing2D.GraphicsPath] | Out-Null

$root = Split-Path -Parent $PSScriptRoot
$artDir = Join-Path $root "assets\art"
$spritesDir = Join-Path $root "assets\sprites"

function New-Bitmap($w, $h) {
    return New-Object System.Drawing.Bitmap($w, $h)
}

function Get-Graphics($bmp) {
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::White)
    return $g
}

function New-Color($hex) {
    return [System.Drawing.ColorTranslator]::FromHtml($hex)
}

function Fill-Background($g, $bg, $scribble, $dots) {
    $brush = New-Object System.Drawing.SolidBrush (New-Color $bg)
    $g.FillRectangle($brush, 0, 0, 512, 512)
    $brush.Dispose()

    $pen = New-Object System.Drawing.Pen (New-Color $scribble), 7
    for ($i = 0; $i -lt 18; $i++) {
        $x1 = Get-Random -Minimum -20 -Maximum 500
        $y1 = Get-Random -Minimum -20 -Maximum 500
        $x2 = $x1 + (Get-Random -Minimum 40 -Maximum 140)
        $y2 = $y1 + (Get-Random -Minimum -30 -Maximum 30)
        $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    }
    $pen.Dispose()

    $dotBrush = New-Object System.Drawing.SolidBrush (New-Color $dots)
    for ($i = 0; $i -lt 22; $i++) {
        $x = Get-Random -Minimum 0 -Maximum 480
        $y = Get-Random -Minimum 0 -Maximum 480
        $s = Get-Random -Minimum 10 -Maximum 28
        $g.FillEllipse($dotBrush, $x, $y, $s, $s)
    }
    $dotBrush.Dispose()
}

function Draw-WobblyRect($g, $x, $y, $w, $h, $fillHex, $borderHex, $borderWidth = 6) {
    $brush = New-Object System.Drawing.SolidBrush (New-Color $fillHex)
    $g.FillRectangle($brush, $x, $y, $w, $h)
    $brush.Dispose()

    $pen = New-Object System.Drawing.Pen (New-Color $borderHex), $borderWidth
    $g.DrawRectangle($pen, $x, $y, $w, $h)
    $g.DrawRectangle($pen, $x + 3, $y + 2, $w - 6, $h - 5)
    $pen.Dispose()
}

function Draw-ImageWithOutline($g, $imagePath, $x, $y, $w, $h) {
    $img = [System.Drawing.Image]::FromFile($imagePath)
    $outline = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 255, 255, 255))
    $g.FillEllipse($outline, $x - 8, $y - 8, $w + 16, $h + 16)
    $outline.Dispose()
    $pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(210, 30, 30, 30)), 5
    $g.DrawEllipse($pen, $x - 8, $y - 8, $w + 16, $h + 16)
    $pen.Dispose()
    $g.DrawImage($img, $x, $y, $w, $h)
    $img.Dispose()
}

function Draw-StarBurst($g, $cx, $cy, $r, $hex) {
    $pen = New-Object System.Drawing.Pen (New-Color $hex), 6
    for ($i = 0; $i -lt 8; $i++) {
        $angle = [Math]::PI * 2 * $i / 8
        $x1 = $cx + [Math]::Cos($angle) * ($r * 0.35)
        $y1 = $cy + [Math]::Sin($angle) * ($r * 0.35)
        $x2 = $cx + [Math]::Cos($angle) * $r
        $y2 = $cy + [Math]::Sin($angle) * $r
        $g.DrawLine($pen, $x1, $y1, $x2, $y2)
    }
    $pen.Dispose()
}

function Save-Bitmap($bmp, $name) {
    $path = Join-Path $artDir $name
    $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
}

function Make-LicenseMaze {
    $bmp = New-Bitmap 512 512
    $g = Get-Graphics $bmp
    Fill-Background $g "#FFF3C6" "#FFD85C" "#F7A9A8"
    for ($row = 0; $row -lt 4; $row++) {
        for ($col = 0; $col -lt 5; $col++) {
            $fill = if ((($row + $col) % 3) -eq 0) { "#FFFFFF" } elseif ((($row + $col) % 3) -eq 1) { "#DCF7DF" } else { "#FFE0DC" }
            Draw-WobblyRect $g (38 + $col * 78) (112 + $row * 74) 62 58 $fill "#1D1D1D" 5
        }
    }
    Draw-ImageWithOutline $g (Join-Path $spritesDir "hungry_model.png") 294 288 130 130
    Draw-StarBurst $g 430 110 42 "#16A34A"
    Draw-StarBurst $g 82 92 32 "#FF5B5B"
    $g.Dispose()
    Save-Bitmap $bmp "license_maze_bg.png"
}

function Make-EvalCherry {
    $bmp = New-Bitmap 512 512
    $g = Get-Graphics $bmp
    Fill-Background $g "#EAF7FF" "#8BD0FF" "#FFE97A"
    Draw-WobblyRect $g 48 76 416 84 "#FFFFFF" "#1D1D1D" 6
    Draw-WobblyRect $g 68 196 96 230 "#FFE8F0" "#1D1D1D" 5
    Draw-WobblyRect $g 196 146 96 280 "#DFF8DA" "#1D1D1D" 5
    Draw-WobblyRect $g 324 116 96 310 "#FFE0DC" "#1D1D1D" 5
    Draw-ImageWithOutline $g (Join-Path $spritesDir "leaderboard.png") 334 34 118 118
    Draw-StarBurst $g 102 64 26 "#FFE34D"
    $g.Dispose()
    Save-Bitmap $bmp "eval_cherry_picker_bg.png"
}

function Make-DeployFriday {
    $bmp = New-Bitmap 512 512
    $g = Get-Graphics $bmp
    Fill-Background $g "#FFF4E8" "#FFB66E" "#FFD5CC"
    Draw-WobblyRect $g 42 120 274 254 "#FFFFFF" "#1D1D1D" 6
    Draw-WobblyRect $g 336 150 128 152 "#DFF8DA" "#1D1D1D" 6
    Draw-ImageWithOutline $g (Join-Path $spritesDir "rate_limit.png") 70 174 90 90
    Draw-ImageWithOutline $g (Join-Path $spritesDir "repo_locked.png") 178 174 90 90
    Draw-ImageWithOutline $g (Join-Path $spritesDir "benchmark_cursor.png") 286 174 90 90
    Draw-StarBurst $g 408 336 44 "#FF5B5B"
    Draw-StarBurst $g 380 118 26 "#16A34A"
    $g.Dispose()
    Save-Bitmap $bmp "deploy_friday_bg.png"
}

function Make-SycophancyWhack {
    $bmp = New-Bitmap 512 512
    $g = Get-Graphics $bmp
    Fill-Background $g "#EEF7FF" "#B9E0FF" "#FFE0F2"
    Draw-ImageWithOutline $g (Join-Path $spritesDir "dario_amodei.png") 336 232 126 172
    Draw-WobblyRect $g 52 126 172 78 "#FFE0F2" "#1D1D1D" 5
    Draw-WobblyRect $g 164 236 172 78 "#E6FFE8" "#1D1D1D" 5
    Draw-WobblyRect $g 72 332 186 78 "#FFE0F2" "#1D1D1D" 5
    Draw-StarBurst $g 410 128 30 "#FFE34D"
    Draw-StarBurst $g 288 98 24 "#16A34A"
    $g.Dispose()
    Save-Bitmap $bmp "sycophancy_whack_bg.png"
}

function Make-AgentTaskSwarm {
    $bmp = New-Bitmap 512 512
    $g = Get-Graphics $bmp
    Fill-Background $g "#F3F6FF" "#C9D5FF" "#FFF0A8"
    Draw-WobblyRect $g 50 96 116 92 "#DFF8DA" "#1D1D1D" 5
    Draw-WobblyRect $g 198 96 116 92 "#DFF8DA" "#1D1D1D" 5
    Draw-WobblyRect $g 346 96 116 92 "#DFF8DA" "#1D1D1D" 5
    Draw-WobblyRect $g 86 278 140 72 "#EEF7FF" "#1D1D1D" 5
    Draw-WobblyRect $g 284 278 140 72 "#FFF4E8" "#1D1D1D" 5
    $pen = New-Object System.Drawing.Pen (New-Color "#1F5FBF"), 7
    $g.DrawLine($pen, 108, 188, 156, 278)
    $g.DrawLine($pen, 256, 188, 352, 278)
    $g.DrawLine($pen, 404, 188, 352, 278)
    $pen.Dispose()
    Draw-ImageWithOutline $g (Join-Path $spritesDir "sam_face.png") 194 340 118 118
    $g.Dispose()
    Save-Bitmap $bmp "agent_task_swarm_bg.png"
}

Make-LicenseMaze
Make-EvalCherry
Make-DeployFriday
Make-SycophancyWhack
Make-AgentTaskSwarm
