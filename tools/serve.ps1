# Tiny static server so the slideshow can be previewed in a desktop browser.
param([int]$Port = 8765)
$root = (Resolve-Path (Join-Path $PSScriptRoot "..\app\assets")).Path
$types = @{ '.html' = 'text/html'; '.js' = 'text/javascript'; '.jpg' = 'image/jpeg'; '.png' = 'image/png'; '.mp4' = 'video/mp4' }
$l = New-Object Net.HttpListener
$l.Prefixes.Add("http://localhost:$Port/")
$l.Start()
Write-Output "Serving $root on http://localhost:$Port/"
while ($l.IsListening) {
  $c = $l.GetContext()
  try {
    $rel = [Uri]::UnescapeDataString($c.Request.Url.AbsolutePath.TrimStart('/'))
    if (-not $rel) { $rel = 'index.html' }
    $p = Join-Path $root $rel
    if ((Test-Path $p -PathType Leaf) -and $p.StartsWith($root)) {
      $bytes = [IO.File]::ReadAllBytes($p)
      $ext = [IO.Path]::GetExtension($p).ToLower()
      $c.Response.ContentType = $(if ($types[$ext]) { $types[$ext] } else { 'application/octet-stream' })
      $c.Response.AddHeader('Cache-Control', 'no-store')
      $c.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    } else { $c.Response.StatusCode = 404 }
  } catch {}
  $c.Response.Close()
}
