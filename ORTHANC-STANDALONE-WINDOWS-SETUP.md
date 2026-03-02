# Orthanc Standalone Setup for Windows (No Docker)

## Overview
This guide will help you set up Orthanc server directly on Windows without Docker, integrated with your IIS-deployed PACS system.

---

## Prerequisites

1. Windows Server or Windows 10/11
2. IIS with PACS Backend running on port 5000
3. IIS with PACS Frontend running on port 3000
4. SQL Server on localhost,1434

---

## Step 1: Download Orthanc for Windows

1. Go to: https://www.orthanc-server.com/download-windows.php
2. Download the latest **Orthanc Windows Installer** (e.g., `Orthanc-Win64-1.12.1.exe`)
3. Run the installer and install to: `C:\Orthanc`

---

## Step 2: Download Required Plugins

Download these plugins from https://www.orthanc-server.com/download.php:

1. **OHIF Plugin** (for DICOM viewer)
   - Download: `OrthancOHIF-mainline-Win64.zip`
   - Extract to: `C:\Orthanc\Plugins\`

2. **DICOMweb Plugin** (for web access)
   - Download: `OrthancDicomWeb-mainline-Win64.zip`
   - Extract to: `C:\Orthanc\Plugins\`

3. **Web Viewer Plugin** (optional, for basic viewing)
   - Download: `OrthancWebViewer-mainline-Win64.zip`
   - Extract to: `C:\Orthanc\Plugins\`

After extraction, you should have these DLL files in `C:\Orthanc\Plugins\`:
- `OrthancOHIF.dll`
- `OrthancDicomWeb.dll`
- `OrthancWebViewer.dll`

---

## Step 3: Create Configuration Directory

Create these folders:
```
C:\Orthanc\Configuration\
C:\Orthanc\Database\
C:\Orthanc\Worklists\
C:\Orthanc\Cache\
```

---

## Step 4: Create Configuration File

Create `C:\Orthanc\Configuration\orthanc.json` with this content:

```json
{
  "Name": "PACS Orthanc Server",
  "StorageDirectory": "C:\\Orthanc\\Database",
  "IndexDirectory": "C:\\Orthanc\\Database",
  "StorageCompression": false,
  "MaximumStorageSize": 0,
  "MaximumPatientCount": 0,
  
  "HttpPort": 8042,
  "DicomPort": 4242,
  "RemoteAccessAllowed": true,
  "AuthenticationEnabled": true,
  
  "RegisteredUsers": {
    "orthanc": "orthanc",
    "admin": "admin"
  },
  
  "DicomWeb": {
    "Enable": true,
    "Root": "/dicom-web/",
    "EnableWado": true,
    "WadoRoot": "/wado",
    "Ssl": false,
    "QidoCaseSensitive": false,
    "Host": "0.0.0.0",
    "Port": 8042
  },
  
  "Worklists": {
    "Enable": true,
    "Database": "C:\\Orthanc\\Worklists"
  },
  
  "DicomModalities": {
    "CT_ROOM1": [ "CT_ROOM1", "192.168.1.60", 104 ],
    "CT_ROOM2": [ "CT_ROOM2", "192.168.1.61", 104 ],
    "MRI_MAIN": [ "MRI_MAIN", "192.168.1.62", 104 ],
    "XRAY_DR":  [ "XRAY_DR",  "192.168.1.63", 104 ]
  },
  
  "OrthancPeers": {},
  "HttpTimeout": 60,
  "HttpVerbose": false,
  "HttpsVerifyPeers": true,
  "UserMetadata": {},
  "StableAge": 10,
  "StrictAetComparison": false,
  "DicomScpTimeout": 30,
  "SaveJobs": true,
  "JobsHistorySize": 10,
  
  "LuaScripts": [
    "C:\\Orthanc\\Configuration\\webhook.lua"
  ],
  
  "Plugins": [
    "C:\\Orthanc\\Plugins"
  ],
  
  "ConcurrentJobs": 2,
  "HttpRequestTimeout": 30,
  "DefaultEncoding": "Latin1",
  "AcceptedTransferSyntaxes": ["1.2.840.10008.1.*"],
  "UnknownSopClassAccepted": false,
  "DicomScuTimeout": 10,
  "DicomScuPreferredTransferSyntax": "1.2.840.10008.1.2.1",
  "DicomThreadsCount": 4,
  "StoreMD5ForAttachments": true,
  "LimitFindResults": 0,
  "LimitFindInstances": 0,
  "LogExportedResources": false,
  "KeepAlive": true,
  "TcpNoDelay": true,
  "HttpThreadsCount": 50,
  "StoreDicom": true,
  "DicomAssociationCloseDelay": 5,
  "QueryRetrieveSize": 100,
  "CaseSensitivePN": false,
  "LoadPrivateDictionary": true,
  "Dictionary": {},
  "SynchronousCMove": true,
  
  "JobsEngineThreadsCount": {
    "ResourceModification": 1
  },
  
  "DicomCache": {
    "MaximumPatientCount": 0,
    "MaximumStorageSize": 128
  },
  
  "Warnings": {
    "W001_TagsBeingReadFromStorage": true,
    "W002_InconsistentDicomTagsInDb": true
  },
  
  "WebViewer": {
    "CachePath": "C:\\Orthanc\\Cache",
    "CacheSize": 100
  },
  
  "OHIF": {
    "DataSource": "dicom-web",
    "RouterBasename": "/ohif/"
  }
}
```

---

## Step 5: Create Webhook Script

Create `C:\Orthanc\Configuration\webhook.lua` with this content:

```lua
-- PACS Webhook Script (Lua)
-- This script automatically sends new studies to the PACS API

