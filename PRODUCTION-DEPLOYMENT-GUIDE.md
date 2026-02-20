# Complete Production Deployment Guide

## 🚀 Production Deployment Options

Choose your deployment strategy based on your infrastructure needs:

### Option 1: Cloud Deployment (Recommended)
### Option 2: On-Premises Server Deployment
### Option 3: Hybrid Cloud Deployment

---

## 🌐 Option 1: Cloud Deployment (AWS/Azure)

### AWS Deployment

#### Step 1: Prepare AWS Infrastructure

```bash
# 1. Create VPC and Security Groups
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-security-group --group-name pacs-sg --description "PACS Security Group"

# 2. Create RDS SQL Server Instance
aws rds create-db-instance \
  --db-instance-identifier pacs-database \
  --db-instance-class db.t3.medium \
  --engine sqlserver-ex \
  --master-username admin \
  --master-user-password YourSecurePassword123! \
  --allocated-storage 100
```

#### Step 2: Deploy Backend API

```bash
# 1. Build and push Docker image to ECR
aws ecr create-repository --repository-name pacs-api
docker build -t pacs-api ./backend
docker tag pacs-api:latest 123456789012.dkr.ecr.us-east-1.amazonaws.com/pacs-api:latest
docker push 123456789012.dkr.ecr.us-east-1.amazonaws.com/pacs-api:latest

# 2. Create ECS Cluster and Service
aws ecs create-cluster --cluster-name pacs-cluster
aws ecs create-service --cluster pacs-cluster --service-name pacs-api-service
```

#### Step 3: Deploy Frontend

```bash
# 1. Build React app
cd frontend
npm run build

# 2. Upload to S3
aws s3 mb s3://your-pacs-frontend-bucket
aws s3 sync dist/ s3://your-pacs-frontend-bucket --delete

# 3. Configure CloudFront
aws cloudfront create-distribution --distribution-config file://cloudfront-config.json
```

#### Step 4: Deploy Orthanc

```bash
# 1. Launch EC2 instance for Orthanc
aws ec2 run-instances \
  --image-id ami-0abcdef1234567890 \
  --count 1 \
  --instance-type t3.medium \
  --key-name your-key-pair \
  --security-group-ids sg-12345678

# 2. Install Docker and run Orthanc
ssh -i your-key.pem ec2-user@your-ec2-ip
sudo yum update -y
sudo yum install docker -y
sudo service docker start
sudo docker run -d -p 8042:8042 -p 4242:4242 \
  -v /opt/orthanc-data:/var/lib/orthanc/db \
  jodogne/orthanc-plugins:latest
```

### Azure Deployment

#### Step 1: Create Azure Resources

```bash
# 1. Create Resource Group
az group create --name pacs-rg --location eastus

# 2. Create Azure SQL Database
az sql server create \
  --name pacs-sql-server \
  --resource-group pacs-rg \
  --location eastus \
  --admin-user pacssqladmin \
  --admin-password YourSecurePassword123!

az sql db create \
  --resource-group pacs-rg \
  --server pacs-sql-server \
  --name PACSDB \
  --service-objective Basic
```

#### Step 2: Deploy API to App Service

```bash
# 1. Create App Service Plan
az appservice plan create \
  --name pacs-plan \
  --resource-group pacs-rg \
  --sku B1 \
  --is-linux

# 2. Create Web App
az webapp create \
  --resource-group pacs-rg \
  --plan pacs-plan \
  --name pacs-api-app \
  --deployment-container-image-name your-registry/pacs-api:latest
```

#### Step 3: Deploy Frontend to Static Web Apps

```bash
# 1. Build frontend
cd frontend
npm run build

# 2. Deploy to Static Web Apps
az staticwebapp create \
  --name pacs-frontend \
  --resource-group pacs-rg \
  --source https://github.com/yourusername/pacs-project \
  --location eastus2 \
  --branch main \
  --app-location "/frontend" \
  --output-location "dist"
```

