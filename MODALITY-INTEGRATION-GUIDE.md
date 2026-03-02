# Modality Integration Guide - Direct DICOM Reception

Your PACS system is **already configured** to receive DICOM images directly from modality machines (CT, MRI, X-Ray, Ultrasound, etc.) over your LAN network.

## Current Configuration

### Orthanc DICOM Server Settings
- **DICOM Port**: `4242` (Standard DICOM C-STORE port)
- **AE Title**: `PACS Orthanc Server`
- **IP Address**: Your server's IP (e.g., `192.168.1.24` or `localhost`)
- **Status**: ✅ Ready to receive DICOM files

### Pre-configured Modalities
Your system already has example modality configurations:
```json
"DicomModalities": {
  "CT_ROOM1": [ "CT_ROOM1", "192.168.1.60", 104 ],
  "CT_ROOM2": [ "CT_ROOM2", "192.168.1.61", 104 ],
  "MRI_MAIN": [ "MRI_MAIN", "192.168.1.62", 104 ],
  "XRAY_DR":  [ "XRAY_DR",  "192.168.1.63", 104 ]
}
```

## How It Works

```
┌─────────────────┐         DICOM C-STORE          ┌──────────────────┐
│  CT/MRI/X-Ray   │ ──────────────────────────────> │  Orthanc Server  │
│    Machine      │      (Port 4242)                │   (Your PACS)    │
└─────────────────┘                                 └──────────────────┘
                                                             │
                                                             │ Webhook
                                                             ▼
                                                    ┌──────────────────┐
                                                    │   PACS Backend   │
                                                    │   (Auto-index)   │
                                                    └──────────────────┘
```

## Step-by-Step Setup

### 1. Find Your Server's IP Address

**On Windows:**
```powershell
ipconfig
```
Look for "IPv4 Address" (e.g., `192.168.1.24`)

### 2. Ensure Firewall Allows DICOM Port

**Run this PowerShell script (as Administrator):**
```powershell
# Allow DICOM port 4242
New-NetFirewallRule -DisplayName "DICOM Orthanc" -Direction Inbound -Protocol TCP -LocalPort 4242 -Action Allow

# Allow HTTP port 8042 (Orthanc Web UI)
New-NetFirewallRule -DisplayName "Orthanc Web" -Direction Inbound -Protocol TCP -LocalPort 8042 -Action Allow
```

Or use the existing script:
```powershell
.\setup-firewall-rules.ps1
```

### 3. Configure Your Modality Machine

On your CT/MRI/X-Ray machine's DICOM settings, add a new destination:

