# PACS Quick Start Guide

Get your PACS system running in 5 minutes!

## Prerequisites

- Docker Desktop installed and running
- At least 8GB RAM available
- 20GB free disk space
- Internet connection for pulling images

## Step 1: Clone or Download

If you have this code, you're ready. Otherwise:

```bash
git clone <repository-url>
cd pacs-system
```

## Step 2: Start the System

```bash
docker-compose up -d
```

This command will:
- Pull required Docker images (first time only)
- Start SQL Server
- Start Orthanc DICOM server
- Build and start the API
- Build and start the frontend

Wait 2-3 minutes for all services to initialize.

## Step 3: Verify Services

Check all containers are running:

```bash
docker-compose ps
```

You should see 4 services running:
- pacs-sqlserver
- pacs-orthanc
- pacs-api
- pacs-frontend

## Step 4: Access the System

Open your browser and navigate to:

**Frontend:** http://localhost:3000

**Login with:**
- Email: `admin@pacs.local`
- Password: `Admin123!`

Or use the radiologist account:
- Email: `radiologist@pacs.local`
- Password: `Radio123!`

## Step 5: Send a Test Study

### Option A: Use Orthanc Web Interface

1. Open http://localhost:8042
2. Login with username: `orthanc`, password: `orthanc`
3. Click "Upload" button
4. Select DICOM files from your computer
5. Wait for upload to complete

### Option B: Use DICOM Tools

If you have dcm4che or similar tools:

```bash
storescu -c ORTHANC@localhost:4242 /path/to/dicom/files
```

### Option C: Download Sample DICOM

Get free sample DICOM files from:
- https://www.dicomlibrary.com/
- https://barre.dev/medical/samples/

## Step 6: View the Study

1. Go back to http://localhost:3000
2. Navigate to "Worklist"
3. You should see your uploaded study
4. Click "View" to see study details
5. Click "Report" to create a report

## Common Commands

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f pacs-api
docker-compose logs -f pacs-orthanc
```

### Stop the System

```bash
docker-compose down
```

### Restart the System

```bash
docker-compose restart
```

### Reset Everything

```bash
# Warning: This deletes all data!
docker-compose down -v
docker-compose up -d --build
```

## Troubleshooting

### Services Won't Start

```bash
# Check Docker is running
docker ps

# Check logs for errors
docker-compose logs

# Restart services
docker-compose restart
```

### Can't Access Frontend

1. Check if container is running: `docker ps`
2. Check logs: `docker-compose logs pacs-frontend`
3. Try accessing directly: http://localhost:3000
4. Clear browser cache

### Can't Login

1. Verify API is running: http://localhost:5000/swagger
2. Check API logs: `docker-compose logs pacs-api`
3. Verify database is running: `docker-compose logs sqlserver`
4. Use correct credentials (see Step 4)

### Study Not Appearing in Worklist

1. Check Orthanc received it: http://localhost:8042
2. Check API logs for webhook processing
3. Verify database connection
4. Refresh the worklist page

### Database Connection Issues

```bash
# Restart SQL Server
docker-compose restart sqlserver

# Check if SQL Server is healthy
docker-compose ps sqlserver
```

## Next Steps

### Explore Features

1. **Worklist Management**
   - Search for studies
   - Filter by modality
   - Assign to radiologist
   - Set priority

2. **Study Viewing**
   - View patient demographics
   - See series information
   - Launch OHIF viewer

3. **Reporting**
   - Create draft reports
   - Finalize reports
   - Download PDF

4. **Administration**
   - View audit logs
   - Manage users (future)
   - System configuration

### Configure for Production

See [DEPLOYMENT.md](DEPLOYMENT.md) for:
- Security hardening
- Performance tuning
- Backup configuration
- Monitoring setup

### Integrate with Modalities

See [ARCHITECTURE.md](ARCHITECTURE.md) for:
- DICOM configuration
- Modality setup
- Network configuration
- Testing procedures

### Run Tests

See [TESTING.md](TESTING.md) for:
- Manual testing procedures
- API testing
- Performance testing
- Security testing

## System URLs

| Service | URL | Credentials |
|---------|-----|-------------|
| Frontend | http://localhost:3000 | admin@pacs.local / Admin123! |
| API | http://localhost:5000 | (Use JWT from login) |
| Swagger | http://localhost:5000/swagger | (Use JWT from login) |
| Orthanc | http://localhost:8042 | orthanc / orthanc |
| SQL Server | localhost:1433 | sa / YourStrong@Passw0rd |

## Default Ports

- 3000: React Frontend
- 5000: ASP.NET Core API
- 8042: Orthanc HTTP/DICOMweb
- 4242: Orthanc DICOM C-STORE
- 1433: SQL Server

## File Structure

```
pacs-system/
├── backend/              # ASP.NET Core API
│   ├── PACS.API/        # Web API project
│   ├── PACS.Core/       # Domain layer
│   └── PACS.Infrastructure/  # Data access
├── frontend/            # React application
│   └── src/
│       ├── pages/       # Page components
│       ├── components/  # Reusable components
│       ├── services/    # API services
│       └── contexts/    # React contexts
├── orthanc/             # Orthanc configuration
│   ├── orthanc.json    # Main config
│   └── webhook.py      # Python webhook
├── docker-compose.yml   # Docker orchestration
└── README.md           # This file
```

## Getting Help

1. Check the logs: `docker-compose logs`
2. Review documentation in this repository
3. Check Orthanc logs: http://localhost:8042
4. Verify API health: http://localhost:5000/swagger

## Clean Up

To completely remove the system:

```bash
# Stop and remove containers
docker-compose down

# Remove volumes (deletes all data)
docker-compose down -v

# Remove images
docker rmi pacs-api pacs-frontend
```

## What's Next?

- [ ] Send test DICOM studies
- [ ] Create your first report
- [ ] Configure modality connections
- [ ] Set up backup procedures
- [ ] Review security settings
- [ ] Configure production deployment
- [ ] Integrate with existing systems

## Support

For issues or questions:
1. Check logs for error messages
2. Review documentation files
3. Verify system requirements
4. Check Docker resources

---

**Congratulations!** Your PACS system is now running. Start by uploading a test study and exploring the features.
