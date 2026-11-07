# Converts the photo folder into TV-sized JPEGs (HEIC/PNG included, EXIF rotation applied)
# and copies videos, writing app/assets/media/*. Run with -Part/-Parts to split work across processes.
param(
  [string]$Source = "$env:USERPROFILE\Pictures",
  [string]$Out = (Join-Path $PSScriptRoot "..\app\assets\media"),
  [int]$Part = 0,
  [int]$Parts = 1,
  [int]$MaxW = 2200,
  [int]$MaxH = 1400
)
Add-Type -AssemblyName PresentationCore, WindowsBase
New-Item -ItemType Directory -Force $Out | Out-Null

$files = Get-ChildItem $Source -File | Where-Object { $_.Extension -match '^\.(jpe?g|heic|png|mp4|mov)$' } | Sort-Object Name
$i = -1
foreach ($f in $files) {
  $i++
  if ($i % $Parts -ne $Part) { continue }
  $id = '{0:D4}' -f $i
  $isVideo = $f.Extension -match '^\.(mp4|mov)$'
  $date = $f.LastWriteTime
  $dest = Join-Path $Out ("$id" + $(if ($isVideo) { '.mp4' } else { '.jpg' }))
  $metaFile = Join-Path $Out "$id.json"
  if ((Test-Path $metaFile) -and (Test-Path $dest)) { continue }
  try {
    $w = 0; $h = 0
    if ($isVideo) {
      Copy-Item $f.FullName $dest -Force
    } else {
      $fs = [IO.File]::OpenRead($f.FullName)
      try {
        $frame = [Windows.Media.Imaging.BitmapFrame]::Create($fs, [Windows.Media.Imaging.BitmapCreateOptions]::IgnoreColorProfile, [Windows.Media.Imaging.BitmapCacheOption]::OnLoad)
      } finally { $fs.Dispose() }
      $orient = 1
      try {
        $m = $frame.Metadata
        $o = $m.GetQuery('System.Photo.Orientation'); if ($o) { $orient = [int]$o }
        if ($m.DateTaken) { $date = [datetime]$m.DateTaken }
      } catch {}
      $src = $frame
      $tg = New-Object Windows.Media.TransformGroup
      switch ($orient) {
        2 { $tg.Children.Add((New-Object Windows.Media.ScaleTransform -1, 1)) }
        3 { $tg.Children.Add((New-Object Windows.Media.RotateTransform 180)) }
        4 { $tg.Children.Add((New-Object Windows.Media.ScaleTransform 1, -1)) }
        5 { $tg.Children.Add((New-Object Windows.Media.ScaleTransform -1, 1)); $tg.Children.Add((New-Object Windows.Media.RotateTransform 270)) }
        6 { $tg.Children.Add((New-Object Windows.Media.RotateTransform 90)) }
        7 { $tg.Children.Add((New-Object Windows.Media.ScaleTransform -1, 1)); $tg.Children.Add((New-Object Windows.Media.RotateTransform 90)) }
        8 { $tg.Children.Add((New-Object Windows.Media.RotateTransform 270)) }
      }
      $rw = $frame.PixelWidth; $rh = $frame.PixelHeight
      if ($orient -ge 5) { $rw, $rh = $rh, $rw }
      $scale = [math]::Min(1.0, [math]::Min($MaxW / $rw, $MaxH / $rh))
      if ($scale -lt 1.0) { $tg.Children.Add((New-Object Windows.Media.ScaleTransform $scale, $scale)) }
      if ($tg.Children.Count -gt 0) { $src = New-Object Windows.Media.Imaging.TransformedBitmap $frame, $tg }
      $enc = New-Object Windows.Media.Imaging.JpegBitmapEncoder
      $enc.QualityLevel = 85
      $enc.Frames.Add([Windows.Media.Imaging.BitmapFrame]::Create($src))
      $os = [IO.File]::Create($dest)
      try { $enc.Save($os) } finally { $os.Dispose() }
      $w = $src.PixelWidth; $h = $src.PixelHeight
    }
    @{ f = Split-Path $dest -Leaf; t = $(if ($isVideo) { 'v' } else { 'i' }); d = $date.ToString('yyyy-MM-dd'); w = $w; h = $h; n = $f.Name } |
      ConvertTo-Json -Compress | Set-Content $metaFile -Encoding utf8
  } catch {
    Write-Output "FAILED $($f.Name): $($_.Exception.Message)"
  }
}
Write-Output "Part $Part done"