**DICOM Destination Settings:**
- **AE Title**: `PACS` or `ORTHANC` (case-sensitive)
- **Host/IP Address**: `192.168.1.24` (your server's IP)
- **Port**: `4242`
- **Transfer Syntax**: Any (Orthanc accepts all standard syntaxes)

**Example for Siemens CT:**
1. Go to System → Network → DICOM
2. Add New Destination
3. Enter the settings above
4. Test Connection

**Example for GE MRI:**
1. Service Mode → Network → DICOM Nodes
2. Add Node
3. Enter AE Title, IP, Port
4. Verify Connection

**Example for Philips X-Ray:**
1. Configuration → Network → DICOM Export
2. Add Destination
3. Configure and Test

### 4. Test the Connection

**Option A: From Modality Machine**
- Most modalities have a "Test Connection" or "Echo" button
- This sends a DICOM C-ECHO to verify connectivity

**Option B: Using DICOM Tools**
If you have DICOM tools installed:
```bash
# Test DICOM echo
echoscu -aec ORTHANC 192.168.1.24 4242

# Send a test DICOM file
storescu -aec ORTHANC 192.168.1.24 4242 test.dcm
```

### 5. Send Images from Modality

**Automatic Send (Recommended):**
Configure your modality to automatically send images after acquisition:
- Enable "Auto-Send" or "Auto-Route"
- Select your PACS destination
- Images will be sent immediately after scanning

**Manual Send:**
- Select completed study
- Choose "Send to PACS" or "Export"
- Select your configured destination
- Confirm send

### 6. Verify Reception

**Check Orthanc Web UI:**
1. Open browser: `http://192.168.1.24:8042`
2. Login: `orthanc` / `orthanc`
3. You should see received studies in the list

**Check PACS Frontend:**
1. Open: `http://localhost:3000`
2. Login: `admin@pacs.local` / `admin123`
3. Go to Worklist
4. Studies appear automatically (via webhook)

## Automatic Workflow

Once configured, the workflow is fully automatic:

1. **Technician performs scan** on modality machine
2. **Modality sends DICOM** to Orthanc (port 4242)
3. **Orthanc receives and stores** the images
4. **Webhook triggers** and notifies PACS backend
5. **Backend auto-indexes** study in database
6. **Study appears in Worklist** immediately
7. **Radiologist can view and report** from web interface

## Advanced Configuration

### Add More Modalities

Edit `orthanc/orthanc.json`:
```json
"DicomModalities": {
  "YOUR_CT_NAME": [ "CT_AE_TITLE", "192.168.1.100", 104 ],
  "YOUR_MRI_NAME": [ "MRI_AE_TITLE", "192.168.1.101", 104 ],
  "YOUR_XRAY_NAME": [ "XRAY_AE_TITLE", "192.168.1.102", 104 ]
}
```

Then restart Orthanc:
```powershell
docker-compose restart pacs-orthanc
```

### Configure AE Title Filtering

To accept only specific AE Titles, edit `orthanc/orthanc.json`:
```json
"StrictAetComparison": true,
"DicomCheckCalledAet": true,
"DicomCalledAet": ["ORTHANC", "PACS"]
```

### Enable DICOM TLS (Secure)

For secure DICOM transmission:
```json
"DicomTlsEnabled": true,
"DicomTlsCertificate": "/path/to/cert.pem",
"DicomTlsPrivateKey": "/path/to/key.pem"
```

## Troubleshooting

### Images Not Appearing

**1. Check Orthanc is receiving:**
```powershell
# Check Orthanc logs
docker logs pacs-orthanc
```

**2. Check firewall:**
```powershell
# Test if port is open
Test-NetConnection -ComputerName localhost -Port 4242
```

**3. Check modality configuration:**
- Verify IP address is correct
- Verify port is 4242
- Verify AE Title matches

**4. Check webhook is working:**
```powershell
# Check API logs
docker logs pacs-api
```

### Connection Refused

**Problem:** Modality can't connect to PACS

**Solutions:**
1. Verify server IP address
2. Check firewall rules
3. Ensure Orthanc container is running:
   ```powershell
   docker ps | findstr orthanc
   ```
4. Restart Orthanc:
   ```powershell
   docker-compose restart pacs-orthanc
   ```

### Images Received but Not in Worklist

**Problem:** Images in Orthanc but not in PACS worklist

**Solution:** Check webhook configuration:
```powershell
# Verify webhook.lua is loaded
docker exec pacs-orthanc cat /etc/orthanc/webhook.lua

# Check API is accessible from Orthanc
docker exec pacs-orthanc curl http://pacs-api:8080/api/orthanc/webhook
```

## Network Requirements

### Ports to Open
- **4242**: DICOM C-STORE (modality → PACS)
- **8042**: Orthanc Web UI (optional, for admin)
- **104**: DICOM Query/Retrieve (PACS → modality, optional)

### Network Setup
- All modalities and PACS server must be on same LAN
- Or use VPN if connecting remote sites
- Static IP recommended for PACS server
- DNS hostname can be used instead of IP

## Production Recommendations

### 1. Use Static IP
Configure your server with a static IP address so modalities always know where to send.

### 2. Configure Backup
Set up automatic backup of Orthanc storage:
```powershell
# Backup script
docker exec pacs-orthanc tar -czf /backup/orthanc-$(date +%Y%m%d).tar.gz /var/lib/orthanc/db
```

### 3. Monitor Storage
Check available disk space regularly:
```powershell
docker exec pacs-orthanc df -h /var/lib/orthanc/db
```

### 4. Set Up Redundancy
Consider configuring multiple PACS destinations on modalities for redundancy.

### 5. Enable Audit Logging
All DICOM receptions are automatically logged in the audit system.

## Testing with Sample DICOM Files

If you don't have a real modality yet, you can test with sample DICOM files:

**1. Download sample DICOM files:**
- https://www.dicomlibrary.com/
- https://barre.dev/medical/samples/

**2. Send using Orthanc's upload:**
- Open `http://localhost:8042`
- Click "Upload" button
- Select DICOM files
- Files will be processed automatically

**3. Or use command line:**
```powershell
# Upload via REST API
curl -X POST http://localhost:8042/instances -u orthanc:orthanc --data-binary @sample.dcm
```

## Summary

✅ Your PACS is **ready to receive** DICOM images from modalities
✅ No manual upload needed - fully automatic
✅ Configure modality with: IP + Port 4242 + AE Title
✅ Images appear in worklist automatically
✅ Supports all standard modalities (CT, MRI, X-Ray, US, etc.)

## Support

For modality-specific configuration help:
- Consult your modality's service manual
- Contact modality vendor support
- Most vendors have DICOM configuration guides

Your PACS system is enterprise-ready for direct modality integration!
