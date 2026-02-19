# Test Updated Worklist with New Study

# Login
$loginBody = @{
    email = "admin@pacs.local"
    password = "Admin123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody
$token = $loginResponse.token

Write-Host "✅ Logged in successfully" -ForegroundColor Green

# Get worklist
$headers = @{
    Authorization = "Bearer $token"
}

$worklist = Invoke-RestMethod -Uri "http://localhost:5000/api/worklist?page=1&pageSize=20" -Method GET -Headers $headers

Write-Host "`n📊 Updated Worklist Results:" -ForegroundColor Cyan
Write-Host "Total Studies: $($worklist.totalCount)" -ForegroundColor Yellow

if ($worklist.studies -and $worklist.studies.Count -gt 0) {
    Write-Host "`n📋 Studies Found:" -ForegroundColor Green
    $worklist.studies | ForEach-Object {
        $priority = if ($_.isPriority) { "PRIORITY" } else { "Normal" }
        $workingStatus = if ($_.description -eq "KUNAS" -or $_.description -eq "Echocardiogram") { "✅ WORKING" } else { "⚠️ Fake" }
        Write-Host "  - $($_.patientName) - $($_.modality) - $($_.description) - $workingStatus"
    }
    
    Write-Host "`n🎯 Studies that will work in OHIF viewer:" -ForegroundColor Green
    $workingStudies = $worklist.studies | Where-Object { $_.description -eq "KUNAS" -or $_.description -eq "Echocardiogram" }
    $workingStudies | ForEach-Object {
        Write-Host "  ✅ $($_.description) - Study ID: $($_.studyId)"
    }
} else {
    Write-Host "❌ No studies found in worklist" -ForegroundColor Red
}

Write-Host "`n🌐 Test in browser: http://localhost:3000/worklist" -ForegroundColor Cyan