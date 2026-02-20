# Re-index all studies from Orthanc into PACS database
Write-Host "Fetching all studies from Orthanc..." -ForegroundColor Cyan

$auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("orthanc:orthanc"))
$headers = @{Authorization = "Basic $auth"}

$studies = Invoke-RestMethod -Uri "http://localhost:8042/studies" -Method Get -Headers $headers

Write-Host "Found $($studies.Count) studies in Orthanc" -ForegroundColor Green
Write-Host ""

$successCount = 0
$failCount = 0

foreach ($studyId in $studies) {
    Write-Host "Processing study: $studyId"
    
    $payload = @{
        ChangeType = "StableStudy"
        ResourceType = "Study"
        ID = $studyId
        Path = "/studies/$studyId"
        Seq = 0
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "http://localhost:5000/api/orthanc/webhook" -Method Post -Body $payload -ContentType 'application/json' | Out-Null
        Write-Host "  Success!" -ForegroundColor Green
        $successCount++
    }
    catch {
        Write-Host "  Failed!" -ForegroundColor Red
        $failCount++
    }
}

Write-Host ""
Write-Host "Complete! Success: $successCount, Failed: $failCount" -ForegroundColor Cyan
