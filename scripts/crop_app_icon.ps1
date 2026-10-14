Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\LENOVO\.gemini\antigravity-ide\brain\0e8a198a-0455-43e0-a27b-e4b7e7d2c3b4\.user_uploaded\media_1791949405801.jpg"
$outDirMobile = "d:\Retiva (Hackathon UGM)\mobile\assets\images"
$outDirWeb = "d:\Retiva (Hackathon UGM)\web\public\images\mascot"

$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
Write-Output "App Icon Image Dimensions: $($bmp.Width) x $($bmp.Height)"

# 1. Full Image as app_logo_full.png
$bmp.Save((Join-Path $outDirMobile "retiva_app_logo_full.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Save((Join-Path $outDirWeb "retiva_app_logo_full.png"), [System.Drawing.Imaging.ImageFormat]::Png)

# 2. Crop just the app icon squircle badge (around center, ~520x520 from 1024x1024)
# Let's inspect where squircle badge is:
# Usually from ~240 to ~780 X, ~150 to ~690 Y on 1024x1024
$w = $bmp.Width
$scale = $w / 1024.0

$badgeX = [int](240 * $scale)
$badgeY = [int](150 * $scale)
$badgeW = [int](544 * $scale)
$badgeH = [int](540 * $scale)

$rectBadge = New-Object System.Drawing.Rectangle($badgeX, $badgeY, $badgeW, $badgeH)
$cropBadge = $bmp.Clone($rectBadge, $bmp.PixelFormat)
$cropBadge.Save((Join-Path $outDirMobile "retiva_app_badge.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$cropBadge.Save((Join-Path $outDirWeb "retiva_app_badge.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$cropBadge.Dispose()

# 3. Crop Retiva text logo:
$textX = [int](280 * $scale)
$textY = [int](680 * $scale)
$textW = [int](464 * $scale)
$textH = [int](130 * $scale)
$rectText = New-Object System.Drawing.Rectangle($textX, $textY, $textW, $textH)
$cropText = $bmp.Clone($rectText, $bmp.PixelFormat)
$cropText.Save((Join-Path $outDirMobile "retiva_brand_text.png"), [System.Drawing.Imaging.ImageFormat]::Png)
$cropText.Dispose()

$bmp.Dispose()

# Copy all mascots to mobile/assets/images
$mascotFiles = Get-ChildItem -Path $outDirWeb -Filter "*.png"
foreach ($f in $mascotFiles) {
    Copy-Item -Path $f.FullName -Destination (Join-Path $outDirMobile $f.Name) -Force
    Write-Output "Copied to mobile: $($f.Name)"
}

Write-Output "Done prepping mobile assets!"
