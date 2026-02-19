# Test Worklist with New Sample Data

# Login first
$loginBody = @{
    email = "admin@pacs.local"
    password = "Admin123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody
$token = $loginResponse.token

Write-Host "Logged in successfully" -ForegroundColor Green

# Get worklist
$headers = @{
    Authorization = "Bearer $token"
}

$worklist = Invoke-RestMethod -Uri "http://localhost:5000/api/worklist?page=1&pageSize=20" -Method GET -Headers $headers

Write-Host "`nWorklist Results:" -ForegroundColor Cyan
Write-Host "Total Studies: $($worklist.totalCount)" -ForegroundColor Yellow

if ($worklist.studies -and $worklist.studies.Count -gt 0) {
    Write-Host "`nStudies Found:" -ForegroundColor Green
    $worklist.studies | ForEach-Object {
        $priority = if ($_.isPriority) { "PRIORITY" } else { "Normal" }
        Write-Host "  - $($_.patientName) - $($_.modality) - $($_.studyDate.Substring(0,10)) - $($_.status) - $priority"
    }
} else {
    Write-Host "No studies found in worklist" -ForegroundColor Red
}

Write-Host "`nOpen worklist in browser: http://localhost:3000/worklist" -ForegroundColor Cyan