---

## 🏢 Option 2: On-Premises Server Deployment

### Prerequisites

- Ubuntu 20.04+ or Windows Server 2019+
- 16GB RAM minimum (32GB recommended)
- 500GB SSD storage minimum
- Static IP address
- Domain name (optional but recommended)

### Step 1: Server Setup

```bash
# Ubuntu Server Setup
sudo apt update && sudo apt upgrade -y
sudo apt install docker.io docker-compose nginx certbot -y
sudo systemctl enable docker
sudo usermod -aG docker $USER

# Create project directory
sudo mkdir -p /opt/pacs
sudo chown $USER:$USER /opt/pacs
cd /opt/pacs
```

### Step 2: Clone and Configure

```bash
# Clone your repository
git clone https://github.com/yourusername/pacs-project.git
cd pacs-project

# Create production environment file
cp .env.example .env.production
```

### Step 3: Production Configuration

Create `docker-compose.prod.yml`:

```yaml
version: '3.8'

services:
  sqlserver:
    image: mcr.microsoft.com/mssql/server:2022-latest
    container_name: pacs-sqlserver-prod
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=${SQL_SA_PASSWORD}
      - MSSQL_PID=Standard
    ports:
      - "1433:1433"
    volumes:
      - sqlserver-prod-data:/var/opt/mssql
      - ./backups:/var/backups
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 4G
        reservations:
          memory: 2G

  pacs-api:
    build:
      context: ./backend
      dockerfile: Dockerfile.prod
    container_name: pacs-api-prod
    environment:
      - ASPNETCORE_ENVIRONMENT=Production
      - ConnectionStrings__DefaultConnection=${DATABASE_CONNECTION_STRING}
      - Orthanc__Url=http://orthanc:8042
      - JWT__SecretKey=${JWT_SECRET_KEY}
      - JWT__Issuer=${JWT_ISSUER}
      - JWT__Audience=${JWT_AUDIENCE}
    ports:
      - "5000:8080"
    depends_on:
      - sqlserver
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 2G

  orthanc:
    image: jodogne/orthanc-plugins:latest
    container_name: pacs-orthanc-prod
    ports:
      - "8042:8042"
      - "4242:4242"
    volumes:
      - ./orthanc/orthanc.prod.json:/etc/orthanc/orthanc.json:ro
      - ./orthanc/webhook.lua:/etc/orthanc/webhook.lua:ro
      - orthanc-prod-data:/var/lib/orthanc/db
      - orthanc-prod-cache:/var/lib/orthanc/cache
    restart: unless-stopped
    deploy:
      resources:
        limits:
          memory: 4G

  nginx:
    image: nginx:alpine
    container_name: pacs-nginx-prod
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.prod.conf:/etc/nginx/nginx.conf:ro
      - ./frontend/dist:/usr/share/nginx/html:ro
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - pacs-api
    restart: unless-stopped

volumes:
  sqlserver-prod-data:
  orthanc-prod-data:
  orthanc-prod-cache:

networks:
  default:
    name: pacs-prod-network
```

### Step 4: SSL Certificate Setup

```bash
# Get SSL certificate with Let's Encrypt
sudo certbot certonly --standalone -d your-domain.com
sudo cp /etc/letsencrypt/live/your-domain.com/fullchain.pem ./ssl/
sudo cp /etc/letsencrypt/live/your-domain.com/privkey.pem ./ssl/
sudo chown $USER:$USER ./ssl/*
```

### Step 5: Production Environment Variables

Create `.env.production`:

