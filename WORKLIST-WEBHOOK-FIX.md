# Worklist Webhook Fix - Completed

## Problem
Studies uploaded to Orthanc were visible in OHIF viewer but not appearing in the PACS worklist.

## Root Cause
The `webhook.lua` script was sending an incomplete payload to the PACS API. The C# DTO `OrthancWebhookPayload` expected 5 fields, but the Lua script was only sending 3:

**Missing fields:**
- `Path` - The REST API path to the resource
- `Seq` - Sequence number for the change

## Solution Applied

### 1. Updated webhook.lua
Fixed the payload structure to match the C# DTO:

```lua
local payload = {
    ChangeType = "StableStudy",
    ResourceType = "Study",
    ID = studyId,
    Path = "/studies/" .. studyId,  -- Added
    Seq = 0                          -- Added
}
```

### 2. Restarted Orthanc
```powershell
docker restart pacs-orthanc
```

### 3. Re-indexed Existing Studies
Created `reindex-orthanc-studies.ps1` script to manually trigger webhooks for all existing studies in Orthanc.

## Verification

✅ Study now appears in database:
- Patient table: 1 record
- Studies table: 1 record (StudyInstanceUID: 1.3.6.1.4.1.44316...)
- Status: Pending
- Description: KUNAS

✅ Worklist API returns the study:
```json
{
  "studies": [
    {
      "studyId": 1,
      "studyInstanceUID": "1.3.6.1.4.1.44316.6.102.1.20250704114423696.61158672119535771932",
      "patientName": "Anonymized, ",
      "mrn": "0",
      "studyDate": "2015-12-07T00:00:00",
      "modality": "",
      "description": "KUNAS",
      "status": "Pending",
      "seriesCount": 2,
      "instanceCount": 0
    }
  ],
  "totalCount": 1
}
```

## Files Modified
1. `orthanc/webhook.lua` - Fixed payload structure
2. `reindex-orthanc-studies.ps1` - Created re-indexing script

## Testing
To test with new uploads:
1. Upload DICOM files to Orthanc (via web UI or DICOM C-STORE)
2. Wait 10 seconds for study to become "stable"
3. Webhook automatically triggers
4. Study appears in worklist within seconds

## Re-indexing Existing Studies
If you have studies in Orthanc that aren't in the worklist:
```powershell
./reindex-orthanc-studies.ps1
```

## Status
✅ **RESOLVED** - Webhook is now working correctly and studies are automatically indexed into the PACS worklist.
