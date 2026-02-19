# 📊 Worklist Data Management Guide

## ✅ Current Status: 6 Studies Added Successfully!

Your worklist now contains:
1. **Sarah Johnson** - Brain MRI (🔴 PRIORITY, InProgress)
2. **John Smith** - Chest CT Follow-up (🔴 PRIORITY, Pending)  
3. **Emily Davis** - Pelvic Ultrasound (Normal, Pending)
4. **John Smith** - Chest X-Ray (Normal, Pending)
5. **Michael Brown** - Abdominal CT (Normal, Reported)
6. **Anonymized Patient** - CT KUNAS (Normal, Reported)

## 🎯 How to Add More Data

### Method 1: Add Sample Database Records (Quick Testing)

Create more test studies with this SQL:

```sql
-- Add more patients
INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
VALUES 
    ('33333', 'Robert', 'Wilson', '1970-07-10', 'M', GETUTCDATE()),
    ('44444', 'Lisa', 'Anderson', '1988-11-25', 'F', GETUTCDATE()),
    ('55555', 'David', 'Taylor', '1965-04-08', 'M', GETUTCDATE());

-- Add more studies
INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
VALUES 
    ('1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.25', 6, '2026-02-18', 'MR', 'Knee MRI Left', 'ACC006', 'sample-study-006', 'Pending', 0, GETUTCDATE()),
    ('1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.26', 7, '2026-02-18', 'CT', 'Head CT without contrast', 'ACC007', 'sample-study-007', 'Pending', 1, GETUTCDATE()),
    ('1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.27', 8, '2026-02-18', 'XR', 'Lumbar Spine X-Ray', 'ACC008', 'sample-study-008', 'InProgress', 0, GETUTCDATE());
```

### Method 2: Upload Real DICOM Files (Recommended for Production)

#### Option A: Via Orthanc Web Interface
1. **Open**: http://localhost:8042/app/explorer.html
2. **Login**: `orthanc` / `orthanc`
3. **Click "Upload"** button
4. **Select DICOM files** (.dcm extension)
5. **Upload** - Studies will appear automatically in worklist

#### Option B: Via Command Line
```powershell
# Upload single DICOM file
curl -X POST http://localhost:8042/instances -u orthanc:orthanc --data-binary @"C:\path\to\file.dcm"

# Upload multiple files from folder
Get-ChildItem "C:\DICOM\Files\*.dcm" | ForEach-Object {
    curl -X POST http://localhost:8042/instances -u orthanc:orthanc --data-binary "@$($_.FullName)"
    Write-Host "Uploaded: $($_.Name)"
}
```

#### Option C: Via REST API
```powershell
# PowerShell script to upload DICOM
$orthancUrl = "http://localhost:8042"
$credentials = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("orthanc:orthanc"))

$headers = @{
    "Authorization" = "Basic $credentials"
    "Content-Type" = "application/dicom"
}

$dicomFile = Get-Content "C:\path\to\file.dcm" -Raw -Encoding Byte
Invoke-RestMethod -Uri "$orthancUrl/instances" -Method POST -Headers $headers -Body $dicomFile
```

### Method 3: Bulk Data Generation Script

<function_calls>
<invoke name="fsWrite">
<parameter name="path">generate-bulk-test-data.sqlGenerate Bulk Test Data for PACS Worklist

DECLARE @i INT = 1;
DECLARE @patientCount INT = 20;
DECLARE @studyCount INT = 50;

-- Generate 20 test patients
WHILE @i <= @patientCount
BEGIN
    INSERT INTO Patients (MRN, FirstName, LastName, DateOfBirth, Gender, CreatedAt)
    VALUES (
        'MRN' + RIGHT('00000' + CAST(@i AS VARCHAR), 5),
        CASE (@i % 10)
            WHEN 0 THEN 'James'
            WHEN 1 THEN 'Mary'
            WHEN 2 THEN 'John'
            WHEN 3 THEN 'Patricia'
            WHEN 4 THEN 'Robert'
            WHEN 5 THEN 'Jennifer'
            WHEN 6 THEN 'Michael'
            WHEN 7 THEN 'Linda'
            WHEN 8 THEN 'William'
            ELSE 'Elizabeth'
        END,
        CASE (@i % 8)
            WHEN 0 THEN 'Smith'
            WHEN 1 THEN 'Johnson'
            WHEN 2 THEN 'Williams'
            WHEN 3 THEN 'Brown'
            WHEN 4 THEN 'Jones'
            WHEN 5 THEN 'Garcia'
            WHEN 6 THEN 'Miller'
            ELSE 'Davis'
        END,
        DATEADD(YEAR, -(@i + 20), GETDATE()),
        CASE (@i % 2) WHEN 0 THEN 'M' ELSE 'F' END,
        GETUTCDATE()
    );
    SET @i = @i + 1;
END

-- Generate 50 test studies
SET @i = 1;
WHILE @i <= @studyCount
BEGIN
    INSERT INTO Studies (StudyInstanceUID, PatientId, StudyDate, Modality, Description, AccessionNumber, OrthancStudyId, Status, IsPriority, CreatedAt)
    VALUES (
        '1.2.3.4.5.6.7.8.9.10.11.12.13.14.15.16.17.18.19.' + CAST((100 + @i) AS VARCHAR),
        ((@i - 1) % @patientCount) + 1,  -- Cycle through patients
        DATEADD(DAY, -(@i % 30), GETDATE()),  -- Studies from last 30 days
        CASE (@i % 5)
            WHEN 0 THEN 'CT'
            WHEN 1 THEN 'MR'
            WHEN 2 THEN 'XR'
            WHEN 3 THEN 'US'
            ELSE 'CR'
        END,
        CASE (@i % 10)
            WHEN 0 THEN 'Chest CT with contrast'
            WHEN 1 THEN 'Brain MRI'
            WHEN 2 THEN 'Chest X-Ray'
            WHEN 3 THEN 'Abdominal Ultrasound'
            WHEN 4 THEN 'Lumbar Spine MRI'
            WHEN 5 THEN 'Pelvis CT'
            WHEN 6 THEN 'Knee X-Ray'
            WHEN 7 THEN 'Cardiac Echo'
            WHEN 8 THEN 'Head CT'
            ELSE 'Mammography'
        END,
        'ACC' + RIGHT('0000' + CAST(@i AS VARCHAR), 4),
        'bulk-study-' + RIGHT('000' + CAST(@i AS VARCHAR), 3),
        CASE (@i % 4)
            WHEN 0 THEN 'Pending'
            WHEN 1 THEN 'InProgress'
            WHEN 2 THEN 'Reported'
            ELSE 'Pending'
        END,
        CASE WHEN (@i % 10) = 0 THEN 1 ELSE 0 END,  -- 10% priority
        GETUTCDATE()
    );
    SET @i = @i + 1;
END

-- Show summary
SELECT 
    'Total Patients' AS Category,
    COUNT(*) AS Count
FROM Patients
UNION ALL
SELECT 
    'Total Studies',
    COUNT(*)
FROM Studies
UNION ALL
SELECT 
    'Priority Studies',
    COUNT(*)
FROM Studies WHERE IsPriority = 1
UNION ALL
SELECT 
    'Pending Studies',
    COUNT(*)
FROM Studies WHERE Status = 'Pending';

PRINT 'Bulk test data generated successfully!';