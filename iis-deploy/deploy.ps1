# ============================================================
# PACS Full IIS Deployment Script
# Run as Administrator in PowerShell
# ============================================================

param(
    [string]$ServerIP = "YOUR_SERVER_IP",
    [string]$ApiPort  = "5000",
    [string]$FrontendPort = "80"
)

$ErrorActionPreference = "Stop"
$ScriptDir  = Split-Path -Parent $MyInvocation.MyCommand.Path
$ProjectDir = Split-Path -Parent $ScriptDir
$ApiOut     = "C:\inetpub\pacs-api"
$FrontOut   = "C:\inetpub\pacs-frontend"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PACS IIS Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# ── 0. Validate Admin ────────────────────────────────────────
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")) {
    Write-Host "ERROR: Run this script as Administrator." -ForegroundColor Red
    exit 1
}

# ── 1. Check Prerequisites ───────────────────────────────────
Write-Host "[1/7] Checking prerequisites..." -ForegroundColor Yellow

# .NET 8 Hosting Bundle
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if (-not $dotnet) {
    Write-Host "ERROR: .NET SDK not found. Install .NET 8 Hosting Bundle from:" -ForegroundColor Red
    Write-Host "       https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -ForegroundColor Red
    exit 1
}
Write-Host "  .NET: OK" -ForegroundColor Green

# Node.js
$node = Get-Command node -ErrorAction SilentlyContinue
if (-not $node) {
    Write-Host "ERROR: Node.js not found. Install from https://nodejs.org" -ForegroundColor Red
    exit 1
}
Write-Host "  Node.js: OK" -ForegroundColor Green

# IIS
$iis = Get-Service W3SVC -ErrorAction SilentlyContinue
if (-not $iis) {
    Write-Host "ERROR: IIS not installed. Enable via: Turn Windows features on/off > Internet Information Services" -ForegroundColor Red
    exit 1
}
Write-Host "  IIS: OK" -ForegroundColor Green

# ── 2. Build Backend ─────────────────────────────────────────
Write-Host ""
Write-Host "[2/7] Building .NET API..." -ForegroundColor Yellow

$apiProject = Join-Path $ProjectDir "backend\PACS.API\PACS.API.csproj"
if (-not (Test-Path $apiProject)) {
    Write-Host "ERROR: Cannot find $apiProject" -ForegroundColor Red
    exit 1
}

if (Test-Path $ApiOut) { Remove-Item $ApiOut -Recurse -Force }
New-Item -ItemType Directory -Path $ApiOut | Out-Null
New-Item -ItemType Directory -Path "$ApiOut\logs" | Out-Null

dotnet publish $apiProject -c Release -o $ApiOut --nologo
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: API build failed." -ForegroundColor Red; exit 1 }

# Copy IIS appsettings and web.config
Copy-Item "$ScriptDir\appsettings.json" "$ApiOut\appsettings.json" -Force
Copy-Item "$ScriptDir\api-web.config"   "$ApiOut\web.config" -Force

Write-Host "  API built to: $ApiOut" -ForegroundColor Green

# ── 3. Build Frontend ────────────────────────────────────────
Write-Host ""
Write-Host "[3/7] Building React frontend..." -ForegroundColor Yellow

$frontendDir = Join-Path $ProjectDir "frontend"
if (-not (Test-Path $frontendDir)) {
    Write-Host "ERROR: Cannot find frontend folder" -ForegroundColor Red
    exit 1
}

# Update .env with server IP before build
$envContent = "VITE_API_URL=http://${ServerIP}:${ApiPort}/api`nVITE_ORTHANC_URL=http://${ServerIP}:8042"
Set-Content "$frontendDir\.env" $envContent

Push-Location $frontendDir
npm install --legacy-peer-deps --silent
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: npm install failed." -ForegroundColor Red; Pop-Location; exit 1 }

npm run build
if ($LASTEXITCODE -ne 0) { Write-Host "ERROR: Frontend build failed." -ForegroundColor Red; Pop-Location; exit 1 }
Pop-Location

if (Test-Path $FrontOut) { Remove-Item $FrontOut -Recurse -Force }
Copy-Item "$frontendDir\dist" $FrontOut -Recurse -Force

# Copy web.config and runtime config.js
Copy-Item "$ScriptDir\frontend-web.config" "$FrontOut\web.config" -Force

# Write config.js with actual server IP
$configJs = @"
// ============================================================
// PACS Runtime Configuration
// Edit API_URL and ORTHANC_URL to change backend URLs.
// No rebuild required — just save and refresh the browser.
// ============================================================
window.__PACS_CONFIG__ = {
  API_URL: "http://${ServerIP}:${ApiPort}/api",
  ORTHANC_URL: "http://${ServerIP}:8042"
};
"@
Set-Content "$FrontOut\config.js" $configJs

