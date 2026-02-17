$body = @{
    ChangeType = "StableStudy"
    ResourceType = "Study"
    ID = "a2390fab-3be3e31b-268f6c22-4eb2e70f-6e5d1726"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/orthanc/webhook" -Method POST -ContentType "application/json" -Body $body
