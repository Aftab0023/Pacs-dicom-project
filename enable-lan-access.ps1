# Enable LAN Access for PACS System
# This script rebuilds the frontend with LAN IP configuration

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PACS System - Enable LAN Access" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Get server IP
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
Write-Host "Your server IP: $ip" -ForegroundColor Yellow
Write-Host ""

# Check if running as admin
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if ($isAdmin) {
    Write-Host "Step 1: Setting up firewall rules..." -ForegroundColor Cyan
    
    # Remove old rules
    Remove-NetFirewallRule -DisplayName "PACS Frontend" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "PACS API" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "Orthanc Web" -ErrorAction SilentlyContinue
    Remove-NetFirewallRule -DisplayName "DICOM C-STORE" -ErrorAction SilentlyContinue
    
    # Create new rules
    New-NetFirewallRule -DisplayName "PACS Frontend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName "PACS API" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName "Orthanc Web" -Direction Inbound -LocalPort 8042 -Protocol TCP -Action Allow -Profile Any | Out-Null
    New-NetFirewallRule -DisplayName "DICOM C-STORE" -Direction Inbound -LocalPort 4242 -Protocol TCP -Action Allow -Profile Any | Out-Null
    
    Write-Host "  Firewall rules created!" -ForegroundColor Green
} else {
    Write-Host "Step 1: Skipping firewall setup (not running as Administrator)" -ForegroundColor Yellow
    Write-Host "  To setup firewall, run this script as Administrator" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Step 2: Rebuilding frontend with LAN configuration..." -ForegroundColor Cyan
Write-Host "  This may take a few minutes..." -ForegroundColor Yellow
Write-Host ""

# Stop frontend
docker stop pacs-frontend 2>&1 | Out-Null

# Remove old container
docker rm pacs-frontend 2>&1 | Out-Null

# Rebuild and start
docker-compose up -d --build pacs-frontend

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  LAN Access Enabled!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs from any device on your network:" -ForegroundColor Cyan
Write-Host ""
Write-Host "  PACS System:  http://${ip}:3000" -ForegroundColor White
Write-Host "  Orthanc:      http://${ip}:8042" -ForegroundColor White
Write-Host ""
Write-Host "Login Credentials:" -ForegroundColor Cyan
Write-Host "  Admin:        admin@pacs.local / admin123" -ForegroundColor White
Write-Host "  Radiologist:  radiologist@pacs.local / admin123" -ForegroundColor White
Write-Host ""
Write-Host "Orthanc Login:" -ForegroundColor Cyan
Write-Host "  Username:     orthanc" -ForegroundColor White
Write-Host "  Password:     orthanc" -ForegroundColor White
Write-Host ""
