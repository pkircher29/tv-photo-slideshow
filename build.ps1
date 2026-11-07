# Builds PhotoSlideshow.apk without Gradle: aapt2 -> javac -> d8 -> zipalign -> apksigner.
# Expects the JDK + Android SDK under %LOCALAPPDATA%\FireTVBuild (short path avoids Windows 260-char limits).
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing, System.IO.Compression, System.IO.Compression.FileSystem
$root = $PSScriptRoot
$T = "$env:LOCALAPPDATA\FireTVBuild"
$env:JAVA_HOME = (Get-ChildItem "$T\jdk" -Directory)[0].FullName
$sdk = "$T\sdk"
$bt = (Get-ChildItem "$sdk\build-tools" -Directory | Sort-Object Name -Descending)[0].FullName
$jar = "$sdk\platforms\android-34\android.jar"
$work = "$T\work"
if (Test-Path $work) { Remove-Item $work -Recurse -Force }
New-Item -ItemType Directory -Force "$work\res\drawable", "$work\classes", "$work\dex", "$work\apkdir\res\drawable", "$work\apkdir\assets\media", "$work\apkdir\assets\thumbs" | Out-Null

# --- launcher banner (Fire TV wants 320x180) ---
$bmp = New-Object Drawing.Bitmap 320, 180
$g = [Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAliasGridFit'
$grad = New-Object Drawing.Drawing2D.LinearGradientBrush (New-Object Drawing.Point 0, 0), (New-Object Drawing.Point 320, 180), ([Drawing.Color]::FromArgb(255, 20, 8, 50)), ([Drawing.Color]::FromArgb(255, 150, 30, 90))
$g.FillRectangle($grad, 0, 0, 320, 180)
$rnd = New-Object Random 7
1..60 | ForEach-Object { $g.FillEllipse([Drawing.Brushes]::White, $rnd.Next(320), $rnd.Next(180), 2, 2) }
$f1 = New-Object Drawing.Font 'Segoe UI Light', 40
$f2 = New-Object Drawing.Font 'Segoe UI', 11
$sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'
$g.DrawString('SLIDESHOW', $f1, [Drawing.Brushes]::White, 160, 42, $sf)
$g.DrawString('PICTURES & MEMORIES', $f2, [Drawing.Brushes]::Gold, 160, 108, $sf)
# use the bar's real logo as the launcher banner/icon
$g.Clear([Drawing.Color]::Black)
$logo = [Drawing.Image]::FromFile("$root\app\assets\logo.jpg")
$g.InterpolationMode = 'HighQualityBicubic'
$g.DrawImage($logo, 70, 0, 180, 180)
$logo.Dispose()
$g.Dispose(); $bmp.Save("$work\res\drawable\banner.png", [Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()

# --- assets (skip per-file metadata json) ---
robocopy "$root\app\assets" "$work\assets" /E /XF *.json tagger.html /NFL /NDL /NJH /NJS /NP | Out-Null

& "$bt\aapt2.exe" compile --dir "$work\res" -o "$work\res.zip"
& "$bt\aapt2.exe" link --output-to-dir -o "$work\apkdir" -I $jar --manifest "$root\app\AndroidManifest.xml" -R "$work\res.zip" -A "$work\assets" -0 jpg -0 mp4 -0 png --min-sdk-version 22 --target-sdk-version 34 --version-code 1 --version-name 1.0
if ($LASTEXITCODE) { throw 'aapt2 link failed' }

$src = Get-ChildItem "$root\app\src" -Recurse -Filter *.java | ForEach-Object FullName
& "$env:JAVA_HOME\bin\javac.exe" -source 8 -target 8 -Xlint:-options -cp $jar -d "$work\classes" $src
if ($LASTEXITCODE) { throw 'javac failed' }
$cls = Get-ChildItem "$work\classes" -Recurse -Filter *.class | ForEach-Object FullName
& "$bt\d8.bat" --lib $jar --min-api 22 --output "$work\dex" $cls
if ($LASTEXITCODE) { throw 'd8 failed' }

# aapt2 wrote the package to a folder (zipping it ourselves avoids its Windows backslash entry names).
# jar -0 stores every entry uncompressed with forward slashes, which Android requires for resources.arsc.
Copy-Item "$work\dex\classes.dex" "$work\apkdir\classes.dex"
& "$env:JAVA_HOME\bin\jar.exe" --create --no-manifest --no-compress --file "$work\base.apk" -C "$work\apkdir" .
if ($LASTEXITCODE) { throw 'jar failed' }

& "$bt\zipalign.exe" -f -p 4 "$work\base.apk" "$work\aligned.apk"
if ($LASTEXITCODE) { throw 'zipalign failed' }

$ks = "$T\debug.keystore"
if (-not (Test-Path $ks)) {
  & "$env:JAVA_HOME\bin\keytool.exe" -genkeypair -keystore $ks -storepass android -keypass android -alias slideshow -keyalg RSA -keysize 2048 -validity 10000 -dname "CN=Photo Slideshow"
}
$out = "$root\PhotoSlideshow.apk"
& "$bt\apksigner.bat" sign --ks $ks --ks-pass pass:android --key-pass pass:android --out $out "$work\aligned.apk"
if ($LASTEXITCODE) { throw 'apksigner failed' }
"Built $out  ($([math]::Round((Get-Item $out).Length / 1MB, 1)) MB)"
