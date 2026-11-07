# Generates colorful sample pictures (no real photos) plus thumbnails and app/assets/media.js,
# so the app can be built and tried without any personal media. Used for the demo APK.
param([int]$Count = 28)
Add-Type -AssemblyName System.Drawing
$assets = Join-Path $PSScriptRoot "..\app\assets"
$media = Join-Path $assets "media"; $thumbs = Join-Path $assets "thumbs"
New-Item -ItemType Directory -Force $media, $thumbs | Out-Null
$rnd = New-Object Random 42
$jpg = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$ep = New-Object Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 85L
$palettes = @(@(255, 61, 127, 255, 177, 61), @(61, 214, 255, 120, 61, 255), @(255, 140, 60, 200, 40, 90), @(60, 220, 160, 20, 90, 200), @(250, 220, 90, 240, 90, 90), @(150, 90, 255, 40, 200, 220))
$font = New-Object Drawing.Font('Segoe UI', [single]64, [Drawing.FontStyle]::Bold)
$sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
$list = @()
for ($i = 0; $i -lt $Count; $i++) {
  $portrait = ($i % 5 -eq 2)
  $w = $(if ($portrait) { 900 } else { 1600 }); $h = $(if ($portrait) { 1400 } else { 900 })
  $p = $palettes[$i % $palettes.Count]
  $bmp = New-Object Drawing.Bitmap $w, $h
  $g = [Drawing.Graphics]::FromImage($bmp); $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
  $c1 = [Drawing.Color]::FromArgb(255, $p[0], $p[1], $p[2]); $c2 = [Drawing.Color]::FromArgb(255, $p[3], $p[4], $p[5])
  $br = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Rectangle 0, 0, $w, $h), $c1, $c2, ([single]($rnd.Next(20, 160)))
  $g.FillRectangle($br, 0, 0, $w, $h)
  for ($k = 0; $k -lt 14; $k++) {
    $r = $rnd.Next(60, [int]($h / 2)); $x = $rnd.Next(-$r, $w); $y = $rnd.Next(-$r, $h)
    $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb($rnd.Next(25, 90), 255, 255, 255))
    $g.FillEllipse($b, $x, $y, $r, $r); $b.Dispose()
  }
  $g.DrawString("Demo picture $($i + 1)", $font, [Drawing.Brushes]::White, (New-Object Drawing.RectangleF 0, 0, $w, $h), $sf)
  $g.Dispose()
  $id = '{0:D4}' -f $i
  $bmp.Save((Join-Path $media "$id.jpg"), $jpg, $ep)
  $side = [math]::Min($w, $h); $th = New-Object Drawing.Bitmap 128, 128; $tg = [Drawing.Graphics]::FromImage($th)
  $tg.DrawImage($bmp, (New-Object Drawing.Rectangle 0, 0, 128, 128), (New-Object Drawing.Rectangle ([int](($w - $side) / 2)), ([int](($h - $side) / 2)), $side, $side), 'Pixel'); $tg.Dispose()
  $th.Save((Join-Path $thumbs "$id.jpg"), $jpg, $ep); $th.Dispose(); $bmp.Dispose()
  $list += [pscustomobject]@{ f = "$id.jpg"; t = 'i'; d = ('2024-{0:D2}-{1:D2}' -f (1 + $i % 12), (1 + $i % 28)); w = $w; h = $h; n = "demo-$id.jpg" }
}
Set-Content (Join-Path $assets "media.js") ('window.MEDIA=' + (ConvertTo-Json @($list) -Compress) + ';') -Encoding utf8
Write-Output "demo media: $Count pictures"
