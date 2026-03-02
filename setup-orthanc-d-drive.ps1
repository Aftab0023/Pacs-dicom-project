# Setup Orthanc on D: Drive
# For installation at: D:\Program Files\Orthanc Server

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Orthanc D: Drive Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "⚠ This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please right-click and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "✓ Running as Administrator" -ForegroundColor Green
Write-Host ""

# Orthanc installation path
$orthancExe = "D:\Program Files\Orthanc Server\Orthanc.exe"

# Check if Orthanc is installed
Write-Host "Checking Orthanc installation..." -ForegroundColor Yellow
if (-not (Test-Path $orthancExe)) {
    Write-Host "✗ Orthanc not found at: $orthancExe" -ForegroundColor Red
    Write-Host ""
    Write-Host "Please verify Orthanc installation path." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press any key to exit..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "✓ Found Orthanc at: $orthancExe" -ForegroundColor Green
Write-Host ""

# Create Configuration folder if it doesn't exist
Write-Host "Setting up configuration..." -ForegroundColor Yellow
$configDir = "D:\Life Relier\OrthancData\Configuration"

if (-not (Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    Write-Host "✓ Created Configuration folder" -ForegroundColor Green
} else {
    Write-Host "✓ Configuration folder exists" -ForegroundColor Green
}

# Copy configuration files
$configFile = "$configDir\orthanc.json"
$webhookFile = "$configDir\webhook.lua"

Write-Host "Copying configuration files..." -ForegroundColor Yellow

if (Test-Path "orthanc-d-drive-config.json") {
    Copy-Item "orthanc-d-drive-config.json" $configFile -Force
    Write-Host "✓ Copied orthanc.json" -ForegroundColor Green
} else {
    Write-Host "✗ orthanc-d-drive-config.json not found!" -ForegroundColor Red
}

if (Test-Path "webhook-d-drive.lua") {
    Copy-Item "webhook-d-drive.lua" $webhookFile -Force
    Write-Host "✓ Copied webhook.lua" -ForegroundColor Green
} else {
    Write-Host "✗ webhook-d-drive.lua not found!" -ForegroundColor Red
}

Write-Host ""

# Configure Windows Firewall
Write-Host "Configuring Windows Firewall..." -ForegroundColor Yellow

try {
    Remove-NetFirewallRule -DisplayName "Orthanc HTTP" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Orthanc DICOM" -ErrorAction SilentlyContinue
    
    New-NetFirewallRule -DisplayName "Orthanc HTTP" -Direction Inbound -LocalPort 8042 -Protocol TCP -Action Allow | Out-Null
    Write-Host "✓ Allowed port 8042 (HTTP)" -ForegroundColor Green
    
    New-NetFirewallRule -DisplayName "Orthanc DICOM" -Direction Inbound -LocalPort 4242 -Protocol TCP -Action Allow | Out-Null
    Write-Host "✓ Allowed port 4242 (DICOM)" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to configure firewall: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Stop existing service if running
Write-Host "Checking for existing Orthanc service..." -ForegroundColor Yellow
$service = Get-Service -Name "Orthanc" -ErrorAction SilentlyContinue

if ($service) {
    Write-Host "Found existing service, stopping..." -ForegroundColor Gray
    Stop-Service -Name "Orthanc" -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    
    # Uninstall existing service
    Set-Location "D:\Program Files\Orthanc Server"
    & $orthancExe --uninstall-service 2>&1 | Out-Null
    Write-Host "✓ Removed existing service" -ForegroundColor Green
}

Write-Host ""

# Install new service
Write-Host "Installing Orthanc as Windows Service..." -ForegroundColor Yellow

try {
    Set-Location "D:\Program Files\Orthanc Server"
    & $orthancExe --install-service $configFile 2>&1 | Out-Null
    Write-Host "✓ Installed Orthanc service" -ForegroundColor Green
} catch {
    Write-Host "✗ Failed to install service: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""

# Start service
Write-Host "Starting Orthanc service..." -ForegroundColor Yellow

try {
    Start-Service -Name "Orthanc" -ErrorAction Stop
    Start-Sleep -Seconds 3
    
    $service = Get-Service -Name "Orthanc"
    if ($service.Status -eq "Running") {
        Write-Host "✓ Orthanc service is running" -ForegroundColor Green
    } else {
        Write-Host "✗ Service status: $($service.Status)" -ForegroundColor Red
    }
} catch {
    Write-Host "✗ Failed to start service: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Try starting manually:" -ForegroundColor Yellow
    Write-Host "  net start Orthanc" -ForegroundColor Cyan
}

Write-Host ""

# Test connection
Write-Host "Testing Orthanc connection..." -ForegroundColor Yellow
Start-Sleep -Seconds 2

try {
    $response = Invoke-WebRequest -Uri "http://localhost:8042/system" -UseBasicParsing -ErrorAction Stop
    Write-Host "✓ Orthanc is accessible at http://localhost:8042" -ForegroundColor Green
} catch {
    Write-Host "✗ Cannot connect to Orthanc" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "1. Check if service is running: Get-Service Orthanc" -ForegroundColor Gray
    Write-Host "2. Try manual start: cd 'D:\Program Files\Orthanc Server'" -ForegroundColor Gray
    Write-Host "   .\Orthanc.exe '$configFile' --verbose" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "1. Open browser: http://localhost:8042" -ForegroundColor White
Write-Host "   Login: orthanc / orthanc" -ForegroundColor Gray
Write-Host ""
Write-Host "2. Test OHIF viewer: http://localhost:8042/ohif/" -ForegroundColor White
Write-Host ""
Write-Host "3. Upload DICOM files and check PACS worklist" -ForegroundColor White
Write-Host ""
Write-Host "Configuration files:" -ForegroundColor Cyan
Write-Host "  Config: $configFile" -ForegroundColor Gray
Write-Host "  Webhook: $webhookFile" -ForegroundColor Gray
Write-Host "  Database: D:\Life Relier\OrthancData\Database" -ForegroundColor Gray
Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
