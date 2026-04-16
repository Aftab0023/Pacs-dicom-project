# ================================================================
#  Start-Orthanc.ps1  —  PACS Orthanc Server Launcher
#  Compatible: Windows 10, Windows Server 2016/2019/2022
#
#  USAGE: Right-click → Run with PowerShell
#         OR: powershell -ExecutionPolicy Bypass -File Start-Orthanc.ps1
#
#  Place OrthancPortable folder on E:\ before running.
#  All data folders are created automatically.
# ================================================================

# Allow script execution on older Windows without changing global policy
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ScriptDir   = Split-Path -Parent $MyInvocation.MyCommand.Path

# ── Fixed base path — paste OrthancPortable here ─────────────────
$OrthancBase = "E:\OrthancPortable"
$OrthancExe  = "$OrthancBase\OrthancServer\Orthanc.exe"
$PluginsDir  = "$OrthancBase\OrthancServer\Plugins"
$DataDir     = "$OrthancBase\OrthancData"
$DatabaseDir = "$DataDir\Database"
$WorklistDir = "$DataDir\worklists"
$CacheDir    = "$DataDir\cache"
$LogFile     = "$DataDir\OrthancLog.txt"
$WebhookFile = "$ScriptDir\orthanc\webhook.lua"
$TempConfig  = "$OrthancBase\orthanc-runtime.json"

# ── Validate Orthanc.exe ──────────────────────────────────────────
if (-not (Test-Path $OrthancExe)) {
    Write-Host ""
    Write-Host "  ERROR: Orthanc.exe not found!" -ForegroundColor Red
    Write-Host "  Expected: $OrthancExe" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  Make sure you copied OrthancPortable to E:\" -ForegroundColor Yellow
    Write-Host "  Structure should be:" -ForegroundColor Yellow
    Write-Host "    E:\OrthancPortable\OrthancServer\Orthanc.exe" -ForegroundColor White
    Write-Host "    E:\OrthancPortable\OrthancServer\Plugins\" -ForegroundColor White
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Create all data folders ───────────────────────────────────────
$folders = @($DataDir, $DatabaseDir, $WorklistDir, $CacheDir)
foreach ($f in $folders) {
    if (-not (Test-Path $f)) {
        New-Item -ItemType Directory -Path $f -Force | Out-Null
        Write-Host "  Created: $f" -ForegroundColor DarkGray
    }
}

# ── Check if already running ──────────────────────────────────────
$running = Get-Process -Name "Orthanc" -ErrorAction SilentlyContinue
if ($running) {
    Write-Host ""
    Write-Host "  Orthanc is already running (PID: $($running.Id))" -ForegroundColor Yellow
    Write-Host "  Run Stop-Orthanc.ps1 first if you want to restart." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 0
}

# ── Build runtime config — inject all paths into JSON ─────────────
$cfg = Get-Content "$ScriptDir\orthanc\orthanc.json" -Raw | ConvertFrom-Json

$cfg | Add-Member -Force -NotePropertyName "StorageDirectory" -NotePropertyValue $DatabaseDir
$cfg | Add-Member -Force -NotePropertyName "IndexDirectory"   -NotePropertyValue $DatabaseDir
$cfg | Add-Member -Force -NotePropertyName "LogFile"          -NotePropertyValue $LogFile
$cfg | Add-Member -Force -NotePropertyName "LuaScripts"       -NotePropertyValue @($WebhookFile)
$cfg | Add-Member -Force -NotePropertyName "Plugins"          -NotePropertyValue @($PluginsDir)
$cfg.Worklists | Add-Member -Force -NotePropertyName "Database" -NotePropertyValue $WorklistDir

# ConvertTo-Json depth 10 for full nested object support
$cfg | ConvertTo-Json -Depth 10 | Out-File -FilePath $TempConfig -Encoding utf8 -Force

# ── Print startup banner ──────────────────────────────────────────
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "     PACS Orthanc Server" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "  Base    : $OrthancBase" -ForegroundColor Gray
Write-Host "  Storage : $DatabaseDir" -ForegroundColor Gray
Write-Host "  Worklist: $WorklistDir" -ForegroundColor Gray
Write-Host "  Log     : $LogFile" -ForegroundColor Gray
Write-Host ""
Write-Host "  Web UI  : http://localhost:8042" -ForegroundColor Green
Write-Host "  OHIF    : http://localhost:8042/ohif/" -ForegroundColor Green
Write-Host "  DICOM   : port 4242" -ForegroundColor Green
Write-Host ""
Write-Host "  Login   : orthanc / orthanc" -ForegroundColor White
Write-Host "            admin   / admin" -ForegroundColor White
Write-Host ""
Write-Host "  Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host ""

# ── Launch Orthanc ────────────────────────────────────────────────
& $OrthancExe $TempConfig
