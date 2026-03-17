Add-Type -AssemblyName System.Drawing

$sizes    = @(16, 32, 48, 256)
$pngDatas = @()
$hanChar  = [char]0xD55C   # Korean char

foreach ($size in $sizes) {
    $bmp = New-Object System.Drawing.Bitmap($size, $size)
    $g   = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode     = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $g.Clear([System.Drawing.Color]::Transparent)

    $bgColor = [System.Drawing.Color]::FromArgb(255, 26, 107, 190)
    $brush   = New-Object System.Drawing.SolidBrush($bgColor)
    $r       = [int]($size * 0.22)
    $path    = New-Object System.Drawing.Drawing2D.GraphicsPath
    $path.AddArc($r,         0,        $r, $r, 180, 90)
    $path.AddArc($size-$r*2, 0,        $r, $r, 270, 90)
    $path.AddArc($size-$r*2, $size-$r, $r, $r,   0, 90)
    $path.AddArc($r,         $size-$r, $r, $r,  90, 90)
    $path.CloseFigure()
    $g.FillPath($brush, $path)

    $fontSize = [float]($size * 0.52)
    $font  = New-Object System.Drawing.Font("Malgun Gothic", $fontSize, [System.Drawing.FontStyle]::Bold)
    $tb    = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::White)
    $fmt   = New-Object System.Drawing.StringFormat
    $fmt.Alignment     = [System.Drawing.StringAlignment]::Center
    $fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
    $rectF = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
    $g.DrawString($hanChar, $font, $tb, $rectF, $fmt)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $bmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngDatas += ,$ms.ToArray()
    $ms.Dispose()
    $bmp.Dispose()
}

$outputPath = (Split-Path -Parent $MyInvocation.MyCommand.Path) + "\IMEGuard.ico"
$out = New-Object System.IO.MemoryStream
$bw  = New-Object System.IO.BinaryWriter($out)
$bw.Write([uint16]0)
$bw.Write([uint16]1)
$bw.Write([uint16]$sizes.Count)

$offset = 6 + $sizes.Count * 16
for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz    = $sizes[$i]
    $wh    = if ($sz -ge 256) { [byte]0 } else { [byte]$sz }
    $bw.Write($wh)
    $bw.Write($wh)
    $bw.Write([byte]0)
    $bw.Write([byte]0)
    $bw.Write([uint16]1)
    $bw.Write([uint16]32)
    $bw.Write([uint32]$pngDatas[$i].Length)
    $bw.Write([uint32]$offset)
    $offset += $pngDatas[$i].Length
}
foreach ($d in $pngDatas) { $bw.Write($d) }
$bw.Flush()
[System.IO.File]::WriteAllBytes($outputPath, $out.ToArray())
Write-Host "Saved: $outputPath"
