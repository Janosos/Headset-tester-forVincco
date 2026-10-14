Add-Type -AssemblyName System.Drawing

$srcPath = "$PSScriptRoot\..\assets\vincco.jpg"
$destIco1 = "$PSScriptRoot\..\windows\runner\resources\app_icon.ico"
$destIco2 = "$PSScriptRoot\..\assets\icons\tray_icon.ico"
$destPng = "$PSScriptRoot\..\assets\icons\vincco_logo.png"

$origBmp = [System.Drawing.Bitmap]::FromFile($srcPath)

# Save PNG version for UI
$origBmp.Save($destPng, [System.Drawing.Imaging.ImageFormat]::Png)

$sizes = @(16, 32, 48, 64, 128, 200)
$pngBytesList = @()

foreach ($sz in $sizes) {
    $resBmp = New-Object System.Drawing.Bitmap($sz, $sz)
    $g = [System.Drawing.Graphics]::FromImage($resBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.DrawImage($origBmp, 0, 0, $sz, $sz)
    $g.Dispose()

    $ms = New-Object System.IO.MemoryStream
    $resBmp.Save($ms, [System.Drawing.Imaging.ImageFormat]::Png)
    $pngBytesList += ,$ms.ToArray()
    $ms.Dispose()
    $resBmp.Dispose()
}

$origBmp.Dispose()

# Create ICO file
$icoMs = New-Object System.IO.MemoryStream
$bw = New-Object System.IO.BinaryWriter($icoMs)

# ICONDIR
$bw.Write([int16]0) # Reserved
$bw.Write([int16]1) # ICO type
$bw.Write([int16]$sizes.Count) # Number of images

$offset = 6 + ($sizes.Count * 16)

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $sz = $sizes[$i]
    $data = $pngBytesList[$i]
    $widthByte = if ($sz -ge 256) { 0 } else { [byte]$sz }
    $heightByte = if ($sz -ge 256) { 0 } else { [byte]$sz }

    $bw.Write([byte]$widthByte)  # Width
    $bw.Write([byte]$heightByte) # Height
    $bw.Write([byte]0)           # Color count
    $bw.Write([byte]0)           # Reserved
    $bw.Write([int16]1)          # Color planes
    $bw.Write([int16]32)         # Bits per pixel
    $bw.Write([int32]$data.Length) # Image data size
    $bw.Write([int32]$offset)      # Offset of image data
    $offset += $data.Length
}

for ($i = 0; $i -lt $sizes.Count; $i++) {
    $bw.Write($pngBytesList[$i])
}

$bw.Flush()
$icoBytes = $icoMs.ToArray()
$bw.Close()
$icoMs.Close()

[System.IO.File]::WriteAllBytes($destIco1, $icoBytes)
[System.IO.File]::WriteAllBytes($destIco2, $icoBytes)

Write-Host "Icon converted successfully to $destIco1 and $destIco2 ($($icoBytes.Length) bytes)"
