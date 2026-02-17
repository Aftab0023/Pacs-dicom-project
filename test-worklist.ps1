# Login
$loginBody = @{
    email = "admin@pacs.local"
    password = "Admin123!"
} | ConvertTo-Json

$loginResponse = Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" -Method POST -ContentType "application/json" -Body $loginBody
$token = $loginResponse.token

Write-Host "Logged in successfully"
Write-Host "Token: $($token.Substring(0, 50))..."

# Get worklist
$headers = @{
    Authorization = "Bearer $token"
}

$worklist = Invoke-RestMethod -Uri "http://localhost:5000/api/worklist?page=1&pageSize=10" -Method GET -Headers $headers

Write-Host "`nWorklist Results:"
Write-Host "Total Count: $($worklist.totalCount)"
Write-Host "Studies:"
$worklist.studies | Format-Table -Property studyId, patientName, studyDate, modality, description, status
