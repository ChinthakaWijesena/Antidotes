# ==============================================================================
# Antidotes - Windows Installer Build Script
# ==============================================================================

Write-Host ">>> Step 1: Building Flutter Windows Application in Release Mode..." -ForegroundColor Cyan
flutter build windows

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Flutter Windows build failed!" -ForegroundColor Red
    exit 1
}

Write-Host "`n>>> Step 2: Locating Inno Setup Compiler (ISCC.exe)..." -ForegroundColor Cyan

$isccCandidates = @(
    "ISCC.exe",
    "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe",
    "C:\Program Files (x86)\Inno Setup 6\ISCC.exe",
    "C:\Program Files\Inno Setup 6\ISCC.exe"
)

$isccPath = $null
foreach ($path in $isccCandidates) {
    $cmd = Get-Command $path -ErrorAction SilentlyContinue
    if ($cmd) {
        $isccPath = $cmd.Source
        break
    }
    if (Test-Path $path) {
        $isccPath = $path
        break
    }
}

if (-not $isccPath) {
    Write-Host "`n[!] Inno Setup is not installed on this machine." -ForegroundColor Yellow
    Write-Host "To compile the setup .exe automatically, install Inno Setup using:" -ForegroundColor Yellow
    Write-Host "   winget install JRSoftware.InnoSetup" -ForegroundColor Green
    Write-Host "Or download it from: https://jrsoftware.org/isdl.php" -ForegroundColor Cyan
    Write-Host "`nAlternatively, you can open installer/antidotes_setup.iss directly in Inno Setup GUI and click 'Compile'." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found Inno Setup at: $isccPath" -ForegroundColor Green
Write-Host "`n>>> Step 3: Compiling Setup .exe..." -ForegroundColor Cyan

$issFile = Join-Path $PSScriptRoot "antidotes_setup.iss"
& $isccPath "$issFile"

if ($LASTEXITCODE -eq 0) {
    Write-Host "`n========================================================" -ForegroundColor Green
    Write-Host "[SUCCESS] Installer created successfully!" -ForegroundColor Green
    Write-Host "Output file: build\installer\Antidotes-Setup-v1.0.0.exe" -ForegroundColor Cyan
    Write-Host "========================================================" -ForegroundColor Green
} else {
    Write-Host "Error compiling Inno Setup script." -ForegroundColor Red
}
