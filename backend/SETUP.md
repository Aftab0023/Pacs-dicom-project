# Backend Setup Instructions

## Prerequisites
- .NET 8 SDK
- SQL Server (or use Docker)

## Database Migration

### Create Initial Migration

```bash
cd backend
dotnet ef migrations add InitialCreate --project PACS.Infrastructure --startup-project PACS.API
```

### Apply Migration

```bash
dotnet ef database update --project PACS.Infrastructure --startup-project PACS.API
```

## Run Locally

```bash
cd backend/PACS.API
dotnet run
```

API will be available at: http://localhost:5000

## Swagger Documentation

Once running, access Swagger UI at: http://localhost:5000/swagger

## Default Users

The system seeds two default users:

1. **Admin**
   - Email: admin@pacs.local
   - Password: Admin123!
   - Role: Admin

2. **Radiologist**
   - Email: radiologist@pacs.local
   - Password: Radio123!
   - Role: Radiologist

## Configuration

Edit `appsettings.json` to configure:
- Database connection string
- JWT settings
- Orthanc connection details

## API Endpoints

### Authentication
- POST /api/auth/login
- POST /api/auth/refresh
- POST /api/auth/logout

### Worklist
- GET /api/worklist
- GET /api/worklist/{studyId}
- POST /api/worklist/{studyId}/assign
- PUT /api/worklist/{studyId}/status
- PUT /api/worklist/{studyId}/priority

### Reports
- GET /api/report/{reportId}
- GET /api/report/study/{studyId}
- POST /api/report
- PUT /api/report/{reportId}
- POST /api/report/{reportId}/finalize
- GET /api/report/{reportId}/pdf

### Orthanc Webhook
- POST /api/orthanc/webhook
- GET /api/orthanc/dicomweb/{studyInstanceUID}
