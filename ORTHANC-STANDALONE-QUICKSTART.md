# Orthanc Standalone Quick Start (No Docker)

## Quick Setup Steps

### 1. Download Orthanc
- Go to: https://www.orthanc-server.com/download-windows.php
- Download: `Orthanc-Win64-1.12.1.exe` (or latest version)
- Install to: `C:\Orthanc`

### 2. Download Required Plugins
Go to: https://www.orthanc-server.com/download.php

Download and extract these to `C:\Orthanc\Plugins\`:
- `OrthancOHIF-mainline-Win64.zip` → Extract `OrthancOHIF.dll`
- `OrthancDicomWeb-mainline-Win64.zip` → Extract `OrthancDicomWeb.dll`

### 3. Run Setup Script
Open PowerShell as Administrator:
```powershell
cd path\to\your\pacs\project
.\setup-orthanc-standalone.ps1
```

This script will:
- Create required directories
- Copy configuration files
- Configure Windows Firewall
- Install Orthanc as Windows Service
- Start the service

### 4. Verify Installation
Open browser and go to: `http://localhost:8042`
- Login: `orthanc` / `orthanc`
- You should see Orthanc Explorer

### 5. Test OHIF Viewer
Go to: `http://localhost:8042/ohif/`
- Should load OHIF viewer interface

### 6. Upload Test DICOM Files
1. In Orthanc Explorer, click "Upload"
2. Select DICOM files (.dcm)
3. Wait 10 seconds
4. Check PACS worklist - studies should appear automatically

### 7. Index Existing Studies (if needed)
If you already uploaded studies before webhook was configured:
```powershell
.\index-existing-studies.ps1
```

---

## System Architecture (No Docker)

```
┌─────────────────────────────────────────────────────────┐
│                    Windows Server/PC                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌──────────────┐      ┌──────────────┐                │
│  │   Frontend   │      │   Backend    │                │
│  │  IIS:3000    │─────▶│  IIS:5000    │                │
│  └──────────────┘      └──────┬───────┘                │
│                               │                          │
│                               │                          │
│  ┌──────────────┐            │        ┌──────────────┐ │
│  │   Orthanc    │            │        │  SQL Server  │ │
│  │ Service:8042 │◀───────────┴───────▶│  Port:1434   │ │
│  │   (OHIF)     │                     │   PACSDB     │ │
│  └──────────────┘                     └──────────────┘ │
│         │                                                │
│         │ Webhook (on new study)                        │
│         └──────────────────────────────────────────────▶│
│                    http://localhost:5000/api/orthanc/   │
│                                                           │
└─────────────────────────────────────────────────────────┘
```

---

## Important URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| PACS Frontend | http://localhost:3000 | admin@pacs.local / admin123 |
| PACS Backend | http://localhost:5000 | - |
| Orthanc Explorer | http://localhost:8042 | orthanc / orthanc |
| OHIF Viewer | http://localhost:8042/ohif/ | orthanc / orthanc |
| SQL Server | localhost,1434 | sa / Aftab@3234 |

---

## Configuration Files

| File | Location |
|------|----------|
| Orthanc Config | `C:\Orthanc\Configuration\orthanc.json` |
| Webhook Script | `C:\Orthanc\Configuration\webhook.lua` |
| Backend Config | `backend\PACS.API\appsettings.json` |
| Orthanc Database | `C:\Orthanc\Database\` |
| Orthanc Worklists | `C:\Orthanc\Worklists\` |
| Orthanc Logs | `C:\Orthanc\OrthancLog.txt` |

---

## Useful Commands

### Service Management
```cmd
# Start Orthanc
net start Orthanc

# Stop Orthanc
net stop Orthanc

# Restart Orthanc
net stop Orthanc && net start Orthanc

# Check service status
sc query Orthanc
```

### View Logs
```cmd
# View Orthanc logs
type C:\Orthanc\OrthancLog.txt

# View last 50 lines
powershell "Get-Content C:\Orthanc\OrthancLog.txt -Tail 50"
```

### Test Webhook
```powershell
.\test-orthanc-webhook.ps1
```

### Index Existing Studies
```powershell
.\index-existing-studies.ps1
```

---

## Troubleshooting

### Issue: Service won't start
```cmd
# Run Orthanc in console mode to see errors
cd C:\Orthanc
Orthanc.exe C:\Orthanc\Configuration\orthanc.json --verbose
```

### Issue: OHIF viewer not working
1. Check if `OrthancOHIF.dll` exists in `C:\Orthanc\Plugins\`
2. Restart Orthanc service
3. Go to `http://localhost:8042/system` and verify "OHIF" is in plugins list

### Issue: Studies not appearing in PACS worklist
1. Wait 10 seconds after upload (StableAge setting)
2. Check webhook is configured: `C:\Orthanc\Configuration\webhook.lua`
3. Test webhook: `.\test-orthanc-webhook.ps1`
4. Check backend is running on port 5000
5. Manually index: `.\index-existing-studies.ps1`

### Issue: Cannot access from other devices
1. Check Windows Firewall allows port 8042
2. Verify `RemoteAccessAllowed: true` in orthanc.json
3. Use server IP: `http://192.168.1.24:8042`

---

## Workflow

1. **Upload DICOM** → Orthanc (via web or DICOM C-STORE)
2. **Wait 10 seconds** → Orthanc marks study as "stable"
3. **Webhook triggers** → Sends study info to Backend API
4. **Backend processes** → Extracts metadata, saves to SQL Server
5. **View in PACS** → Study appears in worklist
6. **Open OHIF** → Click "Open Full OHIF Viewer" button

---

## Backup Strategy

### Daily Backup
```powershell
# Backup Orthanc database
$date = Get-Date -Format "yyyy-MM-dd"
Copy-Item "C:\Orthanc\Database" "C:\Backups\Orthanc-$date" -Recurse
```

### SQL Server Backup
```sql
BACKUP DATABASE PACSDB 
TO DISK = 'C:\Backups\PACSDB.bak'
WITH FORMAT, COMPRESSION;
```

---

## Performance Tips

1. **Increase StableAge** if you have slow uploads:
   - Edit `orthanc.json`: `"StableAge": 30`

2. **Increase concurrent jobs** for better performance:
   - Edit `orthanc.json`: `"ConcurrentJobs": 4`

3. **Monitor disk space**:
   - Orthanc database grows with DICOM files
   - Location: `C:\Orthanc\Database\`

---

## Next Steps

1. ✅ Install Orthanc standalone
2. ✅ Configure webhook
3. ✅ Test OHIF viewer
4. ✅ Upload test DICOM files
5. ✅ Verify studies appear in PACS worklist
6. 🔲 Configure DICOM modalities (CT, MRI, X-Ray)
7. 🔲 Set up automated backups
8. 🔲 Configure LAN access for other devices
9. 🔲 Set up SSL/HTTPS (production)
10. 🔲 Configure user permissions

---

## Support

For issues, check:
1. Orthanc logs: `C:\Orthanc\OrthancLog.txt`
2. IIS logs for backend errors
3. Browser console for frontend errors
4. SQL Server logs for database issues

---

## Additional Resources

- Orthanc Documentation: https://book.orthanc-server.com/
- OHIF Viewer: https://ohif.org/
- DICOM Standard: https://www.dicomstandard.org/
