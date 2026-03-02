# Start Orthanc Manually on D: Drive (for troubleshooting)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Orthanc (D: Drive)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$orthancExe = "D:\Program Files\Orthanc Server\Orthanc.exe"
$configFile = "D:\Life Relier\OrthancData\Configuration\orthanc.json"

# Check if Orthanc exists
if (-not (Test-Path $orthancExe)) {
    Write-Host "✗ Orthanc not found at: $orthancExe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "✓ Found Orthanc at: $orthancExe" -ForegroundColor Green

# Check if config exists
if (-not (Test-Path $configFile)) {
    Write-Host "✗ Config not found at: $configFile" -ForegroundColor Red
    Write-Host ""
    Write-Host "Run setup-orthanc-d-drive.ps1 first!" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "✓ Found config at: $configFile" -ForegroundColor Green
Write-Host ""
Write-Host "Starting Orthanc with verbose logging..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to Orthanc directory
Set-Location "D:\Program Files\Orthanc Server"

# Start Orthanc in verbose mode
& $orthancExe $configFile --verbose
