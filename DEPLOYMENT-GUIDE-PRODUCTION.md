# Production Deployment Guide - PACS System

## Architecture Overview

```
┌─────────────────┐
│  Vercel/Netlify │  ← Frontend (FREE)
│  (React App)    │
└────────┬────────┘
         │ HTTPS
         ↓
┌─────────────────┐
│   VPS Server    │  ← Backend ($5-10/month)
│  - .NET API     │
│  - SQL Server   │
│  - Orthanc      │
│  - DICOM Files  │
└─────────────────┘
```

## Prerequisites

1. **Domain Name** (optional but recommended)
   - Namecheap: ~$10/year
   - Cloudflare: Free DNS management

2. **VPS Server** (choose one)
   - Hetzner Cloud: €4.51/month (2 vCPU, 4GB RAM)
   - Vultr: $6/month (1 vCPU, 2GB RAM)
   - DigitalOcean: $6/month (1 vCPU, 2GB RAM)

3. **Free Frontend Hosting**
   - Vercel (recommended)
   - Netlify

## Part 1: Deploy Backend to VPS

### Step 1: Setup VPS Server

```bash
# SSH into your VPS
ssh root@your-vps-ip

# Update system
apt update && apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Install Docker Compose
apt install docker-compose -y

# Install Nginx
apt install nginx -y

# Install Certbot for SSL
apt install certbot python3-certbot-nginx -y
```

### Step 2: Upload Project to VPS

```bash
# On your local machine, create a deployment package
# Exclude node_modules and build artifacts
tar -czf pacs-backend.tar.gz \
  backend/ \
  database/ \
  orthanc/ \
  docker-compose.yml \
  --exclude=backend/PACS.API/bin \
  --exclude=backend/PACS.API/obj

# Upload to VPS
scp pacs-backend.tar.gz root@your-vps-ip:/root/

# On VPS, extract
ssh root@your-vps-ip
cd /root
tar -xzf pacs-backend.tar.gz
```

### Step 3: Configure for Production

Create production docker-compose file:

```yaml
# docker-compose.prod.yml
services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: pacs-sqlserver
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=YourStrongPassword123!
      - MSSQL_PID=Developer
    ports:
      - "127.0.0.1:1433:1433"  # Only localhost
    volumes:
      - sqlserver-data:/var/opt/mssql
      - ./database/init.sql:/docker-entrypoint-initdb.d/init.sql:ro
    networks:
      - pacs-network
    restart: unless-stopped

  pacs-api:
    build:
      context: ./backend
      dockerfile: PACS.API/Dockerfile
    container_name: pacs-api
    ports:
      - "127.0.0.1:5000:8080"  # Only localhost
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=Server=sqlserver;Database=PACSDB;User Id=sa;Password=YourStrongPassword123!;TrustServerCertificate=True;
      - Orthanc__Url=http://orthanc:8042
      - Orthanc__Username=orthanc
      - Orthanc__Password=YourOrthancPassword123
      - AppSettings__BaseUrl=https://yourdomain.com
    networks:
      - pacs-network
    depends_on:
      - sqlserver
    restart: unless-stopped

  orthanc:
    image: jodogne/orthanc-plugins:latest
    container_name: pacs-orthanc
    ports:
      - "127.0.0.1:8042:8042"  # Only localhost
      - "4242:4242"  # DICOM port (if needed externally)
    volumes:
      - ./orthanc/orthanc.json:/etc/orthanc/orthanc.json:ro
      - orthanc-data:/var/lib/orthanc/db
      - orthanc-cache:/var/lib/orthanc/cache
    networks:
      - pacs-network
    restart: unless-stopped

volumes:
  sqlserver-data:
  orthanc-data:
  orthanc-cache:

networks:
  pacs-network:
    driver: bridge
```

### Step 4: Configure Nginx Reverse Proxy

```bash
# Create Nginx config
nano /etc/nginx/sites-available/pacs-api
```

```nginx
# /etc/nginx/sites-available/pacs-api
server {
    listen 80;
    server_name api.yourdomain.com;  # or your-vps-ip

    # API endpoints
    location /api {
        proxy_pass http://localhost:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Orthanc OHIF Viewer
    location /ohif {
        proxy_pass http://localhost:8042;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Orthanc API
    location /orthanc {
        proxy_pass http://localhost:8042;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

```bash
# Enable site
ln -s /etc/nginx/sites-available/pacs-api /etc/nginx/sites-enabled/
nginx -t
systemctl restart nginx
```

### Step 5: Get SSL Certificate (if using domain)

```bash
# Get SSL certificate
certbot --nginx -d api.yourdomain.com

# Auto-renewal is configured automatically
```

### Step 6: Start Backend Services

```bash
cd /root
docker-compose -f docker-compose.prod.yml up -d --build

