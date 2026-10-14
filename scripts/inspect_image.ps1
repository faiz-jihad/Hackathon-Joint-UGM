Add-Type -AssemblyName System.Drawing
$filePath = "d:\Retiva (Hackathon UGM)\web\public\images\mascot\retiva_mascot_sheet.jpg"
$bmp = [System.Drawing.Bitmap]::FromFile($filePath)
Write-Output "Image Dimensions: $($bmp.Width) x $($bmp.Height)"
$bmp.Dispose()
