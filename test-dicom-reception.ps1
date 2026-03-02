# Test DICOM Reception Setup
# This script verifies your PACS is ready to receive DICOM from modalities

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "PACS DICOM Reception Test" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Check if Docker containers are running
Write-Host "1. Checking Docker containers..." -ForegroundColor Yellow
$orthancRunning = docker ps --filter "name=pacs-orthanc" --format "{{.Status}}" 2>$null
if ($orthancRunning -like "*Up*") {
    Write-Host "   ✓ Orthanc container is running" -ForegroundColor Green
} else {
    Write-Host "   ✗ Orthanc container is NOT running" -ForegroundColor Red
    Write-Host "   Run: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

# 2. Get server IP address
Write-Host ""
Write-Host "2. Getting server IP address..." -ForegroundColor Yellow
$ipAddress = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*" -or $_.IPAddress -like "10.*"} | Select-Object -First 1).IPAddress
if ($ipAddress) {
    Write-Host "   ✓ Server IP: $ipAddress" -ForegroundColor Green
} else {
    Write-Host "   ! Could not detect LAN IP, using localhost" -ForegroundColor Yellow
    $ipAddress = "localhost"
}

# 3. Test DICOM port
Write-Host ""
Write-Host "3. Testing DICOM port 4242..." -ForegroundColor Yellow
$portTest = Test-NetConnection -ComputerName localhost -Port 4242 -WarningAction SilentlyContinue
if ($portTest.TcpTestSucceeded) {
    Write-Host "   ✓ DICOM port 4242 is open and listening" -ForegroundColor Green
} else {
    Write-Host "   ✗ DICOM port 4242 is not accessible" -ForegroundColor Red
    Write-Host "   Check firewall settings" -ForegroundColor Yellow
}

# 4. Test Orthanc Web UI
Write-Host ""
Write-Host "4. Testing Orthanc Web UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost:8042/system" -UseBasicParsing -TimeoutSec 5 -ErrorAction Stop
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ Orthanc Web UI is accessible" -ForegroundColor Green
    }
}
catch {
    Write-Host "   ✗ Orthanc Web UI is not accessible" -ForegroundColor Red
}

# 5. Check firewall rules
Write-Host ""
Write-Host "5. Checking Windows Firewall rules..." -ForegroundColor Yellow
$firewallRule = Get-NetFirewallRule -DisplayName "DICOM Orthanc" -ErrorAction SilentlyContinue
if ($firewallRule) {
    Write-Host "   ✓ Firewall rule exists for DICOM port" -ForegroundColor Green
} else {
    Write-Host "   ! No firewall rule found" -ForegroundColor Yellow
    Write-Host "   Run: .\setup-firewall-rules.ps1 (as Administrator)" -ForegroundColor Yellow
}

# 6. Display configuration summary
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "MODALITY CONFIGURATION SETTINGS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Configure your modality machine with:" -ForegroundColor White
Write-Host ""
Write-Host "  AE Title:    ORTHANC" -ForegroundColor Green
Write-Host "  IP Address:  $ipAddress" -ForegroundColor Green
Write-Host "  Port:        4242" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# 7. Display access URLs
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Orthanc Web UI:  http://$ipAddress:8042" -ForegroundColor Cyan
Write-Host "  PACS Frontend:   http://$ipAddress:3000" -ForegroundColor Cyan
Write-Host ""

# 8. Display next steps
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "NEXT STEPS" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Configure your modality machine with the settings above" -ForegroundColor White
Write-Host "2. Test connection from modality (DICOM Echo/Verify)" -ForegroundColor White
Write-Host "3. Send a test study from the modality" -ForegroundColor White
Write-Host "4. Check Orthanc Web UI to verify reception" -ForegroundColor White
Write-Host "5. Check PACS Worklist - study should appear automatically" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see: MODALITY-INTEGRATION-GUIDE.md" -ForegroundColor Yellow
Write-Host ""

# 9. Offer to create firewall rule
if (-not $firewallRule) {
    Write-Host "Would you like to create the firewall rule now? (Requires Administrator)" -ForegroundColor Yellow
    $response = Read-Host "Create firewall rule? (Y/N)"
    if ($response -eq "Y" -or $response -eq "y") {
        Write-Host ""
        Write-Host "Creating firewall rules..." -ForegroundColor Yellow
        
        # Check if running as administrator
        $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        
        if ($isAdmin) {
            try {
                New-NetFirewallRule -DisplayName "DICOM Orthanc" -Direction Inbound -Protocol TCP -LocalPort 4242 -Action Allow -ErrorAction Stop | Out-Null
                New-NetFirewallRule -DisplayName "Orthanc Web" -Direction Inbound -Protocol TCP -LocalPort 8042 -Action Allow -ErrorAction Stop | Out-Null
                Write-Host "✓ Firewall rules created successfully!" -ForegroundColor Green
            }
            catch {
                Write-Host "✗ Failed to create firewall rules: $_" -ForegroundColor Red
            }
        }
        else {
            Write-Host "✗ Not running as Administrator. Please run this script as Administrator." -ForegroundColor Red
            Write-Host "Or run: .\setup-firewall-rules.ps1" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "Test complete!" -ForegroundColor Green
Write-Host ""
