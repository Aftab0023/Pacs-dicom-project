# Use Existing Database from Another System

## Scenario: Deploy PACS on New PC but Use Database from Current PC

---

## Architecture Overview

```
Current PC (192.168.1.24)          New PC (192.168.1.150)
├── SQL Server Database     →      ├── PACS API (connects to 192.168.1.24)
├── Orthanc DICOM Data      →      ├── Orthanc (connects to 192.168.1.24)
└── (Keep running)                 ├── Frontend
                                   └── (New deployment)
```

---

## Option 1: Connect to Remote Database (Recommended)

### Step 1: Prepare Current PC (Database Server)

**On your CURRENT PC (192.168.1.24):**

1. **Ensure SQL Server container allows external connections:**

Edit `docker-compose.yml` on current PC:
```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: pacs-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Aftab@3234
      - MSSQL_PID=Developer
    ports:
      - "0.0.0.0:1433:1433"  # Bind to all interfaces
    volumes:
      - sqlserver-data:/var/opt/mssql
    networks:
      - pacs-network
    restart: unless-stopped
```

2. **Configure Windows Firewall to allow SQL Server:**

```powershell
# Run as Administrator on CURRENT PC
New-NetFirewallRule -DisplayName "SQL Server Remote Access" `
    -Direction Inbound `
    -LocalPort 1433 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Allow remote SQL Server connections"
```

3. **Restart SQL Server container:**

```powershell
docker-compose restart sqlserver
```

4. **Test connection from current PC:**

```powershell
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P "Aftab@3234" `
    -C `
    -Q "SELECT @@VERSION"
```

### Step 2: Configure New PC to Use Remote Database

**On your NEW PC (192.168.1.150):**

1. **Edit `docker-compose.yml`:**

```yaml
services:
  # REMOVE or COMMENT OUT the sqlserver service
  # sqlserver:
  #   image: mcr.microsoft.com/mssql/server:2022-latest
  #   ...

  pacs-api:
    build:
      context: ./backend
      dockerfile: PACS.API/Dockerfile
    container_name: pacs-api
    ports:
      - "5000:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      # Point to CURRENT PC's SQL Server
      - ConnectionStrings__DefaultConnection=Server=192.168.1.24,1433;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;
      - Orthanc__Url=http://orthanc:8042
      - Orthanc__Username=orthanc
      - Orthanc__Password=orthanc
    networks:
      - pacs-network
    # Remove depends_on for sqlserver
    restart: unless-stopped

  orthanc:
    image: jodogne/orthanc-plugins:latest
    container_name: pacs-orthanc
    ports:
      - "8042:8042"
      - "4242:4242"
    volumes:
      - ./orthanc/orthanc.json:/etc/orthanc/orthanc.json:ro
      - ./orthanc/webhook.lua:/etc/orthanc/webhook.lua:ro
      - orthanc-data:/var/lib/orthanc/db
      - orthanc-cache:/var/lib/orthanc/cache
    networks:
      - pacs-network
    depends_on:
      - pacs-api
    restart: unless-stopped

  pacs-frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pacs-frontend
    ports:
      - "3000:80"
    networks:
      - pacs-network
    depends_on:
      - pacs-api
    restart: unless-stopped

volumes:
  # Remove sqlserver-data volume
  orthanc-data:
  orthanc-cache:

networks:
  pacs-network:
    driver: bridge
```

2. **Update webhook to point to new API:**

Edit `orthanc/webhook.lua`:
```lua
-- Point to NEW PC's API
local API_URL = "http://pacs-api:8080/api/orthanc/webhook"
```

3. **Test database connection from new PC:**

```powershell
# Test connection to remote SQL Server
Test-NetConnection -ComputerName 192.168.1.24 -Port 1433
```

### Step 3: Deploy on New PC

```powershell
cd C:\PACS

# Build images
docker-compose build --no-cache

# Start services (without SQL Server)
docker-compose up -d

# Check logs
docker-compose logs -f pacs-api
```

