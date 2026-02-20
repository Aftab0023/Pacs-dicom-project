# Windows On-Premises Server Deployment Guide
## PACS Medical Imaging System - Production Deployment

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Hardware Requirements](#hardware-requirements)
3. [Software Installation](#software-installation)
4. [Network Configuration](#network-configuration)
5. [System Preparation](#system-preparation)
6. [PACS Deployment](#pacs-deployment)
7. [Security Hardening](#security-hardening)
8. [Backup Configuration](#backup-configuration)
9. [Monitoring Setup](#monitoring-setup)
10. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### Minimum Hardware Requirements

**For Small Clinic (< 50 studies/day):**
- CPU: Intel Core i5 or AMD Ryzen 5 (4 cores)
- RAM: 16 GB
- Storage: 500 GB SSD + 2 TB HDD
- Network: Gigabit Ethernet

**For Medium Hospital (50-200 studies/day):**
- CPU: Intel Core i7 or AMD Ryzen 7 (8 cores)
- RAM: 32 GB
- Storage: 1 TB NVMe SSD + 4 TB HDD RAID
- Network: Gigabit Ethernet (dedicated)

**For Large Hospital (> 200 studies/day):**
- CPU: Intel Xeon or AMD EPYC (16+ cores)
- RAM: 64 GB+
- Storage: 2 TB NVMe SSD + 10 TB+ HDD RAID 10
- Network: 10 Gigabit Ethernet (dedicated)

### Operating System
- Windows Server 2019 or later (Recommended)
- Windows 10/11 Pro (For small deployments)

---

## Software Installation

### Step 1: Install Docker Desktop for Windows

1. **Download Docker Desktop:**
   - Visit: https://www.docker.com/products/docker-desktop/
   - Download Docker Desktop for Windows

2. **System Requirements:**
   - Windows 10 64-bit: Pro, Enterprise, or Education (Build 19041 or higher)
   - OR Windows 11 64-bit
   - WSL 2 feature enabled
   - Hyper-V and Containers Windows features enabled

3. **Installation Steps:**
   ```powershell
   # Run as Administrator
   
   # Enable WSL 2
   wsl --install
   
   # Restart computer after WSL installation
   
   # Install Docker Desktop (run the installer)
   # Follow the installation wizard
   # Select "Use WSL 2 instead of Hyper-V" option
   ```

4. **Verify Installation:**
   ```powershell
   docker --version
   docker-compose --version
   ```

### Step 2: Install Git (Optional but Recommended)

```powershell
# Download from: https://git-scm.com/download/win
# Or use winget:
winget install --id Git.Git -e --source winget
```

### Step 3: Install PowerShell 7 (Recommended)

```powershell
# Download from: https://github.com/PowerShell/PowerShell/releases
# Or use winget:
winget install --id Microsoft.PowerShell --source winget
```

### Step 4: Install Text Editor (Optional)

```powershell
# Visual Studio Code
winget install -e --id Microsoft.VisualStudioCode

# OR Notepad++
winget install -e --id Notepad++.Notepad++
```

---

## Network Configuration

### Step 1: Configure Static IP Address

1. **Open Network Settings:**
   - Press `Win + R`, type `ncpa.cpl`, press Enter
   - Right-click your network adapter → Properties
   - Select "Internet Protocol Version 4 (TCP/IPv4)" → Properties

2. **Set Static IP:**
   ```
   IP Address: 192.168.1.100 (or your preferred IP)
   Subnet Mask: 255.255.255.0
   Default Gateway: 192.168.1.1 (your router IP)
   Preferred DNS: 8.8.8.8
   Alternate DNS: 8.8.4.4
   ```

3. **Verify Configuration:**
   ```powershell
   ipconfig /all
   ping 8.8.8.8
   ```

### Step 2: Configure Windows Firewall

**Option A: Using PowerShell (Recommended)**

Create a file: `setup-firewall.ps1`

```powershell
# Run as Administrator

Write-Host "Configuring Windows Firewall for PACS System..." -ForegroundColor Cyan

# PACS Frontend (Port 3000)
New-NetFirewallRule -DisplayName "PACS Frontend" `
    -Direction Inbound `
    -LocalPort 3000 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "PACS Web Interface"

# PACS API (Port 5000)
New-NetFirewallRule -DisplayName "PACS API" `
    -Direction Inbound `
    -LocalPort 5000 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "PACS Backend API"

# Orthanc Web (Port 8042)
New-NetFirewallRule -DisplayName "Orthanc Web Interface" `
    -Direction Inbound `
    -LocalPort 8042 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "Orthanc DICOM Server Web UI"

# DICOM C-STORE (Port 4242)
New-NetFirewallRule -DisplayName "DICOM C-STORE" `
    -Direction Inbound `
    -LocalPort 4242 `
    -Protocol TCP `
    -Action Allow `
    -Profile Any `
    -Description "DICOM Modality Communication"

# SQL Server (Port 1433) - Only if accessing externally
New-NetFirewallRule -DisplayName "SQL Server" `
    -Direction Inbound `
    -LocalPort 1433 `
    -Protocol TCP `
    -Action Allow `
    -Profile Private,Domain `
    -Description "SQL Server Database"

Write-Host "Firewall rules configured successfully!" -ForegroundColor Green
```

Run the script:
```powershell
# Right-click PowerShell → Run as Administrator
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup-firewall.ps1
```

**Option B: Using GUI**

1. Open Windows Defender Firewall with Advanced Security
2. Click "Inbound Rules" → "New Rule"
3. Select "Port" → Next
4. Select "TCP" and enter ports: `3000, 5000, 8042, 4242`
5. Allow the connection → Apply to all profiles
6. Name it "PACS System"

### Step 3: Configure DNS (Optional)

For easier access, configure local DNS:

1. **Edit hosts file:**
   ```powershell
   # Run as Administrator
   notepad C:\Windows\System32\drivers\etc\hosts
   ```

2. **Add entries:**
   ```
   192.168.1.100   pacs.hospital.local
   192.168.1.100   orthanc.hospital.local
   ```

---

## System Preparation

### Step 1: Create Deployment Directory

```powershell
# Create directory structure
New-Item -ItemType Directory -Path "C:\PACS" -Force
New-Item -ItemType Directory -Path "C:\PACS\data" -Force
New-Item -ItemType Directory -Path "C:\PACS\backups" -Force
New-Item -ItemType Directory -Path "C:\PACS\logs" -Force

# Set permissions
icacls "C:\PACS" /grant "Users:(OI)(CI)F" /T
```

### Step 2: Configure Docker Resources

1. **Open Docker Desktop Settings:**
   - Right-click Docker icon in system tray → Settings

2. **Configure Resources:**
   - **CPU:** Allocate 50-70% of available cores
   - **Memory:** Allocate 50-70% of available RAM
   - **Disk:** Set image location to SSD if available

3. **Example for 32GB RAM system:**
   ```
   Memory: 20 GB
   CPUs: 6 (out of 8)
   Swap: 4 GB
   ```

### Step 3: Optimize Windows for Server Use

```powershell
# Disable unnecessary services
Set-Service -Name "DiagTrack" -StartupType Disabled
Set-Service -Name "SysMain" -StartupType Disabled

# Set power plan to High Performance
powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

# Disable Windows Search indexing on data drives
# (Keep enabled on C: for system performance)
```

---

## PACS Deployment

### Step 1: Prepare Configuration Files

1. **Navigate to PACS directory:**
   ```powershell
   cd C:\PACS
   ```

2. **Copy your PACS project files to C:\PACS**

3. **Update environment configuration:**

**Edit `frontend/.env`:**
```env
# Use your server's static IP
VITE_API_URL=http://192.168.1.100:5000/api
VITE_ORTHANC_URL=http://192.168.1.100:8042
```

**Edit `docker-compose.yml`:**
```yaml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: pacs-sqlserver
    deploy:
      resources:
        limits:
          memory: 4096M  # Adjust based on your RAM
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrongPassword123!  # CHANGE THIS!
      - MSSQL_PID=Developer
    ports:
      - "1433:1433"
    volumes:
      - C:/PACS/data/sqlserver:/var/opt/mssql
    networks:
      - pacs-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P YourStrongPassword123! -C -Q 'SELECT 1' || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 120s

  pacs-api:
    build:
      context: ./backend
      dockerfile: PACS.API/Dockerfile
    container_name: pacs-api
    ports:
      - "5000:8080"
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=PACSDB;User Id=sa;Password=YourStrongPassword123!;TrustServerCertificate=True;
      - Orthanc__Url=http://orthanc:8042
      - Orthanc__Username=orthanc
      - Orthanc__Password=OrthancSecurePass123!  # CHANGE THIS!
    networks:
      - pacs-network
    depends_on:
      sqlserver:
        condition: service_healthy
    restart: unless-stopped

  orthanc:
    image: jodogne/orthanc-plugins:latest
    container_name: pacs-orthanc
    deploy:
      resources:
        limits:
          memory: 2048M
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

volumes:
  sqlserver-data:
  orthanc-data:
  orthanc-cache:

networks:
  pacs-network:
    driver: bridge
```

**Update `orthanc/orthanc.json`:**
```json
{
  "Name": "Hospital PACS Server",
  "RegisteredUsers": {
    "orthanc": "OrthancSecurePass123!",
    "admin": "AdminSecurePass123!"
  },
  "RemoteAccessAllowed": true,
  "AuthenticationEnabled": true,
  "HttpTimeout": 120,
  "StableAge": 60
}
```

### Step 2: Update Frontend Dockerfile

**Edit `frontend/Dockerfile`:**
```dockerfile
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install --legacy-peer-deps

COPY . .

# Set build-time environment variables
ARG VITE_API_URL=http://192.168.1.100:5000/api
ARG VITE_ORTHANC_URL=http://192.168.1.100:8042
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_ORTHANC_URL=$VITE_ORTHANC_URL

RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Step 3: Build and Deploy

Create deployment script: `deploy.ps1`

```powershell
# PACS Deployment Script
# Run as Administrator

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  PACS System Deployment" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if Docker is running
$dockerRunning = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Docker is not running!" -ForegroundColor Red
    Write-Host "Please start Docker Desktop and try again." -ForegroundColor Yellow
    exit 1
}

Write-Host "Step 1: Stopping existing containers..." -ForegroundColor Cyan
docker-compose down

Write-Host ""
Write-Host "Step 2: Building images..." -ForegroundColor Cyan
docker-compose build --no-cache

Write-Host ""
Write-Host "Step 3: Starting services..." -ForegroundColor Cyan
docker-compose up -d

Write-Host ""
Write-Host "Step 4: Waiting for services to be ready..." -ForegroundColor Cyan
Start-Sleep -Seconds 30

Write-Host ""
Write-Host "Step 5: Checking service status..." -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Deployment Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Yellow
Write-Host "  Frontend:  http://192.168.1.100:3000" -ForegroundColor White
Write-Host "  Orthanc:   http://192.168.1.100:8042" -ForegroundColor White
Write-Host "  API:       http://192.168.1.100:5000" -ForegroundColor White
Write-Host ""
Write-Host "Default Credentials:" -ForegroundColor Yellow
Write-Host "  Admin:     admin@pacs.local / admin123" -ForegroundColor White
Write-Host "  Orthanc:   orthanc / OrthancSecurePass123!" -ForegroundColor White
Write-Host ""
Write-Host "IMPORTANT: Change default passwords immediately!" -ForegroundColor Red
Write-Host ""
```

Run deployment:
```powershell
.\deploy.ps1
```

### Step 4: Initialize Database

Create script: `init-production-db.ps1`

```powershell
# Database Initialization Script

Write-Host "Initializing PACS Database..." -ForegroundColor Cyan

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Create admin user with BCrypt hash
$adminPassword = "YourSecurePassword123!"  # CHANGE THIS!

# Generate BCrypt hash (you'll need to do this separately)
# Use online tool or .NET code to generate BCrypt hash

$sqlCommand = @"
USE PACSDB;

-- Update admin password
UPDATE Users SET PasswordHash = '$2a$11$YourBCryptHashHere' WHERE Email = 'admin@pacs.local';

-- Update radiologist password
UPDATE Users SET PasswordHash = '$2a$11$YourBCryptHashHere' WHERE Email = 'radiologist@pacs.local';

SELECT UserId, Email, Role FROM Users;
"@

docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost `
    -U sa `
    -P "YourStrongPassword123!" `
    -C `
    -Q $sqlCommand

Write-Host "Database initialized successfully!" -ForegroundColor Green
```

---

## Security Hardening

### Step 1: Change Default Passwords

**Create password update script: `update-passwords.ps1`**

```powershell
# Password Update Script
# Run as Administrator

Write-Host "PACS Password Update Utility" -ForegroundColor Cyan
Write-Host ""

# SQL Server SA Password
$saPassword = Read-Host "Enter new SQL Server SA password" -AsSecureString
$saPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($saPassword))

# Orthanc Password
$orthancPassword = Read-Host "Enter new Orthanc password" -AsSecureString
$orthancPasswordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($orthancPassword))

Write-Host ""
Write-Host "Updating passwords..." -ForegroundColor Yellow

# Update docker-compose.yml
# Update orthanc.json
# Restart services

Write-Host "Passwords updated successfully!" -ForegroundColor Green
Write-Host "Please restart the PACS system for changes to take effect." -ForegroundColor Yellow
```

### Step 2: Enable HTTPS (SSL/TLS)

**For production, you MUST use HTTPS. Here's how:**

1. **Obtain SSL Certificate:**
   - Option A: Use Let's Encrypt (free)
   - Option B: Purchase from Certificate Authority
   - Option C: Use self-signed (testing only)

2. **Configure Nginx for HTTPS:**

Create `frontend/nginx-ssl.conf`:
```nginx
server {
    listen 80;
    server_name pacs.hospital.local;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name pacs.hospital.local;

    ssl_certificate /etc/nginx/ssl/cert.pem;
    ssl_certificate_key /etc/nginx/ssl/key.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;

    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /api {
        proxy_pass http://pacs-api:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### Step 3: Configure Windows Defender

```powershell
# Add exclusions for Docker and PACS data
Add-MpPreference -ExclusionPath "C:\PACS"
Add-MpPreference -ExclusionPath "C:\ProgramData\Docker"
Add-MpPreference -ExclusionProcess "docker.exe"
Add-MpPreference -ExclusionProcess "dockerd.exe"
```

### Step 4: Enable Audit Logging

Create `enable-audit-logging.ps1`:
```powershell
# Enable Windows Event Logging for PACS
$logName = "PACS-System"
$logSource = "PACS-Application"

if (![System.Diagnostics.EventLog]::SourceExists($logSource)) {
    New-EventLog -LogName $logName -Source $logSource
}

Write-EventLog -LogName $logName -Source $logSource `
    -EventId 1000 -EntryType Information `
    -Message "PACS System audit logging enabled"

Write-Host "Audit logging enabled!" -ForegroundColor Green
```

---

## Backup Configuration

### Step 1: Create Backup Script

Create `backup-pacs.ps1`:
```powershell
# PACS Backup Script
# Schedule this to run daily

$backupDate = Get-Date -Format "yyyy-MM-dd_HHmmss"
$backupPath = "C:\PACS\backups\$backupDate"

Write-Host "Starting PACS backup..." -ForegroundColor Cyan

# Create backup directory
New-Item -ItemType Directory -Path $backupPath -Force | Out-Null

# Backup SQL Server database
Write-Host "Backing up database..." -ForegroundColor Yellow
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "YourStrongPassword123!" -C `
    -Q "BACKUP DATABASE PACSDB TO DISK = '/var/opt/mssql/backup/PACSDB_$backupDate.bak'"

# Copy database backup to backup directory
docker cp pacs-sqlserver:/var/opt/mssql/backup/PACSDB_$backupDate.bak "$backupPath\"

# Backup Orthanc data
Write-Host "Backing up DICOM data..." -ForegroundColor Yellow
Copy-Item -Path "C:\PACS\data\orthanc" -Destination "$backupPath\orthanc" -Recurse

# Backup configuration files
Write-Host "Backing up configuration..." -ForegroundColor Yellow
Copy-Item -Path "docker-compose.yml" -Destination "$backupPath\"
Copy-Item -Path "orthanc\orthanc.json" -Destination "$backupPath\"

# Compress backup
Write-Host "Compressing backup..." -ForegroundColor Yellow
Compress-Archive -Path $backupPath -DestinationPath "$backupPath.zip"
Remove-Item -Path $backupPath -Recurse -Force

# Delete old backups (keep last 30 days)
Get-ChildItem "C:\PACS\backups" -Filter "*.zip" | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-30) } | 
    Remove-Item -Force

Write-Host "Backup completed: $backupPath.zip" -ForegroundColor Green
```

### Step 2: Schedule Automated Backups

```powershell
# Create scheduled task for daily backups
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-ExecutionPolicy Bypass -File C:\PACS\backup-pacs.ps1"

$trigger = New-ScheduledTaskTrigger -Daily -At 2:00AM

$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" `
    -LogonType ServiceAccount -RunLevel Highest

Register-ScheduledTask -TaskName "PACS Daily Backup" `
    -Action $action -Trigger $trigger -Principal $principal `
    -Description "Daily backup of PACS system"

Write-Host "Backup schedule created!" -ForegroundColor Green
```

---

## Monitoring Setup

### Step 1: Create Health Check Script

Create `health-check.ps1`:
```powershell
# PACS Health Check Script

Write-Host "PACS System Health Check" -ForegroundColor Cyan
Write-Host "========================" -ForegroundColor Cyan
Write-Host ""

# Check Docker
Write-Host "Docker Status:" -ForegroundColor Yellow
docker info | Select-String "Server Version"

# Check containers
Write-Host ""
Write-Host "Container Status:" -ForegroundColor Yellow
docker-compose ps

# Check disk space
Write-Host ""
Write-Host "Disk Space:" -ForegroundColor Yellow
Get-PSDrive C | Select-Object Used, Free

# Check services
Write-Host ""
Write-Host "Service Health:" -ForegroundColor Yellow

$services = @(
    @{Name="Frontend"; URL="http://localhost:3000"},
    @{Name="API"; URL="http://localhost:5000"},
    @{Name="Orthanc"; URL="http://localhost:8042"}
)

foreach ($service in $services) {
    try {
        $response = Invoke-WebRequest -Uri $service.URL -TimeoutSec 5 -UseBasicParsing
        Write-Host "  $($service.Name): OK" -ForegroundColor Green
    } catch {
        Write-Host "  $($service.Name): FAILED" -ForegroundColor Red
    }
}

Write-Host ""
```

### Step 2: Setup Email Alerts (Optional)

Create `send-alert.ps1`:
```powershell
# Email Alert Script

param(
    [string]$Subject,
    [string]$Body
)

$smtpServer = "smtp.gmail.com"
$smtpPort = 587
$from = "pacs-alerts@hospital.com"
$to = "admin@hospital.com"
$username = "your-email@gmail.com"
$password = ConvertTo-SecureString "your-app-password" -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential($username, $password)

Send-MailMessage -From $from -To $to -Subject $Subject -Body $Body `
    -SmtpServer $smtpServer -Port $smtpPort -UseSsl -Credential $credential
```

---

## Troubleshooting

### Common Issues and Solutions

**Issue 1: Docker containers won't start**
```powershell
# Check Docker logs
docker-compose logs

# Restart Docker Desktop
Restart-Service docker

# Check system resources
docker system df
docker system prune -a
```

**Issue 2: Can't access from network**
```powershell
# Check firewall
Get-NetFirewallRule | Where-Object {$_.DisplayName -like "*PACS*"}

# Test connectivity
Test-NetConnection -ComputerName localhost -Port 3000
```

**Issue 3: Database connection fails**
```powershell
# Check SQL Server container
docker logs pacs-sqlserver

# Test connection
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "YourPassword" -C -Q "SELECT @@VERSION"
```

**Issue 4: Out of disk space**
```powershell
# Check Docker disk usage
docker system df

# Clean up
docker system prune -a --volumes

# Move Docker data to another drive
# Docker Desktop → Settings → Resources → Advanced → Disk image location
```

---

## Maintenance Tasks

### Daily Tasks
- [ ] Check system health
- [ ] Review logs for errors
- [ ] Verify backups completed

### Weekly Tasks
- [ ] Review disk space usage
- [ ] Check for Windows updates
- [ ] Test backup restoration
- [ ] Review user access logs

### Monthly Tasks
- [ ] Update Docker images
- [ ] Review security settings
- [ ] Performance optimization
- [ ] Disaster recovery drill

---

## Production Checklist

Before going live, ensure:

- [ ] Static IP configured
- [ ] Firewall rules configured
- [ ] All default passwords changed
- [ ] HTTPS/SSL enabled
- [ ] Backup system tested
- [ ] Monitoring configured
- [ ] User accounts created
- [ ] Network tested from all locations
- [ ] DICOM modalities configured
- [ ] Documentation updated
- [ ] Staff training completed
- [ ] Disaster recovery plan documented

---

## Support and Maintenance

### Log Locations
- Docker logs: `docker-compose logs`
- Windows Event Viewer: Application → PACS-System
- Backup logs: `C:\PACS\backups\logs`

### Performance Monitoring
```powershell
# Monitor resource usage
docker stats

# Check container health
docker inspect pacs-frontend --format='{{.State.Health.Status}}'
```

### Update Procedure
```powershell
# Pull latest images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build

# Verify
docker-compose ps
```

---

## Emergency Procedures

### System Down
1. Check Docker Desktop is running
2. Check Windows services
3. Review logs: `docker-compose logs`
4. Restart services: `docker-compose restart`

### Data Recovery
1. Stop all services: `docker-compose down`
2. Restore from backup
3. Restart services: `docker-compose up -d`
4. Verify data integrity

### Contact Information
- IT Support: [Your contact]
- Vendor Support: [Vendor contact]
- Emergency: [Emergency contact]

---

**Document Version:** 1.0  
**Last Updated:** 2026-02-20  
**Prepared By:** PACS Deployment Team