```bash
# Database
SQL_SA_PASSWORD=YourVerySecurePassword123!
DATABASE_CONNECTION_STRING=Server=sqlserver;Database=PACSDB;User Id=sa;Password=YourVerySecurePassword123!;TrustServerCertificate=True;

# JWT Configuration
JWT_SECRET_KEY=YourVeryLongAndSecureJWTSecretKey123456789!
JWT_ISSUER=https://your-domain.com
JWT_AUDIENCE=https://your-domain.com

# API URLs
VITE_API_URL=https://your-domain.com/api
VITE_ORTHANC_URL=https://your-domain.com/orthanc

# Orthanc
ORTHANC_USERNAME=admin
ORTHANC_PASSWORD=YourSecureOrthancPassword123!
```

### Step 6: Build and Deploy

```bash
# Build frontend for production
cd frontend
npm install
npm run build
cd ..

# Start production services
docker-compose -f docker-compose.prod.yml up -d --build

# Initialize database
docker exec pacs-api-prod dotnet ef database update

# Create default users
docker exec pacs-sqlserver-prod /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "YourVerySecurePassword123!" -C \
  -Q "USE PACSDB; INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive) VALUES ('admin', 'admin@yourcompany.com', 'admin123', 'Admin', 'System', 'Administrator', 1)"
```

### Step 7: Nginx Configuration

Create `nginx/nginx.prod.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    upstream api {
        server pacs-api:8080;
    }

    upstream orthanc {
        server orthanc:8042;
    }

    server {
        listen 80;
        server_name your-domain.com;
        return 301 https://$server_name$request_uri;
    }

    server {
        listen 443 ssl http2;
        server_name your-domain.com;

        ssl_certificate /etc/nginx/ssl/fullchain.pem;
        ssl_certificate_key /etc/nginx/ssl/privkey.pem;

        # Frontend
        location / {
            root /usr/share/nginx/html;
            try_files $uri $uri/ /index.html;
        }

        # API
        location /api/ {
            proxy_pass http://api/api/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Orthanc
        location /orthanc/ {
            proxy_pass http://orthanc/;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
```

---

## 🔧 Post-Deployment Configuration

### Step 1: Security Hardening

```bash
# 1. Change default passwords
# 2. Configure firewall
sudo ufw enable
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 4242/tcp  # DICOM port

# 3. Set up fail2ban
sudo apt install fail2ban -y
sudo systemctl enable fail2ban
```

### Step 2: Monitoring Setup

```bash
# Install monitoring tools
docker run -d \
  --name=grafana \
  -p 3001:3000 \
  -v grafana-storage:/var/lib/grafana \
  grafana/grafana

docker run -d \
  --name=prometheus \
  -p 9090:9090 \
  -v ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml \
  prom/prometheus
```

### Step 3: Backup Configuration

Create backup script `scripts/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/opt/backups"
DATE=$(date +%Y%m%d_%H%M%S)

# Database backup
docker exec pacs-sqlserver-prod /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$SQL_SA_PASSWORD" -C \
  -Q "BACKUP DATABASE PACSDB TO DISK = '/var/backups/PACSDB_$DATE.bak'"

# Orthanc data backup
docker exec pacs-orthanc-prod tar -czf /var/lib/orthanc/backup_$DATE.tar.gz /var/lib/orthanc/db

# Upload to cloud storage (optional)
aws s3 cp $BACKUP_DIR/ s3://your-backup-bucket/ --recursive
```

### Step 4: SSL Certificate Auto-Renewal

```bash
# Add to crontab
echo "0 12 * * * /usr/bin/certbot renew --quiet" | sudo crontab -
```

---

## 📊 Performance Optimization

### Database Optimization

```sql
-- Create indexes for better performance
CREATE INDEX IX_Studies_StudyDate ON Studies(StudyDate);
CREATE INDEX IX_Studies_Status ON Studies(Status);
CREATE INDEX IX_Studies_PatientId ON Studies(PatientId);
CREATE INDEX IX_Patients_MRN ON Patients(MRN);
```

### Caching Configuration

Add Redis for session management:

```yaml
redis:
  image: redis:alpine
  container_name: pacs-redis-prod
  ports:
    - "6379:6379"
  volumes:
    - redis-data:/data
  restart: unless-stopped
```

