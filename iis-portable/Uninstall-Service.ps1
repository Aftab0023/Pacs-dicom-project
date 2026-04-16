# ================================================================
#  Uninstall-Service.ps1 — Remove Orthanc Windows Service
#  USAGE: Right-click → Run as Administrator
# ================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$ServiceName = "OrthancPACS"

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")
if (-not $isAdmin) {
    Write-Host "  ERROR: Run as Administrator." -ForegroundColor Red
    Read-Host "Press Enter to exit"; exit 1
}

$svc = Get-Service -Name $ServiceName -ErrorAction SilentlyContinue
if ($svc) {
    Write-Host "  Stopping service..." -ForegroundColor Yellow
    Stop-Service -Name $ServiceName -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
    sc.exe delete $ServiceName | Out-Null
    Write-Host "  Service '$ServiceName' removed." -ForegroundColor Green
} else {
    Write-Host "  Service '$ServiceName' not found." -ForegroundColor Gray
}
Write-Host ""
Read-Host "Press Enter to exit"
