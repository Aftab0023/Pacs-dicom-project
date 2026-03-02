# Test Orthanc Webhook Connection to IIS Backend
# This script tests if Orthanc can successfully send webhooks to the PACS API

Write-Host "Testing Orthanc Webhook Connection..." -ForegroundColor Cyan
Write-Host ""

$webhookUrl = "http://localhost:5000/api/orthanc/webhook"

$testPayload = @{
    ChangeType = "StableStudy"
    ResourceType = "Study"
    ID = "test-study-id-12345"
    Path = "/studies/test-study-id-12345"
    Seq = 0
} | ConvertTo-Json

Write-Host "Webhook URL: $webhookUrl" -ForegroundColor Yellow
Write-Host "Test Payload:" -ForegroundColor Yellow
Write-Host $testPayload
Write-Host ""

try {
    Write-Host "Sending test webhook..." -ForegroundColor Cyan
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testPayload -ContentType "application/json" -ErrorAction Stop
    
    Write-Host "✓ Webhook connection successful!" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
    Write-Host ""
    Write-Host "✓ Orthanc can successfully communicate with PACS Backend!" -ForegroundColor Green
    
} catch {
    Write-Host "✗ Webhook connection failed!" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting steps:" -ForegroundColor Yellow
    Write-Host "1. Verify PACS Backend is running on IIS port 5000"
    Write-Host "2. Check if http://localhost:5000/api/orthanc/webhook is accessible"
    Write-Host "3. Review IIS logs for errors"
    Write-Host "4. Ensure Windows Firewall allows port 5000"
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
