# Test LAN Access to PACS System

Write-Host "Testing PACS System LAN Access..." -ForegroundColor Cyan
Write-Host ""

$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}).IPAddress
Write-Host "Server IP: $ip" -ForegroundColor Yellow
Write-Host ""

Write-Host "Checking if ports are listening..." -ForegroundColor Cyan
$ports = @(3000, 5000, 8042, 4242)

foreach ($port in $ports) {
    $result = netstat -an | Select-String ":$port " | Select-String "LISTENING"
    if ($result) {
        Write-Host "  Port $port is listening" -ForegroundColor Green
    } else {
        Write-Host "  Port $port is NOT listening" -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "Testing HTTP endpoints..." -ForegroundColor Cyan

try {
    Invoke-WebRequest -Uri "http://${ip}:8042" -Method Get -TimeoutSec 5 -UseBasicParsing | Out-Null
    Write-Host "  Orthanc (8042): Accessible" -ForegroundColor Green
} catch {
    Write-Host "  Orthanc (8042): Not accessible" -ForegroundColor Red
}

try {
    Invoke-WebRequest -Uri "http://${ip}:5000" -Method Get -TimeoutSec 5 -UseBasicParsing | Out-Null
    Write-Host "  API (5000): Accessible" -ForegroundColor Green
} catch {
    Write-Host "  API (5000): Not accessible" -ForegroundColor Red
}

try {
    Invoke-WebRequest -Uri "http://${ip}:3000" -Method Get -TimeoutSec 5 -UseBasicParsing | Out-Null
    Write-Host "  Frontend (3000): Accessible" -ForegroundColor Green
} catch {
    Write-Host "  Frontend (3000): Not accessible" -ForegroundColor Red
}

Write-Host ""
Write-Host "Access from other devices: http://${ip}:3000" -ForegroundColor Cyan