local API_URL = "http://localhost:5000/api/orthanc/webhook"

function OnStableStudy(studyId, tags, metadata)
    print("New stable study detected: " .. studyId)
    
    -- Create webhook payload matching the C# DTO structure
    local payload = {
        ChangeType = "StableStudy",
        ResourceType = "Study",
        ID = studyId,
        Path = "/studies/" .. studyId,
        Seq = 0
    }
    
    -- Convert payload to JSON
    local jsonPayload = DumpJson(payload)
    
    -- Send HTTP POST request to PACS API
    local response = HttpPost(API_URL, jsonPayload, {
        ["Content-Type"] = "application/json"
    })
    
    if response then
        print("Webhook sent successfully for study: " .. studyId)
        print("Response: " .. response)
    else
        print("Failed to send webhook for study: " .. studyId)
    end
end

print("PACS Lua Webhook loaded successfully!")
```

---

## Step 6: Update Backend Configuration

Update `backend/PACS.API/appsettings.json`:

```json
{
  "Logging": {
    "LogLevel": {
      "Default": "Information",
      "Microsoft.AspNetCore": "Warning"
    }
  },
  "AllowedHosts": "*",
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1434;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;"
  },
  "Jwt": {
    "Key": "YourSuperSecretKeyThatIsAtLeast32CharactersLong!",
    "Issuer": "PACSSystem",
    "Audience": "PACSClient"
  },
  "Orthanc": {
    "Url": "http://localhost:8042",
    "Username": "orthanc",
    "Password": "orthanc"
  },
  "Worklist": {
    "Path": "C:\\Orthanc\\Worklists"
  }
}
```

---

## Step 7: Configure Windows Firewall

Open PowerShell as Administrator and run:

```powershell
# Allow Orthanc HTTP port
New-NetFirewallRule -DisplayName "Orthanc HTTP" -Direction Inbound -LocalPort 8042 -Protocol TCP -Action Allow

# Allow Orthanc DICOM port
New-NetFirewallRule -DisplayName "Orthanc DICOM" -Direction Inbound -LocalPort 4242 -Protocol TCP -Action Allow
```

---

## Step 8: Install Orthanc as Windows Service

Open Command Prompt as Administrator:

```cmd
cd C:\Orthanc
Orthanc.exe --install-service C:\Orthanc\Configuration\orthanc.json
```

---

## Step 9: Start Orthanc Service

Option 1: Using Services Manager
1. Press `Win + R`, type `services.msc`
2. Find "Orthanc" service
3. Right-click → Start

Option 2: Using Command Prompt (as Administrator)
```cmd
net start Orthanc
```
🧠 Pro PACS advice (important)

For your setup, you only need these plugins active:

✅ libOrthancOHIF
✅ OrthancDicomWeb
✅ OrthancExplorer2 (optional but good)
✅ GDCM
---

## Step 10: Verify Installation

1. Open browser and go to: `http://localhost:8042`
2. Login with username: `orthanc`, password: `orthanc`
3. You should see the Orthanc Explorer interface

