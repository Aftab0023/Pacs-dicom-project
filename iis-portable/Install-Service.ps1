# ================================================================
#  Install-Service.ps1
#  Installs Orthanc as a Windows Service (auto-starts on boot)
#  Compatible: Windows 10, Windows Server 2016/2019/2022
#
#  USAGE: Right-click → Run as Administrator
#         OR: powershell -ExecutionPolicy Bypass -File Install-Service.ps1
# ================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ServiceName = "OrthancPACS"
$DisplayName = "PACS Orthanc Server"
$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Admin check ───────────────────────────────────────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host ""
    Write-Host "  ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host "  Right-click the file and select 'Run as Administrator'" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Fixed base path ───────────────────────────────────────────────
$OrthancBase = "E:\OrthancPortable"
$OrthancExe  = "$OrthancBase\OrthancServer\Orthanc.exe"
$PluginsDir  = "$OrthancBase\OrthancServer\Plugins"
$DataDir     = "$OrthancBase\OrthancData"
$DatabaseDir = "$DataDir\Database"
$WorklistDir = "$DataDir\worklists"
$CacheDir    = "$DataDir\cache"
$LogFile     = "$DataDir\OrthancLog.txt"
$WebhookFile = "$ScriptDir\orthanc\webhook.lua"
$ServiceCfg  = "$OrthancBase\orthanc-service.json"

# ── Validate Orthanc.exe ──────────────────────────────────────────
if (-not (Test-Path $OrthancExe)) {
    Write-Host ""
    Write-Host "  ERROR: Orthanc.exe not found at $OrthancExe" -ForegroundColor Red
    Write-Host "  Copy OrthancPortable to E:\ first." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Create data folders ───────────────────────────────────────────
foreach ($f in @($DataDir, $DatabaseDir, $WorklistDir, $CacheDir)) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f -Force | Out-Null
        Write-Host "  Created: $f" -ForegroundColor DarkGray
    }
}

# ── Build permanent service config ───────────────────────────────
$cfg = Get-Content "$ScriptDir\orthanc\orthanc.json" -Raw | ConvertFrom-Json
$cfg | Add-Member -Force -NotePropertyName "StorageDirectory" -NotePropertyValue $DatabaseDir
$cfg | Add-Member -Force -NotePropertyName "IndexDirectory"   -NotePropertyValue $DatabaseDir
$cfg | Add-Member -Force -NotePropertyName "LogFile"          -NotePropertyValue $LogFile
$cfg | Add-Member -Force -NotePropertyName "LuaScripts"       -NotePropertyValue @($WebhookFile)
$cfg | Add-Member -Force -NotePropertyName "Plugins"          -NotePropertyValue @($PluginsDir)
$cfg.Worklists | Add-Member -Force -NotePropertyName "Database" -NotePropertyValue $WorklistDir
$cfg | ConvertTo-Json -Depth 10 | Out-File -FilePath $ServiceCfg -Encoding utf8 -Force
Write-Host "  Config  : $ServiceCfg" -ForegroundColor DarkGray

# ── Remove old service if exists ─────────────────────────────────
$existing = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "  Removing old service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    sc.exe delete $ServiceName | Out-Null
    Start-Sleep -Seconds 2
}

# ── Install service using sc.exe (works on all Windows versions) ──
$binPath = "`"$OrthancExe`" `"$ServiceCfg`""
sc.exe create $ServiceName binPath= $binPath start= auto DisplayName= $DisplayName | Out-Null
sc.exe description $ServiceName "Orthanc DICOM Server for PACS System" | Out-Null

# Set recovery — restart on failure
sc.exe failure $ServiceName reset= 86400 actions= restart/5000/restart/10000/restart/30000 | Out-Null

# ── Start the service ─────────────────────────────────────────────
Start-Sleep -Seconds 1
Start-Service -Name $ServiceName -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2
$status = (Get-Service -Name $ServiceName -ErrorAction SilentlyContinue).Status

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Green
Write-Host "     Orthanc Service Installed!" -ForegroundColor Green
Write-Host "  ================================================" -ForegroundColor Green
Write-Host "  Service : $ServiceName" -ForegroundColor White
Write-Host "  Status  : $status" -ForegroundColor $(if ($status -eq "Running") { "Green" } else { "Yellow" })
Write-Host "  Config  : $ServiceCfg" -ForegroundColor Gray
Write-Host ""
Write-Host "  Web UI  : http://localhost:8042" -ForegroundColor Cyan
Write-Host "  DICOM   : port 4242" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Auto-starts on every Windows boot." -ForegroundColor Yellow
Write-Host "  ================================================" -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to exit"
