# Start Orthanc Manually (for troubleshooting)
# This runs Orthanc in console mode so you can see any errors

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Starting Orthanc in Console Mode" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Find Orthanc.exe
$orthancPaths = @(
    "C:\Orthanc\Orthanc.exe",
    "C:\Program Files\Orthanc\Orthanc.exe",
    "C:\Program Files (x86)\Orthanc\Orthanc.exe"
)

$orthancExe = $null
foreach ($path in $orthancPaths) {
    if (Test-Path $path) {
        $orthancExe = $path
        Write-Host "Found Orthanc at: $path" -ForegroundColor Green
        break
    }
}

if (-not $orthancExe) {
    Write-Host "ERROR: Orthanc.exe not found!" -ForegroundColor Red
    Write-Host "Please install Orthanc first." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

# Find config file
$configPaths = @(
    "C:\Orthanc\Configuration\orthanc.json",
    "C:\Orthanc\orthanc.json",
    "$PSScriptRoot\orthanc-standalone\orthanc.json"
)

$configFile = $null
foreach ($path in $configPaths) {
    if (Test-Path $path) {
        $configFile = $path
        Write-Host "Found config at: $path" -ForegroundColor Green
        break
    }
}

if (-not $configFile) {
    Write-Host "ERROR: Configuration file not found!" -ForegroundColor Red
    Write-Host "Expected at: C:\Orthanc\Configuration\orthanc.json" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host ""
Write-Host "Starting Orthanc with verbose logging..." -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop" -ForegroundColor Gray
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Change to Orthanc directory
$orthancDir = [System.IO.Path]::GetDirectoryName($orthancExe)
Set-Location $orthancDir

# Start Orthanc in verbose mode
& $orthancExe $configFile --verbose