# Check logs
docker-compose -f docker-compose.prod.yml logs -f
```

## Part 2: Deploy Frontend to Vercel

### Step 1: Prepare Frontend for Production

Update frontend environment variables:

```bash
# frontend/.env.production
VITE_API_URL=https://api.yourdomain.com/api
VITE_ORTHANC_URL=https://api.yourdomain.com/orthanc
```

### Step 2: Push to GitHub

```bash
# Initialize git (if not already)
cd frontend
git init
git add .
git commit -m "Initial commit"

# Create GitHub repo and push
git remote add origin https://github.com/yourusername/pacs-frontend.git
git push -u origin main
```

### Step 3: Deploy to Vercel

1. Go to https://vercel.com
2. Sign up with GitHub
3. Click "New Project"
4. Import your frontend repository
5. Configure:
   - Framework Preset: Vite
   - Build Command: `npm run build`
   - Output Directory: `dist`
   - Environment Variables:
     - `VITE_API_URL`: `https://api.yourdomain.com/api`
     - `VITE_ORTHANC_URL`: `https://api.yourdomain.com/orthanc`
6. Click "Deploy"

Your frontend will be live at: `https://your-project.vercel.app`

### Step 4: Configure Custom Domain (Optional)

In Vercel dashboard:
1. Go to Project Settings → Domains
2. Add your domain: `yourdomain.com`
3. Update DNS records as instructed

## Part 3: Configure CORS

Update backend to allow frontend domain:

```csharp
// backend/PACS.API/Program.cs
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowFrontend", policy =>
    {
        policy.WithOrigins(
            "https://your-project.vercel.app",
            "https://yourdomain.com",
            "http://localhost:3000"  // for local development
        )
        .AllowAnyMethod()
        .AllowAnyHeader()
        .AllowCredentials();
    });
});

// Use CORS
app.UseCors("AllowFrontend");
```

Rebuild and restart API:

```bash
docker-compose -f docker-compose.prod.yml up -d --build pacs-api
```

## Cost Breakdown

### Minimum Setup (~$15-20/month)
- VPS (Hetzner): €4.51/month (~$5)
- Domain: ~$10/year (~$1/month)
- Frontend: FREE (Vercel)
- SSL: FREE (Let's Encrypt)
- **Total: ~$6/month**

### Recommended Setup (~$25-30/month)
- VPS (4GB RAM): $12/month
- Domain: ~$10/year (~$1/month)
- Cloudflare Pro (optional): $20/month
- Frontend: FREE (Vercel)
- **Total: ~$13-33/month**

## Security Checklist

- [ ] Change all default passwords
- [ ] Enable firewall (ufw)
- [ ] Configure fail2ban
- [ ] Use strong SQL Server password
- [ ] Enable HTTPS only
- [ ] Restrict database to localhost
- [ ] Regular backups
- [ ] Update Docker images regularly
- [ ] Monitor logs

## Backup Strategy

```bash
# Backup script
#!/bin/bash
# /root/backup.sh

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/root/backups"

# Backup database
docker exec pacs-sqlserver /opt/mssql-tools/bin/sqlcmd \
  -S localhost -U sa -P 'YourStrongPassword123!' \
  -Q "BACKUP DATABASE PACSDB TO DISK='/var/opt/mssql/backup/PACSDB_$DATE.bak'"

# Backup DICOM files
docker run --rm -v orthanc-data:/data -v $BACKUP_DIR:/backup \
  alpine tar czf /backup/orthanc_$DATE.tar.gz /data

# Keep only last 7 days
find $BACKUP_DIR -name "*.bak" -mtime +7 -delete
find $BACKUP_DIR -name "*.tar.gz" -mtime +7 -delete
```

```bash
# Make executable
chmod +x /root/backup.sh

# Add to crontab (daily at 2 AM)
crontab -e
# Add: 0 2 * * * /root/backup.sh
```

## Monitoring

```bash
# Check service status
docker-compose -f docker-compose.prod.yml ps

# View logs
docker-compose -f docker-compose.prod.yml logs -f pacs-api

# Check resource usage
docker stats
```

## Troubleshooting

### Frontend can't connect to API
- Check CORS configuration
- Verify API URL in frontend .env
- Check Nginx logs: `tail -f /var/log/nginx/error.log`

### Database connection failed
- Check SQL Server is running: `docker ps`
- Verify connection string
- Check firewall rules

### OHIF Viewer not loading
- Verify Orthanc is accessible
- Check Nginx proxy configuration
- Test: `curl http://localhost:8042/system`

## Alternative: All-in-One Platforms

If VPS management is too complex, consider:

### Railway.app (~$20/month)
- One-click Docker deployment
- Automatic SSL
- Built-in monitoring
- No server management

### Render.com (~$25/month)
- Docker support
- Managed PostgreSQL
- Auto-scaling
- Free SSL

---

**Need help?** Check logs first, then review configuration files.