---

## 🔍 Monitoring and Maintenance

### Health Check Endpoints

Add to your API:

```csharp
app.MapHealthChecks("/health", new HealthCheckOptions
{
    ResponseWriter = UIResponseWriter.WriteHealthCheckUIResponse
});
```

### Log Management

Configure structured logging:

```json
{
  "Serilog": {
    "Using": ["Serilog.Sinks.File", "Serilog.Sinks.Console"],
    "MinimumLevel": "Information",
    "WriteTo": [
      {
        "Name": "File",
        "Args": {
          "path": "/app/logs/pacs-.log",
          "rollingInterval": "Day",
          "retainedFileCountLimit": 30
        }
      }
    ]
  }
}
```

### Maintenance Tasks

Create maintenance script:

```bash
#!/bin/bash
# Daily maintenance tasks

# 1. Clean old logs
find /opt/pacs/logs -name "*.log" -mtime +30 -delete

# 2. Database maintenance
docker exec pacs-sqlserver-prod /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$SQL_SA_PASSWORD" -C \
  -Q "USE PACSDB; UPDATE STATISTICS"

# 3. Docker cleanup
docker system prune -f

# 4. Check disk space
df -h | mail -s "PACS Disk Usage Report" admin@yourcompany.com
```

---

## 🚨 Troubleshooting

### Common Issues

1. **Database Connection Issues**
   ```bash
   # Check SQL Server logs
   docker logs pacs-sqlserver-prod
   
   # Test connection
   docker exec pacs-api-prod dotnet ef database update --dry-run
   ```

2. **Orthanc Not Receiving Studies**
   ```bash
   # Check Orthanc logs
   docker logs pacs-orthanc-prod
   
   # Test DICOM connectivity
   telnet your-server-ip 4242
   ```

3. **SSL Certificate Issues**
   ```bash
   # Check certificate validity
   openssl x509 -in ./ssl/fullchain.pem -text -noout
   
   # Renew certificate
   sudo certbot renew --force-renewal
   ```

### Performance Issues

```bash
# Monitor resource usage
docker stats

# Check database performance
docker exec pacs-sqlserver-prod /opt/mssql-tools18/bin/sqlcmd \
  -S localhost -U sa -P "$SQL_SA_PASSWORD" -C \
  -Q "SELECT * FROM sys.dm_exec_query_stats ORDER BY total_elapsed_time DESC"
```

---

## 📋 Production Checklist

### Pre-Deployment
- [ ] Change all default passwords
- [ ] Configure SSL certificates
- [ ] Set up monitoring
- [ ] Configure backups
- [ ] Test disaster recovery
- [ ] Security audit
- [ ] Performance testing
- [ ] Documentation review

### Post-Deployment
- [ ] Verify all services are running
- [ ] Test user authentication
- [ ] Upload test DICOM files
- [ ] Verify webhook functionality
- [ ] Test report generation
- [ ] Monitor system resources
- [ ] Set up alerting
- [ ] Train end users

### Ongoing Maintenance
- [ ] Daily backup verification
- [ ] Weekly security updates
- [ ] Monthly performance review
- [ ] Quarterly disaster recovery test
- [ ] Annual security audit

---

## 📞 Support and Maintenance

### Monitoring Dashboards
- **System Health**: https://your-domain.com:3001 (Grafana)
- **API Metrics**: https://your-domain.com:9090 (Prometheus)
- **Application Logs**: `/opt/pacs/logs/`

### Emergency Contacts
- System Administrator: admin@yourcompany.com
- Database Administrator: dba@yourcompany.com
- Network Administrator: network@yourcompany.com

### Escalation Procedures
1. **Level 1**: System alerts and automated recovery
2. **Level 2**: On-call administrator notification
3. **Level 3**: Emergency response team activation

---

Your PACS system is now ready for production deployment! 🎉

Choose the deployment option that best fits your infrastructure needs and follow the step-by-step instructions above.