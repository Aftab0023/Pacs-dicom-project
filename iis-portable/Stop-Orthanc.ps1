# ================================================================
#  Stop-Orthanc.ps1
#  Compatible: Windows 10, Windows Server 2016/2019/2022
#  USAGE: Right-click → Run with PowerShell
# ================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$proc = Get-Process -Name "Orthanc" -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host ""
    Write-Host "  Stopping Orthanc (PID: $($proc.Id))..." -ForegroundColor Yellow
    $proc | Stop-Process -Force
    Start-Sleep -Seconds 1
    Write-Host "  Orthanc stopped." -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host ""
    Write-Host "  Orthanc is not running." -ForegroundColor Gray
    Write-Host ""
}
Read-Host "Press Enter to exit"
