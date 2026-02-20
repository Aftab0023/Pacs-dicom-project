# Setup Windows Firewall Rules for PACS LAN Access
# Run this script as Administrator

Write-Host "Setting up Windows Firewall rules for PACS System..." -ForegroundColor Cyan
Write-Host ""

# Check if running as Administrator
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as Administrator'" -ForegroundColor Yellow
    exit 1
}

# Remove existing rules if they exist
Write-Host "Removing old rules (if any)..." -ForegroundColor Yellow
Remove-NetFirewallRule -DisplayName "PACS Frontend" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "PACS API" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "Orthanc Web" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "DICOM C-STORE" -ErrorAction SilentlyContinue

# Create new rules
Write-Host "Creating firewall rules..." -ForegroundColor Green

# PACS Frontend (Port 3000)
New-NetFirewallRule -DisplayName "PACS Frontend" `
    -Direction Inbound `
    -LocalPort 3000 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Allow access to PACS web interface" | Out-Null
Write-Host "  ✓ PACS Frontend (Port 3000)" -ForegroundColor Green

# PACS API (Port 5000)
New-NetFirewallRule -DisplayName "PACS API" `
    -Direction Inbound `
    -LocalPort 5000 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Allow access to PACS API backend" | Out-Null
Write-Host "  ✓ PACS API (Port 5000)" -ForegroundColor Green

# Orthanc Web Interface (Port 8042)
New-NetFirewallRule -DisplayName "Orthanc Web" `
    -Direction Inbound `
    -LocalPort 8042 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Allow access to Orthanc DICOM server web interface" | Out-Null
Write-Host "  ✓ Orthanc Web (Port 8042)" -ForegroundColor Green

# DICOM C-STORE (Port 4242)
New-NetFirewallRule -DisplayName "DICOM C-STORE" `
    -Direction Inbound `
    -LocalPort 4242 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Allow DICOM modalities to send images" | Out-Null
Write-Host "  ✓ DICOM C-STORE (Port 4242)" -ForegroundColor Green

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Firewall rules created successfully!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get and display IP address
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
Write-Host "Your server IP address: $ip" -ForegroundColor Yellow
Write-Host ""
Write-Host "Access URLs from other devices:" -ForegroundColor Cyan
Write-Host "  Frontend:  http://${ip}:3000" -ForegroundColor White
Write-Host "  Orthanc:   http://${ip}:8042" -ForegroundColor White
Write-Host "  API:       http://${ip}:5000/api" -ForegroundColor White
Write-Host ""
Write-Host "DICOM Modality Settings:" -ForegroundColor Cyan
Write-Host "  AE Title:  ORTHANC" -ForegroundColor White
Write-Host "  Host:      $ip" -ForegroundColor White
Write-Host "  Port:      4242" -ForegroundColor White
Write-Host ""
