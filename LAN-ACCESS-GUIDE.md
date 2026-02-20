# LAN Access Guide - PACS System

## Your Server IP Address
**Host Machine IP:** `192.168.1.24`

## Access URLs from Other Devices on LAN

### 1. PACS Frontend (Main Application)
```
http://192.168.1.24:3000
```
**Login Credentials:**
- Admin: `admin@pacs.local` / `admin123`
- Radiologist: `radiologist@pacs.local` / `admin123`

### 2. Orthanc DICOM Server (Web Interface)
```
http://192.168.1.24:8042
```
**Login Credentials:**
- Username: `orthanc`
- Password: `orthanc`

### 3. PACS API (Backend)
```
http://192.168.1.24:5000/api
```

### 4. DICOM C-STORE (For Modalities)
```
Host: 192.168.1.24
Port: 4242
AE Title: ORTHANC
```

## Important Configuration Changes Needed

### Issue: Frontend API URL
The frontend is currently configured to use `localhost:5000` which only works on the host machine.

### Solution Options:

#### Option 1: Environment Variable (Recommended for Production)
Update `docker-compose.yml` to use the server IP:

```yaml
pacs-frontend:
  environment:
    - VITE_API_URL=http://192.168.1.24:5000/api
```

Then rebuild:
```powershell
docker-compose up -d --build pacs-frontend
```

#### Option 2: Update .env File (For Development)
Update `frontend/.env`:
```env
VITE_API_URL=http://192.168.1.24:5000/api
VITE_ORTHANC_URL=http://192.168.1.24:8042
```

Then rebuild:
```powershell
docker-compose up -d --build pacs-frontend
```

#### Option 3: Use Relative URLs (Best for Both Local and LAN)
Configure nginx to proxy API requests. This way the frontend uses relative URLs that work everywhere.

## Firewall Configuration

### Windows Firewall Rules
You may need to allow incoming connections on these ports:

```powershell
# Allow PACS Frontend
New-NetFirewallRule -DisplayName "PACS Frontend" -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow

# Allow PACS API
New-NetFirewallRule -DisplayName "PACS API" -Direction Inbound -LocalPort 5000 -Protocol TCP -Action Allow

# Allow Orthanc Web
New-NetFirewallRule -DisplayName "Orthanc Web" -Direction Inbound -LocalPort 8042 -Protocol TCP -Action Allow

# Allow DICOM C-STORE
New-NetFirewallRule -DisplayName "DICOM C-STORE" -Direction Inbound -LocalPort 4242 -Protocol TCP -Action Allow
```

Or manually:
1. Open Windows Defender Firewall
2. Click "Advanced settings"
3. Click "Inbound Rules" → "New Rule"
4. Select "Port" → Next
5. Select "TCP" and enter ports: `3000, 5000, 8042, 4242`
6. Allow the connection
7. Apply to all profiles (Domain, Private, Public)
8. Name it "PACS System"

## Testing LAN Access

### From Another Device on the Same Network:

1. **Test Orthanc (Easiest to test first):**
   ```
   http://192.168.1.24:8042
   ```
   Should show Orthanc login page

2. **Test API:**
   ```
   http://192.168.1.24:5000/api
   ```
   Should return a 404 or API response

3. **Test Frontend:**
   ```
   http://192.168.1.24:3000
   ```
   Should show PACS login page

## Network Requirements

✅ Both devices must be on the same network (192.168.1.x)
✅ No VPN or network isolation between devices
✅ Windows Firewall allows the ports
✅ Router doesn't block internal traffic (most don't)

## Troubleshooting

### Can't Access from Other Devices?

1. **Check if ports are listening:**
   ```powershell
   netstat -an | findstr "3000 5000 8042 4242"
   ```
   Should show `0.0.0.0:PORT` or `[::]:PORT`

2. **Test from host machine first:**
   ```powershell
   curl http://192.168.1.24:8042
   ```

3. **Check Windows Firewall:**
   ```powershell
   Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*PACS*"}
   ```

4. **Temporarily disable firewall to test:**
   ```powershell
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False
   # Test access
   # Then re-enable:
   Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True
   ```

## Mobile Device Access

Yes! You can access from:
- ✅ Smartphones (iOS/Android)
- ✅ Tablets
- ✅ Other laptops/desktops
- ✅ Any device on the same WiFi/LAN

Just use the URLs above in any web browser.

## DICOM Modality Configuration

To send DICOM images from a CT/MRI/X-Ray machine:

**AE Title:** ORTHANC
**Host:** 192.168.1.24
**Port:** 4242
**Protocol:** DICOM C-STORE

## Security Notes

⚠️ **Important:**
- This setup is for LOCAL NETWORK only
- Do NOT expose these ports to the internet without proper security
- Use VPN for remote access
- For production, implement:
  - HTTPS/SSL certificates
  - Stronger authentication
  - Network segmentation
  - Proper firewall rules

## Static IP Recommendation

Consider setting a static IP for your server machine:
1. Open Network Settings
2. Change adapter options
3. Right-click your network adapter → Properties
4. Select IPv4 → Properties
5. Use static IP: `192.168.1.24`
6. Subnet: `255.255.255.0`
7. Gateway: `192.168.1.1` (your router)
8. DNS: `8.8.8.8` (Google) or your router IP

This prevents the IP from changing and breaking access.
