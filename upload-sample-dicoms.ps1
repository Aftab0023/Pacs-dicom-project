# Download and Upload Sample DICOM Files

Write-Host "🔽 Downloading Sample DICOM Files..." -ForegroundColor Cyan

# Create temp directory
$tempDir = "temp-dicom-samples"
if (!(Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

# Download sample DICOM files (these are public domain samples)
$samples = @(
    @{
        Name = "chest-xray.dcm"
        Url = "https://www.dicomlibrary.com/dicom/samples/chest.dcm"
    },
    @{
        Name = "brain-mri.dcm" 
        Url = "https://www.dicomlibrary.com/dicom/samples/brain.dcm"
    }
)

foreach ($sample in $samples) {
    try {
        Write-Host "Downloading $($sample.Name)..." -ForegroundColor Yellow
        Invoke-WebRequest -Uri $sample.Url -OutFile "$tempDir\$($sample.Name)" -ErrorAction Stop
        Write-Host "✅ Downloaded $($sample.Name)" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to download $($sample.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Upload to Orthanc
Write-Host "`n📤 Uploading to Orthanc..." -ForegroundColor Cyan

Get-ChildItem "$tempDir\*.dcm" | ForEach-Object {
    try {
        Write-Host "Uploading $($_.Name)..." -ForegroundColor Yellow
        
        $response = curl -X POST http://localhost:8042/instances `
            -u orthanc:orthanc `
            --data-binary "@$($_.FullName)" `
            --silent
            
        if ($LASTEXITCODE -eq 0) {
            Write-Host "✅ Uploaded $($_.Name)" -ForegroundColor Green
        } else {
            Write-Host "❌ Failed to upload $($_.Name)" -ForegroundColor Red
        }
    } catch {
        Write-Host "❌ Error uploading $($_.Name): $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Clean up
Remove-Item -Recurse -Force $tempDir -ErrorAction SilentlyContinue

Write-Host "`n🎯 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Check Orthanc Explorer: http://localhost:8042/app/explorer.html"
Write-Host "2. Wait for webhook to process new studies (or trigger manually)"
Write-Host "3. Refresh worklist: http://localhost:3000/worklist"
Write-Host "4. New studies should now work in OHIF viewer"