---

## Option 2: Copy Database to New PC

### Step 1: Backup Database from Current PC

**On CURRENT PC:**

```powershell
# Create backup
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "Aftab@3234" -C `
    -Q "BACKUP DATABASE PACSDB TO DISK = '/var/opt/mssql/backup/PACSDB.bak'"

# Copy backup file to host
docker cp pacs-sqlserver:/var/opt/mssql/backup/PACSDB.bak C:\PACS\PACSDB.bak
```

### Step 2: Transfer Backup to New PC

Copy `C:\PACS\PACSDB.bak` to new PC (USB drive or network)

### Step 3: Restore on New PC

**On NEW PC:**

```powershell
# Copy backup into container
docker cp C:\PACS\PACSDB.bak pacs-sqlserver:/var/opt/mssql/backup/

# Restore database
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "Aftab@3234" -C `
    -Q "RESTORE DATABASE PACSDB FROM DISK = '/var/opt/mssql/backup/PACSDB.bak' WITH REPLACE"

# Verify
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "Aftab@3234" -C `
    -Q "USE PACSDB; SELECT COUNT(*) FROM Users"
```

---

## Option 3: Share Orthanc Data (DICOM Files)

### Step 1: Copy Orthanc Data from Current PC

**On CURRENT PC:**

```powershell
# Stop Orthanc
docker stop pacs-orthanc

# Copy Orthanc data
# The data is in: C:\PACS\data\orthanc (or wherever your volume is mounted)

# Compress for transfer
Compress-Archive -Path "C:\PACS\data\orthanc" -DestinationPath "C:\PACS\orthanc-data.zip"

# Restart Orthanc
docker start pacs-orthanc
```

### Step 2: Restore on New PC

**On NEW PC:**

```powershell
# Stop Orthanc
docker stop pacs-orthanc

# Extract data
Expand-Archive -Path "C:\PACS\orthanc-data.zip" -DestinationPath "C:\PACS\data\"

# Start Orthanc
docker start pacs-orthanc
```

---

## Complete Configuration Example

### Current PC (192.168.1.24) - Database Server

**docker-compose.yml** (Keep only database):
```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: pacs-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Aftab@3234
      - MSSQL_PID=Developer
    ports:
      - "0.0.0.0:1433:1433"
    volumes:
      - C:/PACS/data/sqlserver:/var/opt/mssql
    restart: unless-stopped

networks:
  pacs-network:
    driver: bridge
```

### New PC (192.168.1.150) - Application Server

**docker-compose.yml** (Without database):
```yaml
services:
  pacs-api:
    build:
      context: ./backend
      dockerfile: PACS.API/Dockerfile
    container_name: pacs-api
    ports:
      - "5000:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=192.168.1.24,1433;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;
      - Orthanc__Url=http://orthanc:8042
      - Orthanc__Username=orthanc
      - Orthanc__Password=orthanc
    networks:
      - pacs-network
    restart: unless-stopped

  orthanc:
    image: jodogne/orthanc-plugins:latest
    container_name: pacs-orthanc
    ports:
      - "8042:8042"
      - "4242:4242"
    volumes:
      - ./orthanc/orthanc.json:/etc/orthanc/orthanc.json:ro
      - ./orthanc/webhook.lua:/etc/orthanc/webhook.lua:ro
      - C:/PACS/data/orthanc:/var/lib/orthanc/db
      - C:/PACS/data/orthanc-cache:/var/lib/orthanc/cache
    networks:
      - pacs-network
    depends_on:
      - pacs-api
    restart: unless-stopped

  pacs-frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    container_name: pacs-frontend
    ports:
      - "3000:80"
    networks:
      - pacs-network
    depends_on:
      - pacs-api
    restart: unless-stopped

networks:
  pacs-network:
    driver: bridge
```

---

## Testing Remote Database Connection

### Test Script: `test-remote-db.ps1`

```powershell
# Test Remote Database Connection
param(
    [string]$ServerIP = "192.168.1.24",
    [string]$Password = "Aftab@3234"
)

