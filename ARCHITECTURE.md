# PACS System Architecture

## Overview

This PACS (Picture Archiving and Communication System) is designed as a modern, microservice-ready radiology information system with clean architecture principles.

## System Components

### 1. Frontend Layer (React + TypeScript)

**Technology Stack:**
- React 18 with TypeScript
- Vite for build tooling
- TanStack Query for data fetching
- Tailwind CSS for styling
- React Router for navigation

**Key Features:**
- JWT-based authentication
- Role-based UI rendering
- Responsive medical-grade dark theme
- Real-time worklist updates
- OHIF viewer integration

**Pages:**
- Login: Authentication portal
- Dashboard: Overview and quick stats
- Worklist: Study management interface
- Study Viewer: Image viewing with OHIF
- Reporting: Report creation and management

### 2. API Layer (ASP.NET Core 8)

**Architecture Pattern:** Clean Architecture / Onion Architecture

**Projects:**
- `PACS.API`: Web API controllers and middleware
- `PACS.Core`: Domain entities, DTOs, interfaces
- `PACS.Infrastructure`: Data access, external services

**Key Features:**
- RESTful API design
- JWT authentication with Bearer tokens
- Role-based authorization
- Swagger/OpenAPI documentation
- CORS support for frontend
- Audit logging middleware

**Controllers:**
- AuthController: Authentication endpoints
- WorklistController: Study management
- ReportController: Report CRUD operations
- OrthancWebhookController: DICOM ingestion

### 3. Database Layer (SQL Server)

**Schema Design:**

```
Patient (1) ──< (N) Study (1) ──< (N) Series (1) ──< (N) Instance
                      │
                      ├──< (N) Report
                      └──< (1) User (Radiologist)

User (1) ──< (N) AuditLog
```

**Key Tables:**
- Patients: Patient demographics
- Studies: Study metadata and status
- Series: Series information
- Instances: Individual DICOM instances
- Users: System users with roles
- Reports: Radiology reports
- AuditLogs: Audit trail

**Indexes:**
- StudyInstanceUID (unique)
- PatientMRN (unique)
- StudyDate, Status, Modality
- AccessionNumber

### 4. DICOM Server (Orthanc)

**Configuration:**
- DICOM C-STORE receiver (port 4242)
- DICOMweb server (WADO-RS, QIDO-RS, STOW-RS)
- REST API (port 8042)
- Python plugin for webhooks
- Local filesystem storage

**Integration:**
- Receives DICOM from modalities
- Triggers webhook on stable study
- Provides DICOMweb for OHIF viewer
- Stores DICOM files persistently

### 5. Image Viewer (OHIF)

**Integration Method:**
- Embedded iframe or separate deployment
- DICOMweb protocol
- Study UID-based launching
- Orthanc as DICOMweb source

**Features:**
- Multi-series viewing
- MPR (Multi-Planar Reconstruction)
- Measurements and annotations
- Hanging protocols
- Viewport synchronization

## Data Flow

### Study Ingestion Workflow

```
1. Modality (CT/MR) 
   ↓ DICOM C-STORE
2. Orthanc DICOM Server
   ↓ Store to filesystem
3. Orthanc Python Webhook
   ↓ HTTP POST
4. ASP.NET Core API
   ↓ Extract metadata
5. SQL Server Database
   ↓ Query
6. React Frontend (Worklist)
```

### Study Viewing Workflow

```
1. User clicks "View" in Worklist
   ↓
2. React navigates to Study Viewer
   ↓
3. API fetches study metadata
   ↓
4. Frontend launches OHIF with Study UID
   ↓
5. OHIF queries Orthanc DICOMweb
   ↓
6. Orthanc serves DICOM images
   ↓
7. OHIF renders images
```

### Reporting Workflow

```
1. Radiologist opens study
   ↓
2. Views images in OHIF
   ↓
3. Navigates to Reporting page
   ↓
4. Enters findings and impression
   ↓
5. Saves draft (can edit later)
   ↓
6. Finalizes report (locked)
   ↓
7. Report stored in database
   ↓
8. Study status updated to "Reported"
   ↓
9. PDF can be generated/downloaded
```

## Security Architecture

### Authentication Flow

```
1. User submits credentials
   ↓
2. API validates against database
   ↓
3. API generates JWT token
   ↓
4. Token returned to frontend
   ↓
5. Frontend stores in localStorage
   ↓
6. Token sent in Authorization header
   ↓
7. API validates token on each request
```

### Authorization Levels

**Roles:**
- Admin: Full system access
- Radiologist: Read studies, create reports
- Referrer: View studies and reports (future)

**Permissions:**
- Study viewing: All authenticated users
- Report creation: Radiologist, Admin
- User management: Admin only
- System configuration: Admin only

### Data Protection

- Passwords: BCrypt hashing
- JWT: HMAC-SHA256 signing
- HTTPS: TLS 1.2+ (production)
- Database: Encrypted connections
- Audit: All actions logged