4. Test OHIF viewer: `http://localhost:8042/ohif/`

---

## Step 11: Test Webhook Connection

Create a PowerShell script `test-orthanc-webhook.ps1`:

```powershell
# Test if Orthanc can reach PACS API
$webhookUrl = "http://localhost:5000/api/orthanc/webhook"

$testPayload = @{
    ChangeType = "StableStudy"
    ResourceType = "Study"
    ID = "test-study-id"
    Path = "/studies/test-study-id"
    Seq = 0
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri $webhookUrl -Method Post -Body $testPayload -ContentType "application/json"
    Write-Host "✓ Webhook connection successful!" -ForegroundColor Green
    Write-Host "Response: $response"
} catch {
    Write-Host "✗ Webhook connection failed!" -ForegroundColor Red
    Write-Host "Error: $_"
}
```

Run it:
```powershell
.\test-orthanc-webhook.ps1
```

---

## Step 12: Upload Test DICOM Files

1. Go to Orthanc Explorer: `http://localhost:8042`
2. Click "Upload" button
3. Select DICOM files (.dcm)
4. Wait 10 seconds (StableAge setting)
5. Check PACS worklist - studies should appear automatically

---

## Step 13: Configure LAN Access (Optional)

If you want to access Orthanc from other devices on your network:

1. Find your server IP address:
```cmd
ipconfig
```

2. Update `orthanc.json` if needed (already set to allow remote access)

3. Access from other devices:
   - Orthanc Explorer: `http://192.168.1.24:8042`
   - OHIF Viewer: `http://192.168.1.24:8042/ohif/`

---

## Troubleshooting

### Issue 1: Service won't start
```cmd
# Check logs
cd C:\Orthanc
Orthanc.exe C:\Orthanc\Configuration\orthanc.json --verbose
```

### Issue 2: Plugins not loading
- Verify DLL files are in `C:\Orthanc\Plugins\`
- Check Windows Event Viewer for errors
- Ensure plugins match Orthanc version (64-bit)

### Issue 3: Webhook not working
- Check if backend is running on port 5000
- Test webhook manually using PowerShell script
- Check Orthanc logs: `C:\Orthanc\OrthancLog.txt`

### Issue 4: OHIF viewer shows "Unknown resource"
- Verify `OrthancOHIF.dll` is in Plugins folder
- Restart Orthanc service
- Check plugin loaded: `http://localhost:8042/system` → Look for "OHIF" in plugins list

### Issue 5: Studies not appearing in PACS worklist
- Wait 10 seconds after upload (StableAge)
- Check webhook.lua is loaded
- Verify backend API is accessible from Orthanc
- Check backend logs for webhook errors

---

## Useful Commands

### Stop Orthanc Service
```cmd
net stop Orthanc
```

### Restart Orthanc Service
```cmd
net stop Orthanc
net start Orthanc
```

### Uninstall Service
```cmd
cd C:\Orthanc
Orthanc.exe --uninstall-service
```

### View Orthanc Logs
```cmd
type C:\Orthanc\OrthancLog.txt
```

---

## Integration with PACS System

After Orthanc is running:

1. **Frontend** (IIS port 3000) → Connects to Backend
2. **Backend** (IIS port 5000) → Connects to Orthanc (localhost:8042) and SQL Server (localhost,1434)
3. **Orthanc** (localhost:8042) → Sends webhooks to Backend when new studies arrive
4. **OHIF Viewer** → Embedded in Orthanc (localhost:8042/ohif/)

---

## Next Steps

1. Upload sample DICOM files to test the workflow
2. Verify studies appear in PACS worklist
3. Test OHIF viewer integration
4. Configure DICOM modalities for your imaging devices
5. Set up automated backups for `C:\Orthanc\Database\`

---

## Important Notes

- Orthanc runs as a Windows Service (starts automatically on boot)
- Database location: `C:\Orthanc\Database\`
- Configuration: `C:\Orthanc\Configuration\orthanc.json`
- Logs: `C:\Orthanc\OrthancLog.txt`
- Default credentials: orthanc/orthanc
- Webhook triggers after 10 seconds (StableAge setting)