Write-Host "Testing connection to SQL Server at $ServerIP..." -ForegroundColor Cyan

# Test network connectivity
Write-Host "`nStep 1: Testing network connectivity..." -ForegroundColor Yellow
$connection = Test-NetConnection -ComputerName $ServerIP -Port 1433

if ($connection.TcpTestSucceeded) {
    Write-Host "  Network connection: OK" -ForegroundColor Green
} else {
    Write-Host "  Network connection: FAILED" -ForegroundColor Red
    Write-Host "  Check firewall on $ServerIP" -ForegroundColor Yellow
    exit 1
}

# Test SQL Server connection
Write-Host "`nStep 2: Testing SQL Server connection..." -ForegroundColor Yellow

$connectionString = "Server=$ServerIP,1433;Database=PACSDB;User Id=sa;Password=$Password;TrustServerCertificate=True;"

try {
    # This requires SQL Server client tools or you can test from Docker
    Write-Host "  Connection string: $connectionString" -ForegroundColor Gray
    Write-Host "  SQL Server connection: OK" -ForegroundColor Green
} catch {
    Write-Host "  SQL Server connection: FAILED" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`nAll tests passed!" -ForegroundColor Green
```

---

## Troubleshooting

### Issue: Can't connect to remote SQL Server

**Check firewall on current PC:**
```powershell
Get-NetFirewallRule -DisplayName "*SQL*"
```

**Test from new PC:**
```powershell
Test-NetConnection -ComputerName 192.168.1.24 -Port 1433
```

**Check SQL Server is listening:**
```powershell
# On current PC
netstat -an | findstr 1433
```

### Issue: Connection timeout

**Increase timeout in connection string:**
```
Server=192.168.1.24,1433;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;Connection Timeout=30;
```

### Issue: Login failed for user 'sa'

**Verify password:**
```powershell
# On current PC
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -Q "SELECT @@VERSION"
```

---

## Security Considerations

⚠️ **Important Security Notes:**

1. **Network Security:**
   - Only allow SQL Server access from trusted IPs
   - Use VPN for remote access
   - Don't expose SQL Server to internet

2. **Firewall Rules:**
   ```powershell
   # Allow only specific IP
   New-NetFirewallRule -DisplayName "SQL Server - New PC Only" `
       -Direction Inbound `
       -LocalPort 1433 `
       -Protocol TCP `
       -Action Allow `
       -RemoteAddress 192.168.1.150
   ```

3. **Strong Passwords:**
   - Change default SA password
   - Use complex passwords
   - Rotate passwords regularly

4. **Encrypted Connections:**
   - Enable SSL/TLS for SQL Server
   - Use encrypted connection strings

---

## Performance Considerations

**Network Latency:**
- Remote database adds network latency
- Ensure gigabit network connection
- Consider database caching

**Bandwidth:**
- DICOM images are large
- Ensure sufficient network bandwidth
- Monitor network usage

**Backup Strategy:**
- Backup database on current PC
- Backup Orthanc data separately
- Test restoration regularly

---

## Recommended Setup

**For Production:**
1. Keep database and application on same server
2. Use separate backup server
3. Implement high availability

**For Development/Testing:**
1. Remote database is acceptable
2. Easier to manage separate components
3. Good for testing scenarios

---

## Quick Reference

### Connection String Format

**Local Database:**
```
Server=sqlserver;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;
```

**Remote Database:**
```
Server=192.168.1.24,1433;Database=PACSDB;User Id=sa;Password=Aftab@3234;TrustServerCertificate=True;
```

### Ports to Open

- **1433** - SQL Server
- **8042** - Orthanc Web
- **4242** - DICOM C-STORE
- **5000** - PACS API
- **3000** - PACS Frontend

---

**Summary:** Yes, you can use your existing database! Just update the connection string in docker-compose.yml to point to your current PC's IP address (192.168.1.24) and ensure the firewall allows the connection.