## Scalability Design

### Horizontal Scaling

**API Layer:**
- Stateless design
- Load balancer ready
- Session stored in JWT
- No server affinity needed

**Database:**
- Read replicas for queries
- Write to primary only
- Connection pooling
- Query optimization

**Storage:**
- Orthanc can use S3/Azure Blob
- CDN for image delivery
- Distributed file system

### Vertical Scaling

**Optimization Points:**
- Database indexes
- Query optimization
- Caching (Redis)
- Async processing
- Background jobs

### Performance Targets

- Study ingestion: < 5 seconds
- Worklist load: < 1 second
- Image viewing: < 3 seconds
- Report save: < 500ms
- Search: < 2 seconds

## Integration Points

### Modality Integration

**DICOM C-STORE:**
- Configure modality AE title
- Add to Orthanc configuration
- Test connectivity
- Verify study reception

**Modality Worklist (Future):**
- MWL SCP implementation
- Schedule integration
- Patient demographics sync

### HL7 Integration (Future)

**ADT Messages:**
- Patient registration
- Patient updates
- Patient merge

**ORM Messages:**
- Order creation
- Order updates
- Order cancellation

### RIS Integration (Future)

**Bidirectional:**
- Order import
- Status updates
- Report export
- Billing integration

## Deployment Architecture

### Development

```
Developer Machine
├── Frontend (npm run dev)
├── API (dotnet run)
├── SQL Server (Docker)
└── Orthanc (Docker)
```

### Production (Docker)

```
Docker Host
├── pacs-frontend (nginx)
├── pacs-api (ASP.NET Core)
├── sqlserver (SQL Server)
└── orthanc (Orthanc + plugins)
```

### Cloud (Azure Example)

```
Azure Cloud
├── Azure Static Web Apps (Frontend)
├── Azure App Service (API)
├── Azure SQL Database
├── Azure Container Instances (Orthanc)
└── Azure Blob Storage (DICOM files)
```

## Monitoring & Observability

### Logging

**Levels:**
- Error: System errors
- Warning: Potential issues
- Information: Key events
- Debug: Detailed diagnostics

**Targets:**
- Console output
- File logging
- Centralized logging (ELK, Splunk)

### Metrics

**Key Metrics:**
- Studies ingested per hour
- Average report turnaround time
- API response times
- Database query performance
- Storage usage
- Active users

### Health Checks

**Endpoints:**
- /health: Overall system health
- /health/db: Database connectivity
- /health/orthanc: Orthanc availability

### Alerts

**Critical:**
- Database connection failure
- Orthanc unavailable
- Disk space < 10%
- API errors > threshold

**Warning:**
- Slow queries
- High memory usage
- Study ingestion delays

## Disaster Recovery

### Backup Strategy

**Database:**
- Full backup: Daily
- Differential: Every 6 hours
- Transaction log: Every 15 minutes
- Retention: 30 days

**DICOM Storage:**
- Incremental backup: Daily
- Full backup: Weekly
- Offsite replication
- Retention: 7 years (regulatory)

**Configuration:**
- Version controlled
- Automated deployment
- Documented procedures

### Recovery Procedures

**RTO (Recovery Time Objective):** 4 hours
**RPO (Recovery Point Objective):** 15 minutes

**Steps:**
1. Restore database from backup
2. Restore DICOM files
3. Verify data integrity
4. Restart services
5. Validate functionality

## Compliance & Standards

### DICOM Compliance

- DICOM 3.0 standard
- Storage SOP classes
- DICOMweb protocols
- Transfer syntaxes

### HIPAA Compliance

- Access controls
- Audit logging
- Data encryption
- PHI protection
- Business associate agreements

### HL7 Compliance (Future)

- HL7 v2.x messages
- ADT, ORM, ORU
- Message acknowledgment
- Error handling

## Future Enhancements

### Phase 2
- HL7 integration
- Modality Worklist
- Advanced search
- Study comparison
- Voice dictation

### Phase 3
- AI integration
- Automated measurements
- Critical findings alerts
- Mobile app
- Teleradiology portal

### Phase 4
- Multi-site deployment
- Cloud-native architecture
- Advanced analytics
- Machine learning models
- 3D reconstruction

## Technology Decisions

### Why ASP.NET Core?
- High performance
- Cross-platform
- Strong typing
- Excellent tooling
- Enterprise support

### Why React?
- Component-based
- Large ecosystem
- TypeScript support
- Performance
- Developer experience

### Why SQL Server?
- ACID compliance
- Strong consistency
- Advanced indexing
- Enterprise features
- Microsoft ecosystem

### Why Orthanc?
- Open source
- DICOM compliant
- DICOMweb support
- Plugin architecture
- Active community

### Why OHIF?
- Open source
- Modern web viewer
- Extensible
- Standards-based
- Active development
