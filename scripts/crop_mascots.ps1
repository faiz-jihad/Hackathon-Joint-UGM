Add-Type -AssemblyName System.Drawing

$srcPath = "d:\Retiva (Hackathon UGM)\web\public\images\mascot\retiva_mascot_sheet.jpg"
$outDir = "d:\Retiva (Hackathon UGM)\web\public\images\mascot"

$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)

$regions = @(
    # Full Hero with slogan
    @{ Name = "mascot_hero_full.png"; X = 0; Y = 30; W = 435; H = 435 },
    # Just the doctor otter standing
    @{ Name = "mascot_hero.png"; X = 130; Y = 65; W = 305; H = 400 },
    # Mascot with laptop
    @{ Name = "mascot_laptop.png"; X = 675; Y = 735; W = 325; H = 235 },
    # App Icon
    @{ Name = "mascot_app_icon.png"; X = 35; Y = 776; W = 118; H = 118 },
    # Chat greeting bubble
    @{ Name = "mascot_greeting_bubble.png"; X = 412; Y = 756; W = 236; H = 58 },
    # 6 Poses (without text captions)
    @{ Name = "pose_menyapa.png"; X = 28; Y = 512; W = 135; H = 158 },
    @{ Name = "pose_membantu.png"; X = 195; Y = 512; W = 125; H = 158 },
    @{ Name = "pose_mendukung.png"; X = 350; Y = 512; W = 130; H = 158 },
    @{ Name = "pose_menjelaskan.png"; X = 510; Y = 495; W = 138; H = 175 },
    @{ Name = "pose_peduli.png"; X = 672; Y = 512; W = 130; H = 158 },
    @{ Name = "pose_melangkah.png"; X = 830; Y = 512; W = 135; H = 158 },
    # Retiva Brand Mark from sheet
    @{ Name = "retiva_brand_mark.png"; X = 460; Y = 35; W = 230; H = 180 }
)

foreach ($r in $regions) {
    $rect = New-Object System.Drawing.Rectangle($r.X, $r.Y, $r.W, $r.H)
    $crop = $bmp.Clone($rect, $bmp.PixelFormat)
    $destFile = Join-Path $outDir $r.Name
    $crop.Save($destFile, [System.Drawing.Imaging.ImageFormat]::Png)
    $crop.Dispose()
    Write-Output "Saved: $($r.Name) ($($r.W)x$($r.H))"
}

$bmp.Dispose()
Write-Output "Refined crops complete!"
