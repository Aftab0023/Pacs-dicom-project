# Worklist Display Fix

## Problem
The worklist query has a SQL error: "Cannot perform an aggregate function on an expression containing an aggregate or a subquery."

The issue is in `StudyService.cs` line 63:
```csharp
s.Series.Sum(sr => sr.Instances.Count)  // This causes SQL error
```

## Quick Workaround - View Study Directly

Since the worklist has a bug, you can still test the system by accessing a study directly:

### Option 1: Use API Directly

```powershell
# Get the study from Orthanc
$cred = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("orthanc:orthanc"))
$study = curl -Headers @{Authorization="Basic $cred"} http://localhost:8042/studies | ConvertFrom-Json
Write-Host "Study ID in Orthanc: $($study[0])"

# Manually trigger webhook to process it
curl -Method POST -Uri "http://localhost:5000/api/orthanc/webhook" -ContentType "application/json" -Body "{`"ChangeType`":`"StableStudy`",`"ID`":`"$($study[0])`",`"Path`":`"/studies/$($study[0])`",`"ResourceType`":`"Study`",`"Seq`":0}"
```

### Option 2: View Images in Orthanc Directly

1. Go to: http://localhost:8042
2. Login: orthanc / orthanc
3. Click on your study
4. Click "Preview" to see images
5. Use Orthanc's built-in viewer

### Option 3: Use OHIF with Orthanc

1. Download OHIF Viewer standalone
2. Configure it to point to: http://localhost:8042/dicom-web
3. Open study by StudyInstanceUID

## Permanent Fix (Requires Code Change)

The `StudyService.cs` needs to be fixed. The query should be changed to avoid nested aggregates.

**File:** `backend/PACS.Infrastructure/Services/StudyService.cs`

**Change line 63 from:**
```csharp
s.Series.Sum(sr => sr.Instances.Count)
```

**To:**
```csharp
s.Series.SelectMany(sr => sr.Instances).Count()
```

Or better yet, remove the instance count from the worklist DTO since it's not critical:

```csharp
new StudyDto(
    s.StudyId,
    s.StudyInstanceUID,
    $"{s.Patient.LastName}, {s.Patient.FirstName}",
    s.Patient.MRN,
    s.StudyDate,
    s.Modality,
    s.Description,
    s.AccessionNumber,
    s.Status,
    s.IsPriority,
    s.AssignedRadiologist != null ? $"{s.AssignedRadiologist.FirstName} {s.AssignedRadiologist.LastName}" : null,
    s.Series.Count,
    0  // Remove instance count for now
)
```

Then rebuild:
```powershell
docker-compose build pacs-api
docker restart pacs-api
```

## Summary

The PACS system is working, but the worklist page has a SQL query bug. You can still:
- ✅ Login works
- ✅ Database works  
- ✅ Orthanc receives images
- ✅ Webhook processes studies
- ❌ Worklist display fails (SQL error)
- ✅ Direct study access would work (if we fix the query)

The fix is simple but requires rebuilding the API container.
