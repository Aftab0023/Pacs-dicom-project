# Fix IIS Deployment - Invalid User or Password

## Problem
Frontend on IIS (port 3000) showing "Invalid user or password" when connecting to Backend on IIS (port 5000)

---

## Step-by-Step Fix

### Step 1: Verify SQL Server Connection

1. **Open SQL Server Management Studio (SSMS)**
2. **Connect to your SQL Server:**
   - Server: `localhost,1434`
   - Authentication: SQL Server Authentication
   - Login: `sa`
   - Password: `Aftab@3234`

3. **Check if PACSDB exists:**
   - Expand Databases
   - Look for PACSDB

4. **Verify Users table:**
   ```sql
   USE PACSDB;
   SELECT UserId, Email, PasswordHash, Role, IsActive FROM Users;
   ```

### Step 2: Fix User Passwords in Database

**Run this SQL query in SSMS:**

```sql
USE PACSDB;

-- Update admin password to plain text (for testing)
UPDATE Users 
SET PasswordHash = 'admin123' 
WHERE Email = 'admin@pacs.local';

-- Update radiologist password
UPDATE Users 
SET PasswordHash = 'admin123' 
WHERE Email = 'radiologist@pacs.local';

-- Verify the update
SELECT UserId, Email, PasswordHash, Role FROM Users;
```

### Step 3: Test Backend API Directly

1. **Open browser**
2. **Go to:** `http://localhost:5000`
3. **You should see:** API response or Swagger page

4. **Test login endpoint using PowerShell:**

```powershell
$body = @{
    email = "admin@pacs.local"
    password = "admin123"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:5000/api/auth/login" `
    -Method Post `
    -Body $body `
    -ContentType "application/json"
