# Test OHIF Viewer Direct Access
$studyUID = "1.3.6.1.4.1.44316.6.102.1.20250704114423696.6115867211953577193"
$ohifUrl = "http://localhost:8042/ohif/viewer?StudyInstanceUIDs=$studyUID"

Write-Host "Opening OHIF Viewer..."
Write-Host "URL: $ohifUrl"
Write-Host ""
Write-Host "If browser doesn't open automatically, copy this URL:"
Write-Host $ohifUrl
Write-Host ""
Write-Host "Login credentials for Orthanc:"
Write-Host "Username: orthanc"
Write-Host "Password: orthanc"

# Open in default browser
Start-Process $ohifUrl
