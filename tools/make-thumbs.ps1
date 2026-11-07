# Makes 128px square center-cropped thumbnails of every converted photo for the galaxy scene,
# and writes app/assets/media.js from the per-file metadata.
param([int]$Size = 128)
Add-Type -AssemblyName System.Drawing
$media = Join-Path $PSScriptRoot "..\app\assets\media"
$thumbs = Join-Path $PSScriptRoot "..\app\assets\thumbs"
New-Item -ItemType Directory -Force $thumbs | Out-Null
$jpgCodec = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object MimeType -eq 'image/jpeg'
$ep = New-Object Drawing.Imaging.EncoderParameters 1
$ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 80L

$list = @()
foreach ($j in Get-ChildItem $media -Filter *.json | Sort-Object Name) {
  $m = Get-Content $j.FullName -Raw | ConvertFrom-Json
  $list += $m
  if ($m.t -ne 'i') { continue }
  $dest = Join-Path $thumbs $m.f
  if (Test-Path $dest) { continue }
  $img = [Drawing.Image]::FromFile((Join-Path $media $m.f))
  try {
    $side = [math]::Min($img.Width, $img.Height)
    $src = New-Object Drawing.Rectangle ([int](($img.Width - $side) / 2)), ([int](($img.Height - $side) / 3)), $side, $side
    $bmp = New-Object Drawing.Bitmap $Size, $Size
    $g = [Drawing.Graphics]::FromImage($bmp)
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.DrawImage($img, (New-Object Drawing.Rectangle 0, 0, $Size, $Size), $src, 'Pixel')
    $g.Dispose()
    $bmp.Save($dest, $jpgCodec, $ep); $bmp.Dispose()
  } finally { $img.Dispose() }
}
$js = 'window.MEDIA=' + (ConvertTo-Json @($list | Select-Object f, t, d, w, h, n) -Compress) + ';'
Set-Content (Join-Path $PSScriptRoot "..\app\assets\media.js") $js -Encoding utf8
Write-Output "thumbs: $((Get-ChildItem $thumbs).Count), media entries: $($list.Count)"