```

**Expected result:** You should get a token response

### Step 4: Check Frontend Configuration

1. **Navigate to frontend folder**
2. **Check if `.env` file exists**
3. **Verify it contains:**
   ```env
   VITE_API_URL=http://localhost:5000/api
   VITE_ORTHANC_URL=http://localhost:8042
   ```

### Step 5: Rebuild Frontend (Important!)

**The frontend needs to be rebuilt after changing .env:**

1. **Open PowerShell in frontend folder**
2. **Run:**
   ```powershell
   npm install --legacy-peer-deps
   npm run build
   ```

3. **Copy the `dist` folder contents to IIS website folder**
   - Source: `frontend/dist/*`
   - Destination: `C:\inetpub\wwwroot\pacs-frontend\` (or your IIS path)

### Step 6: Configure IIS for Frontend

1. **Open IIS Manager**
2. **Select your frontend site**
3. **Click "URL Rewrite"** (if not available, install URL Rewrite module)
4. **Add rule for SPA routing:**

**web.config in frontend folder:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<configuration>
    <system.webServer>
        <rewrite>
            <rules>
                <rule name="React Routes" stopProcessing="true">
                    <match url=".*" />
                    <conditions logicalGrouping="MatchAll">
                        <add input="{REQUEST_FILENAME}" matchType="IsFile" negate="true" />
                        <add input="{REQUEST_FILENAME}" matchType="IsDirectory" negate="true" />
                    </conditions>
                    <action type="Rewrite" url="/" />
                </rule>
            </rules>
        </rewrite>
        <staticContent>
            <mimeMap fileExtension=".json" mimeType="application/json" />
        </staticContent>
    </system.webServer>
</configuration>
```

### Step 7: Configure IIS for Backend API

1. **Open IIS Manager**
2. **Select your backend site**
3. **Application Pool Settings:**
   - .NET CLR Version: No Managed Code
   - Managed Pipeline Mode: Integrated
   - Identity: ApplicationPoolIdentity

4. **Enable CORS in IIS (if needed):**

**web.config in backend folder:**
```xml
<?xml version="1.0" encoding="utf-8"?>
<configuration>
  <system.webServer>
    <handlers>
      <add name="aspNetCore" path="*" verb="*" modules="AspNetCoreModuleV2" resourceType="Unspecified" />
    </handlers>
    <aspNetCore processPath="dotnet" 
                arguments=".\PACS.API.dll" 
                stdoutLogEnabled="true" 
                stdoutLogFile=".\logs\stdout" 
                hostingModel="inprocess" />
    <httpProtocol>
      <customHeaders>
        <add name="Access-Control-Allow-Origin" value="*" />
        <add name="Access-Control-Allow-Methods" value="GET, POST, PUT, DELETE, OPTIONS" />
        <add name="Access-Control-Allow-Headers" value="Content-Type, Authorization" />
      </customHeaders>
    </httpProtocol>
  </system.webServer>
</configuration>
```

### Step 8: Check Windows Firewall

```powershell
# Run as Administrator

# Allow port 3000 (Frontend)
New-NetFirewallRule -DisplayName "IIS Frontend Port 3000" `
    -Direction Inbound `
    -LocalPort 3000 `
    -Protocol TCP `
    -Action Allow

# Allow port 5000 (Backend)
New-NetFirewallRule -DisplayName "IIS Backend Port 5000" `
    -Direction Inbound `
    -LocalPort 5000 `
    -Protocol TCP `
    -Action Allow
```

### Step 9: Restart IIS

```powershell
# Run as Administrator
iisreset
```

### Step 10: Test Again

1. **Open browser**
2. **Go to:** `http://localhost:3000`
3. **Login with:**
   - Email: `admin@pacs.local`
   - Password: `admin123`

---

## Common Issues and Solutions

### Issue 1: "Cannot connect to API"

**Check:**
```powershell
# Test if backend is running
Invoke-WebRequest -Uri "http://localhost:5000" -UseBasicParsing

# Check IIS site status
Get-IISSite
```

**Solution:**
- Ensure backend site is started in IIS
- Check Application Pool is running
- Verify port 5000 is not used by another application

### Issue 2: "CORS Error" in browser console

**Check browser console (F12):**
- Look for "Access-Control-Allow-Origin" errors

**Solution:**
- Add CORS headers in backend web.config (see Step 7)
- Or configure CORS in Program.cs (already done)

### Issue 3: "500 Internal Server Error"

**Check backend logs:**
```powershell
# Navigate to backend folder
cd C:\inetpub\wwwroot\pacs-backend\logs
Get-Content .\stdout*.log -Tail 50
```

**Common causes:**
- Database connection failed
- Missing dependencies
- Wrong connection string

### Issue 4: Frontend shows blank page

**Check:**
1. Browser console (F12) for errors
2. Verify dist folder was copied correctly
3. Check web.config exists in frontend folder

**Solution:**
- Rebuild frontend: `npm run build`
- Copy dist contents to IIS folder
- Add web.config for URL rewrite

### Issue 5: SQL Server connection failed

**Test connection:**
```powershell
# Test SQL Server connectivity
Test-NetConnection -ComputerName localhost -Port 1434
```

**Check SQL Server:**
1. Open SQL Server Configuration Manager
2. SQL Server Network Configuration → Protocols
3. Ensure TCP/IP is Enabled
4. Check TCP/IP Properties → IP Addresses → IPAll → TCP Port = 1434

**Restart SQL Server:**
```powershell
# Run as Administrator
Restart-Service MSSQLSERVER
```

---

## Verification Checklist

- [ ] SQL Server is running on port 1434
- [ ] PACSDB database exists in SSMS
- [ ] Users table has records with plain text passwords
- [ ] Backend API responds at http://localhost:5000
- [ ] Backend can connect to database
- [ ] Frontend .env file has correct API URL
- [ ] Frontend is rebuilt after .env changes
- [ ] Frontend dist folder copied to IIS
- [ ] Both IIS sites are started
- [ ] Application Pools are running
- [ ] Firewall allows ports 3000 and 5000
- [ ] web.config files exist in both sites
- [ ] Can login successfully

---

## Quick Test Commands

```powershell
# Test SQL Server
sqlcmd -S localhost,1434 -U sa -P "Aftab@3234" -Q "SELECT @@VERSION"

# Test Backend API
Invoke-WebRequest -Uri "http://localhost:5000" -UseBasicParsing

# Test Frontend
Invoke-WebRequest -Uri "http://localhost:3000" -UseBasicParsing

# Check IIS Sites
Get-IISSite | Select-Object Name, State, Bindings

# Check Application Pools
Get-IISAppPool | Select-Object Name, State

# View Backend Logs
Get-Content "C:\inetpub\wwwroot\pacs-backend\logs\stdout*.log" -Tail 20
```

---

## Important Notes

1. **Plain Text Passwords:**
   - Only for development/testing
   - For production, use BCrypt hashed passwords

2. **Port Configuration:**
   - Frontend: 3000
   - Backend: 5000
   - SQL Server: 1434
   - Orthanc: 8042 (if using Docker)

3. **IIS Requirements:**
   - .NET Core Hosting Bundle installed
   - URL Rewrite Module installed
   - Application Pools configured correctly

4. **Frontend Build:**
   - Must rebuild after changing .env
   - Copy dist folder contents (not the dist folder itself)
   - Ensure web.config is in the root

---

## Next Steps After Fix

1. **Test login from localhost**
2. **Test from another device on network**
3. **Configure proper user passwords**
4. **Setup HTTPS/SSL**
5. **Configure backup strategy**

---

**Most Common Cause:** Frontend not rebuilt after changing .env file!

**Quick Fix:**
```powershell
cd frontend
npm run build
# Copy dist/* to IIS folder
iisreset
```
