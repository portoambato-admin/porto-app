# ================== CONFIG ==================
$quality       = 85     # Calidad WebP
$thumbQuality  = 70     # Calidad miniaturas
$thumbWidth    = 300    # Ancho máx. miniatura (px)
# ===========================================

$basePath = (Get-Location).Path
$outputRootWebp   = Join-Path $basePath 'webp'
$outputRootThumbs = Join-Path $basePath 'thumbs'

# Crear carpetas raíz de salida
New-Item -ItemType Directory -Force -Path $outputRootWebp   | Out-Null
New-Item -ItemType Directory -Force -Path $outputRootThumbs | Out-Null

# Buscar JPG/PNG recursivamente, evitando procesar las carpetas de salida
Get-ChildItem -Path $basePath -Recurse -File -Include *.jpg,*.jpeg,*.png |
Where-Object {
    $_.FullName -notmatch "\\(webp|thumbs)\\"
} | ForEach-Object {
    $src      = $_.FullName
    $relPath  = $src.Substring($basePath.Length).TrimStart('\','/')
    $relDir   = Split-Path $relPath -Parent
    $name     = $_.BaseName

    # Directorios espejo en salida
    $outDirWebp   = Join-Path $outputRootWebp   $relDir
    $outDirThumbs = Join-Path $outputRootThumbs $relDir
    New-Item -ItemType Directory -Force -Path $outDirWebp,$outDirThumbs | Out-Null

    $outWebp  = Join-Path $outDirWebp   ($name + '.webp')
    $outThumb = Join-Path $outDirThumbs ($name + '_thumb.webp')

    # Convertir a WebP
    & cwebp -mt -quiet -q $quality -metadata none "$src" -o "$outWebp"

    # Miniatura
    & magick "$src" -auto-orient -strip -resize "${thumbWidth}x${thumbWidth}>" -quality $thumbQuality "$outThumb"
}

Write-Host "✅ Listo. WEBP en: $outputRootWebp  | Thumbs en: $outputRootThumbs"