Write-Host "  Frontend built to: $FrontOut" -ForegroundColor Green

# ── 4. Configure IIS App Pools ───────────────────────────────
Write-Host ""
Write-Host "[4/7] Configuring IIS Application Pools..." -ForegroundColor Yellow

Import-Module WebAdministration

# API App Pool — No Managed Code (ASP.NET Core runs out of process via ANCM)
if (Test-Path "IIS:\AppPools\PACS-API") {
    Remove-WebAppPool -Name "PACS-API"
}
New-WebAppPool -Name "PACS-API"
Set-ItemProperty "IIS:\AppPools\PACS-API" managedRuntimeVersion ""
Set-ItemProperty "IIS:\AppPools\PACS-API" processModel.identityType LocalSystem
Write-Host "  App Pool PACS-API: OK" -ForegroundColor Green

# Frontend App Pool
if (Test-Path "IIS:\AppPools\PACS-Frontend") {
    Remove-WebAppPool -Name "PACS-Frontend"
}
New-WebAppPool -Name "PACS-Frontend"
Set-ItemProperty "IIS:\AppPools\PACS-Frontend" managedRuntimeVersion ""
Write-Host "  App Pool PACS-Frontend: OK" -ForegroundColor Green

# ── 5. Configure IIS Sites ───────────────────────────────────
Write-Host ""
Write-Host "[5/7] Configuring IIS Sites..." -ForegroundColor Yellow

# Remove existing sites if present
if (Get-Website -Name "PACS-API" -ErrorAction SilentlyContinue) {
    Remove-Website -Name "PACS-API"
}
if (Get-Website -Name "PACS-Frontend" -ErrorAction SilentlyContinue) {
    Remove-Website -Name "PACS-Frontend"
}

# API Site on port 5000
New-Website -Name "PACS-API" `
    -PhysicalPath $ApiOut `
    -ApplicationPool "PACS-API" `
    -Port $ApiPort `
    -Force
Write-Host "  Site PACS-API on port $ApiPort : OK" -ForegroundColor Green

# Frontend Site on port 80
New-Website -Name "PACS-Frontend" `
    -PhysicalPath $FrontOut `
    -ApplicationPool "PACS-Frontend" `
    -Port $FrontendPort `
    -Force
Write-Host "  Site PACS-Frontend on port $FrontendPort : OK" -ForegroundColor Green

# ── 6. Set Folder Permissions ────────────────────────────────
Write-Host ""
Write-Host "[6/7] Setting folder permissions..." -ForegroundColor Yellow

$acl = Get-Acl $ApiOut
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    "IIS AppPool\PACS-API", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
$acl.SetAccessRule($rule)
Set-Acl $ApiOut $acl
Write-Host "  Permissions set for $ApiOut" -ForegroundColor Green

# ── 7. Open Firewall Ports ───────────────────────────────────
Write-Host ""
Write-Host "[7/7] Opening firewall ports..." -ForegroundColor Yellow

$ports = @(
    @{Name="PACS Frontend HTTP"; Port=80},
    @{Name="PACS API";           Port=5000},
    @{Name="PACS Orthanc";       Port=8042}
)
foreach ($p in $ports) {
    $existing = Get-NetFirewallRule -DisplayName $p.Name -ErrorAction SilentlyContinue
    if ($existing) { Remove-NetFirewallRule -DisplayName $p.Name }
    New-NetFirewallRule -DisplayName $p.Name -Direction Inbound -Protocol TCP -LocalPort $p.Port -Action Allow | Out-Null
    Write-Host "  Port $($p.Port) ($($p.Name)): opened" -ForegroundColor Green
}

# ── Start IIS ────────────────────────────────────────────────
Start-Service W3SVC -ErrorAction SilentlyContinue
Start-Website -Name "PACS-API"
Start-Website -Name "PACS-Frontend"

# ── Done ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "  Frontend : http://${ServerIP}" -ForegroundColor Cyan
Write-Host "  API      : http://${ServerIP}:${ApiPort}" -ForegroundColor Cyan
Write-Host "  Swagger  : http://${ServerIP}:${ApiPort}/swagger" -ForegroundColor Cyan
Write-Host "  Orthanc  : http://${ServerIP}:8042" -ForegroundColor Cyan
Write-Host ""
Write-Host "  To change API URL after deployment:" -ForegroundColor Yellow
Write-Host "  Edit: $FrontOut\config.js" -ForegroundColor Yellow
Write-Host ""
