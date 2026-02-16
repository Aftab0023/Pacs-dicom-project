# PACS Deployment Guide

## Quick Start with Docker

### 1. Prerequisites
- Docker Desktop installed
- Docker Compose installed
- At least 8GB RAM available
- 20GB disk space

### 2. Start All Services

```bash
docker-compose up -d
```

This will start:
- SQL Server (port 1433)
- Orthanc DICOM Server (ports 8042, 4242)
- ASP.NET Core API (port 5000)
- React Frontend (port 3000)

### 3. Access Points

- **Frontend**: http://localhost:3000
- **API**: http://localhost:5000
- **API Swagger**: http://localhost:5000/swagger
- **Orthanc Web UI**: http://localhost:8042 (admin/admin)

### 4. Default Credentials

**PACS System:**
- Admin: admin@pacs.local / Admin123!
- Radiologist: radiologist@pacs.local / Radio123!

**Orthanc:**
- Username: orthanc
- Password: orthanc

### 5. Stop Services

```bash
docker-compose down
```

### 6. Reset Everything

```bash
docker-compose down -v
docker-compose up -d --build
```

## Manual Deployment

### Backend (ASP.NET Core)

```bash
cd backend/PACS.API
dotnet publish -c Release -o ./publish
dotnet ./publish/PACS.API.dll
```

### Frontend (React)

```bash
cd frontend
npm install
npm run build
# Serve the dist folder with nginx or any static server
```

### Database Setup

1. Install SQL Server
2. Update connection string in appsettings.json
3. Run migrations:

```bash
cd backend
dotnet ef database update --project PACS.Infrastructure --startup-project PACS.API
```

### Orthanc Setup

1. Install Orthanc with plugins
2. Copy orthanc/orthanc.json to Orthanc config directory
3. Copy orthanc/webhook.py to Orthanc Python scripts directory
4. Update webhook URL in webhook.py
5. Restart Orthanc

## Production Considerations

### Security

1. **Change Default Passwords**
   - Update SQL Server SA password
   - Update Orthanc credentials
   - Update JWT secret key
   - Change default user passwords

2. **Enable HTTPS**
   - Configure SSL certificates
   - Update API URLs
   - Enable HTTPS in Orthanc

3. **Network Security**
   - Use firewall rules
   - Restrict database access
   - Enable VPN for remote access

### Performance

1. **Database Optimization**
   - Regular index maintenance
   - Query optimization
   - Connection pooling

2. **Storage**
   - Configure tiered storage
   - Implement archival strategy
   - Monitor disk usage

3. **Caching**
   - Enable Redis for session management
   - Configure CDN for frontend
   - Implement API response caching

### Monitoring

1. **Logging**
   - Configure structured logging
   - Set up log aggregation (ELK, Splunk)
   - Monitor error rates

2. **Health Checks**
   - API health endpoints
   - Database connectivity
   - Orthanc availability

3. **Metrics**
   - Study ingestion rate
   - Report turnaround time
   - System resource usage

### Backup

1. **Database Backup**
   - Daily full backups
   - Transaction log backups
   - Test restore procedures

2. **DICOM Storage Backup**
   - Replicate Orthanc storage
   - Offsite backup
   - Verify data integrity

3. **Configuration Backup**
   - Version control for configs
   - Document changes
   - Maintain rollback plan

## Cloud Deployment

### Azure

1. **Azure SQL Database**
   - Create managed SQL instance
   - Update connection string
   - Configure firewall rules

2. **Azure App Service**
   - Deploy API as App Service
   - Configure environment variables
   - Enable auto-scaling

3. **Azure Container Instances**
   - Deploy Orthanc container
   - Configure persistent storage
   - Set up networking

4. **Azure Static Web Apps**
   - Deploy React frontend
   - Configure custom domain
   - Enable CDN

### AWS

1. **RDS for SQL Server**
   - Create RDS instance
   - Configure security groups
   - Set up backups

2. **ECS/Fargate**
   - Deploy API containers
   - Configure load balancer
   - Set up auto-scaling

3. **EC2 for Orthanc**
   - Launch EC2 instance
   - Attach EBS volumes
   - Configure security groups

4. **S3 + CloudFront**
   - Host frontend in S3
   - Configure CloudFront
   - Set up custom domain

## Scaling Strategy

### Horizontal Scaling

1. **API Layer**
   - Deploy multiple API instances
   - Use load balancer
   - Implement sticky sessions

2. **Database**
   - Read replicas for queries
   - Sharding for large datasets
   - Connection pooling

3. **Storage**
   - Distributed file system
   - Object storage (S3, Azure Blob)
   - CDN for image delivery

### Vertical Scaling

1. **Increase Resources**
   - More CPU cores
   - Additional RAM
   - Faster storage (SSD)

2. **Optimize Code**
   - Query optimization
   - Caching strategies
   - Async processing

## Compliance

### HIPAA Compliance

1. **Access Controls**
   - Role-based access
   - Audit logging
   - Session management

2. **Data Encryption**
   - Encryption at rest
   - Encryption in transit
   - Key management

3. **Audit Trail**
   - Log all access
   - Track modifications
   - Regular audits

### DICOM Compliance

1. **DICOM Standards**
   - Proper tag handling
   - Transfer syntax support
   - SOP class implementation

2. **Modality Integration**
   - C-STORE support
   - Worklist (MWL) support
   - Query/Retrieve

## Troubleshooting

### Common Issues

1. **Database Connection Failed**
   - Check connection string
   - Verify SQL Server is running
   - Check firewall rules

2. **Orthanc Not Receiving Studies**
   - Verify DICOM port (4242) is open
   - Check modality AE title configuration
   - Review Orthanc logs

3. **Frontend Can't Connect to API**
   - Verify API URL in .env
   - Check CORS configuration
   - Verify API is running

4. **Images Not Displaying**
   - Check DICOMweb configuration
   - Verify Orthanc plugins are loaded
   - Check browser console for errors

### Logs Location

- **API Logs**: Console output or configured log file
- **Orthanc Logs**: /var/log/orthanc/ or console
- **SQL Server Logs**: SQL Server error log
- **Frontend Logs**: Browser console

## Support

For issues and questions:
1. Check logs for error messages
2. Review configuration files
3. Verify network connectivity
4. Check system resources
