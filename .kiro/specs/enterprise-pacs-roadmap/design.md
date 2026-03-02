# Design Document: Enterprise PACS Roadmap

## Overview

This design transforms the existing PACS system (Orthanc + .NET 8 Web API + MSSQL + OHIF viewer) into an enterprise-grade hospital deployment across three phases. The design maintains backward compatibility while adding enterprise features through modular components that integrate with the existing architecture.

**Current Architecture:**
- Orthanc DICOM server (C-STORE, DICOMweb)
- .NET 8 Web API with JWT authentication
- MSSQL database
- OHIF web viewer
- Lua webhook for study ingestion
- Docker deployment
- Basic RBAC (Admin, Radiologist, Referrer)

**Design Principles:**
- Modular architecture allowing incremental deployment
- Backward compatibility with existing components
- Standards-based integration (DICOM, HL7, DICOMweb)
- Cloud-ready with hybrid deployment support
- Performance-first for large imaging datasets
- Security and compliance by design (HIPAA, DICOM security)

## Architecture

### High-Level System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Hospital Network                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │  Modalities  │    │     RIS      │    │   HIS/EMR    │      │
│  │  (CT/MR/XR)  │    │              │    │              │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │ DICOM              │ REST/HL7          │ HL7          │
│         │ C-STORE            │                   │              │
│         │ C-FIND MWL         │                   │              │
└─────────┼────────────────────┼───────────────────┼──────────────┘
          │                    │                   │
          ▼                    ▼                   ▼
┌─────────────────────────────────────────────────────────────────┐
│                         PACS Layer                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │              Load Balancer / API Gateway                    │ │
│  │              (HTTPS, TLS termination)                       │ │
│  └────────────────────────────────────────────────────────────┘ │
│                                                                   │
│  ┌──────────────────────┐      ┌──────────────────────┐         │
│  │   Orthanc DICOM      │      │   .NET 8 Web API     │         │
│  │   ─────────────      │      │   ───────────────    │         │
│  │   • C-STORE SCP      │◄────►│   • REST endpoints   │         │
│  │   • DICOMweb         │      │   • JWT auth         │         │
│  │   • DICOM TLS        │      │   • Business logic   │         │
│  │   • Lua webhooks     │      │   • HL7 integration  │         │
│  └──────────┬───────────┘      └──────────┬───────────┘         │
│             │                              │                     │
│  ┌──────────▼──────────────────────────────▼───────────┐        │
│  │              MSSQL Database                          │        │
│  │              ───────────────                         │        │
│  │   • Patient demographics                            │        │
│  │   • Study metadata                                  │        │
│  │   • Worklist entries                                │        │
│  │   • Audit logs                                      │        │
│  │   • User accounts & permissions                     │        │
│  │   • Routing rules                                   │        │
│  └──────────────────────────────────────────────────────┘        │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           New Enterprise Components                       │   │
│  │           ──────────────────────────                      │   │
│  │                                                            │   │
│  │   ┌─────────────────┐    ┌─────────────────┐            │   │
│  │   │  MWL Service    │    │  HL7 Listener   │            │   │
│  │   │  (Orthanc       │    │  (TCP listener) │            │   │
│  │   │   plugin)       │    │                 │            │   │
│  │   └─────────────────┘    └─────────────────┘            │   │
│  │                                                            │   │
│  │   ┌─────────────────┐    ┌─────────────────┐            │   │
│  │   │  Study Router   │    │  Audit Logger   │            │   │
│  │   │  (Lua/API)      │    │  (API service)  │            │   │
│  │   └─────────────────┘    └─────────────────┘            │   │
│  │                                                            │   │
│  │   ┌─────────────────┐    ┌─────────────────┐            │   │
│  │   │  Storage Tier   │    │  Report Gen     │            │   │
│  │   │  Manager        │    │  (API service)  │            │   │
│  │   └─────────────────┘    └─────────────────┘            │   │
│  │                                                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │              Storage Layer                                │   │
│  │              ─────────────                                │   │
│  │   ┌──────────┐  ┌──────────┐  ┌──────────┐              │   │
│  │   │   Hot    │  │   Warm   │  │   Cold   │              │   │
│  │   │  (SSD)   │  │  (HDD)   │  │ (Archive)│              │   │
│  │   │  <30d    │  │  30d-1y  │  │   >1y    │              │   │
│  │   └──────────┘  └──────────┘  └──────────┘              │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
│  ┌──────────────────────────────────────────────────────────┐   │
│  │           Monitoring & Observability                      │   │
│  │           ──────────────────────────                      │   │
│  │   • Prometheus metrics                                    │   │
│  │   • Grafana dashboards                                    │   │
│  │   • Application Insights / ELK                            │   │
│  └──────────────────────────────────────────────────────────┘   │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
          │
          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Client Layer                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ OHIF Viewer  │    │  Worklist UI │    │  Admin UI    │      │
│  │ (DICOMweb)   │    │  (React)     │    │  (React)     │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                   │
└───────────────────────────────────────────────────────────────────┘
```

### Multi-Site Architecture (Phase 3)

```
┌─────────────────────────────────────────────────────────────────┐
│                         Site A (Main Hospital)                   │
├─────────────────────────────────────────────────────────────────┤
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │   Orthanc    │◄──►│  .NET API    │◄──►│   MSSQL      │      │
│  │   (Primary)  │    │  (Primary)   │    │  (Primary)   │      │
│  └──────┬───────┘    └──────┬───────┘    └──────┬───────┘      │
│         │                    │                    │              │
│         │                    │                    │ Replication  │
└─────────┼────────────────────┼────────────────────┼──────────────┘
          │                    │                    │
          │ DICOM Q/R          │ REST API           │ DB Sync
          │ Study routing      │ Federation         │
          │                    │                    │
┌─────────┼────────────────────┼────────────────────┼──────────────┐
│         │                    │                    │              │
│  ┌──────▼───────┐    ┌──────▼───────┐    ┌──────▼───────┐      │
│  │   Orthanc    │◄──►│  .NET API    │◄──►│   MSSQL      │      │
│  │  (Secondary) │    │ (Secondary)  │    │ (Secondary)  │      │
│  └──────────────┘    └──────────────┘    └──────────────┘      │
│                                                                   │
│                         Site B (Branch Hospital)                 │
└───────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    Global Study Index                            │
│                    ──────────────────                            │
│   StudyUID → Site mapping                                        │
│   Cross-site query federation                                    │
│   Routing rules and policies                                     │
└───────────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### Phase 1 Components

#### 1. Enhanced Modality Worklist (MWL) Service

**Technology:** Orthanc Worklist Plugin or custom C-FIND SCP

**Implementation Approach:**
- Use Orthanc's built-in worklist plugin configured to read from database
- Alternative: Implement custom DICOM MWL SCP in .NET using fo-dicom library
- Worklist data stored in MSSQL with real-time sync

**Database Schema:**
```sql
CREATE TABLE WorklistEntries (
    WorklistID INT PRIMARY KEY IDENTITY,
    AccessionNumber NVARCHAR(50) NOT NULL UNIQUE,
    PatientID NVARCHAR(50) NOT NULL,
    PatientName NVARCHAR(200) NOT NULL,
    PatientBirthDate DATE,
    PatientSex CHAR(1),
    ScheduledProcedureStepStartDate DATETIME NOT NULL,
    ScheduledProcedureStepStartTime TIME,
    Modality NVARCHAR(10) NOT NULL,
    ScheduledStationAETitle NVARCHAR(50),
    ScheduledProcedureStepDescription NVARCHAR(500),
    StudyInstanceUID NVARCHAR(100),
    RequestedProcedureID NVARCHAR(50),
    ReferringPhysicianName NVARCHAR(200),
    Status NVARCHAR(20) DEFAULT 'SCHEDULED',
    CreatedDate DATETIME DEFAULT GETDATE(),
    CompletedDate DATETIME NULL,
    INDEX IX_AccessionNumber (AccessionNumber),
    INDEX IX_ScheduledDate (ScheduledProcedureStepStartDate),
    INDEX IX_Modality (Modality),
    INDEX IX_Status (Status)
);
```

**API Endpoints:**
```
POST   /api/worklist/entries          - Create worklist entry
GET    /api/worklist/entries          - Query worklist entries
GET    /api/worklist/entries/{id}     - Get specific entry
PUT    /api/worklist/entries/{id}     - Update entry
DELETE /api/worklist/entries/{id}     - Delete entry
PATCH  /api/worklist/entries/{id}/status - Update status
```

**Orthanc Configuration:**
```json
{
  "Worklist": {
    "Enable": true,
    "Database": "mssql://connection-string"
  }
}
```

**Integration Flow:**
1. RIS/Frontend creates worklist entry via API
2. API writes to WorklistEntries table
3. Orthanc worklist plugin reads from database
4. Modality queries worklist via DICOM C-FIND
5. Modality receives scheduled procedures
6. Study arrives with matching AccessionNumber
7. Lua webhook links study to worklist entry

#### 2. RIS Integration Layer

**Technology:** .NET 8 Web API with REST endpoints

**Integration Patterns:**
- REST API for synchronous operations
- Webhook callbacks for async notifications
- Message queue (Azure Service Bus / RabbitMQ) for reliable delivery

**API Contract:**
```csharp
// Request: Schedule procedure
public class ScheduleProcedureRequest
{
    public string AccessionNumber { get; set; }
    public string PatientID { get; set; }
    public string PatientName { get; set; }
    public DateTime PatientBirthDate { get; set; }
    public string PatientSex { get; set; }
    public DateTime ScheduledDateTime { get; set; }
    public string Modality { get; set; }
    public string ProcedureDescription { get; set; }
    public string ReferringPhysician { get; set; }
    public string RequestedProcedureID { get; set; }
}

// Response
public class ScheduleProcedureResponse
{
    public bool Success { get; set; }
    public string WorklistID { get; set; }
    public string Message { get; set; }
}

// Webhook: Study completed
public class StudyCompletedNotification
{
    public string AccessionNumber { get; set; }
    public string StudyInstanceUID { get; set; }
    public DateTime CompletedDateTime { get; set; }
    public string Status { get; set; } // "COMPLETED", "REPORTED", "VERIFIED"
    public string ReportText { get; set; }
}
```

**Retry Logic:**
```csharp
public class RISIntegrationService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IMessageQueue _messageQueue;
    
    public async Task NotifyRISAsync(StudyCompletedNotification notification)
    {
        var policy = Policy
            .Handle<HttpRequestException>()
            .WaitAndRetryAsync(
                retryCount: 5,
                sleepDurationProvider: attempt => TimeSpan.FromMinutes(Math.Pow(2, attempt)),
                onRetry: (exception, timeSpan, retryCount, context) =>
                {
                    _logger.LogWarning($"RIS notification failed. Retry {retryCount} after {timeSpan}");
                });
        
        await policy.ExecuteAsync(async () =>
        {
            var client = _httpClientFactory.CreateClient("RIS");
            var response = await client.PostAsJsonAsync("/api/pacs/study-completed", notification);
            response.EnsureSuccessStatusCode();
        });
    }
}
```

#### 3. Advanced Study Routing Engine

**Technology:** Lua scripts in Orthanc + .NET API routing service

**Implementation:** Two-tier approach
- Tier 1: Lua script in Orthanc for immediate routing decisions
- Tier 2: .NET API service for complex rule evaluation

**Database Schema:**
```sql
CREATE TABLE RoutingRules (
    RuleID INT PRIMARY KEY IDENTITY,
    RuleName NVARCHAR(100) NOT NULL,
    Priority INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
    Conditions NVARCHAR(MAX) NOT NULL, -- JSON
    Actions NVARCHAR(MAX) NOT NULL,    -- JSON
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    INDEX IX_Priority (Priority DESC, IsActive)
);

CREATE TABLE StudyAssignments (
    AssignmentID INT PRIMARY KEY IDENTITY,
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    AssignedToUserID INT NOT NULL,
    AssignedDate DATETIME DEFAULT GETDATE(),
    AssignedByRuleID INT NULL,
    Priority NVARCHAR(20) DEFAULT 'ROUTINE', -- STAT, URGENT, ROUTINE
    Status NVARCHAR(20) DEFAULT 'PENDING',
    FOREIGN KEY (AssignedToUserID) REFERENCES Users(UserID),
    FOREIGN KEY (AssignedByRuleID) REFERENCES RoutingRules(RuleID),
    INDEX IX_StudyUID (StudyInstanceUID),
    INDEX IX_AssignedUser (AssignedToUserID, Status)
);
```

**Routing Rule JSON Format:**
```json
{
  "ruleName": "CT Head to Neuroradiologist",
  "priority": 90,
  "conditions": {
    "modality": "CT",
    "bodyPart": ["HEAD", "BRAIN"],
    "studyDescription": "*head*",
    "timeOfDay": {
      "start": "08:00",
      "end": "17:00"
    }
  },
  "actions": {
    "assignTo": "group:neuroradiology",
    "loadBalance": true,
    "priority": "ROUTINE",
    "notify": true
  }
}
```

**Lua Routing Script:**
```lua
function OnStoredInstance(instanceId, tags, metadata, origin)
    local studyUID = tags['StudyInstanceUID']
    local modality = tags['Modality']
    local studyDesc = tags['StudyDescription']
    
    -- Call .NET API for routing decision
    local routingRequest = {
        studyInstanceUID = studyUID,
        modality = modality,
        studyDescription = studyDesc,
        patientID = tags['PatientID'],
        referringPhysician = tags['ReferringPhysicianName']
    }
    
    local response = HttpPost(
        'http://api:5000/api/routing/evaluate',
        DumpJson(routingRequest)
    )
    
    if response then
        local routing = ParseJson(response)
        if routing.assignTo then
            -- Store assignment in metadata
            SetMetadata(instanceId, 'AssignedTo', routing.assignTo)
        end
    end
end
```

#### 4. Granular RBAC System

**Technology:** .NET 8 Identity with custom claims

**Database Schema:**
```sql
CREATE TABLE Permissions (
    PermissionID INT PRIMARY KEY IDENTITY,
    PermissionName NVARCHAR(100) NOT NULL UNIQUE,
    Category NVARCHAR(50) NOT NULL, -- STUDY, ADMIN, REPORT, etc.
    Description NVARCHAR(500)
);

CREATE TABLE RolePermissions (
    RoleID INT NOT NULL,
    PermissionID INT NOT NULL,
    PRIMARY KEY (RoleID, PermissionID),
    FOREIGN KEY (RoleID) REFERENCES Roles(RoleID),
    FOREIGN KEY (PermissionID) REFERENCES Permissions(PermissionID)
);

CREATE TABLE UserDepartments (
    UserID INT NOT NULL,
    DepartmentID INT NOT NULL,
    PRIMARY KEY (UserID, DepartmentID),
    FOREIGN KEY (UserID) REFERENCES Users(UserID),
    FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID)
);

CREATE TABLE StudyAccessControl (
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    DepartmentID INT NULL,
    UserID INT NULL,
    AccessType NVARCHAR(20) NOT NULL, -- VIEW, DOWNLOAD, DELETE, SHARE
    ExpiresAt DATETIME NULL,
    PRIMARY KEY (StudyInstanceUID, DepartmentID, UserID, AccessType)
);
```

**Permission Examples:**
- `study.view.all` - View all studies
- `study.view.department` - View studies in user's department
- `study.view.assigned` - View only assigned studies
- `study.download` - Download studies
- `study.delete` - Delete studies
- `study.share.external` - Share studies externally
- `report.create` - Create reports
- `report.finalize` - Finalize reports
- `admin.users.manage` - Manage users
- `admin.routing.configure` - Configure routing rules

**Authorization Service:**
```csharp
public class StudyAuthorizationService
{
    public async Task<bool> CanAccessStudyAsync(
        string userId, 
        string studyInstanceUID, 
        string accessType)
    {
        var user = await _userRepository.GetUserWithPermissionsAsync(userId);
        
        // Check global permission
        if (user.HasPermission($"study.{accessType}.all"))
            return true;
        
        // Check department-based access
        if (user.HasPermission($"study.{accessType}.department"))
        {
            var studyDept = await _studyRepository.GetStudyDepartmentAsync(studyInstanceUID);
            if (user.Departments.Contains(studyDept))
                return true;
        }
        
        // Check explicit study access
        var explicitAccess = await _db.StudyAccessControl
            .AnyAsync(sac => 
                sac.StudyInstanceUID == studyInstanceUID &&
                sac.UserID == user.UserID &&
                sac.AccessType == accessType.ToUpper() &&
                (sac.ExpiresAt == null || sac.ExpiresAt > DateTime.UtcNow));
        
        return explicitAccess;
    }
}
```

**Middleware:**
```csharp
public class StudyAuthorizationMiddleware
{
    public async Task InvokeAsync(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        var studyAuth = endpoint?.Metadata.GetMetadata<RequireStudyAccessAttribute>();
        
        if (studyAuth != null)
        {
            var studyUID = context.Request.RouteValues["studyInstanceUID"]?.ToString();
            var userId = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
            
            var authorized = await _authService.CanAccessStudyAsync(
                userId, studyUID, studyAuth.AccessType);
            
            if (!authorized)
            {
                context.Response.StatusCode = 403;
                await context.Response.WriteAsJsonAsync(new { error = "Access denied" });
                return;
            }
        }
        
        await _next(context);
    }
}
```

#### 5. Comprehensive Audit Logging

**Technology:** .NET 8 with structured logging + dedicated audit database

**Database Schema:**
```sql
CREATE TABLE AuditLogs (
    AuditID BIGINT PRIMARY KEY IDENTITY,
    EventType NVARCHAR(50) NOT NULL,
    EventCategory NVARCHAR(50) NOT NULL, -- AUTH, STUDY_ACCESS, CONFIG, DICOM
    Timestamp DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    UserID INT NULL,
    Username NVARCHAR(100),
    IPAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    Action NVARCHAR(100) NOT NULL,
    ResourceType NVARCHAR(50),
    ResourceID NVARCHAR(200),
    Success BIT NOT NULL,
    ErrorMessage NVARCHAR(MAX),
    AdditionalData NVARCHAR(MAX), -- JSON
    Signature NVARCHAR(500), -- HMAC signature for tamper detection
    INDEX IX_Timestamp (Timestamp DESC),
    INDEX IX_UserID (UserID, Timestamp),
    INDEX IX_EventType (EventType, Timestamp),
    INDEX IX_ResourceID (ResourceID, Timestamp)
);

CREATE TABLE AuditLogArchive (
    -- Same schema as AuditLogs
    -- Partitioned by year/month for efficient archival
);
```

**Audit Event Types:**
- `AUTH_LOGIN_SUCCESS` / `AUTH_LOGIN_FAILED`
- `AUTH_LOGOUT`
- `AUTH_TOKEN_REFRESH`
- `STUDY_VIEW`
- `STUDY_DOWNLOAD`
- `STUDY_DELETE`
- `STUDY_SHARE`
- `STUDY_PRINT`
- `REPORT_CREATE`
- `REPORT_EDIT`
- `REPORT_FINALIZE`
- `CONFIG_CHANGE`
- `USER_CREATE` / `USER_MODIFY` / `USER_DELETE`
- `DICOM_RECEIVE`
- `DICOM_SEND`
- `DICOM_QUERY`

**Audit Service:**
```csharp
public class AuditService
{
    private readonly IDbContext _db;
    private readonly IConfiguration _config;
    
    public async Task LogAsync(AuditEvent auditEvent)
    {
        var log = new AuditLog
        {
            EventType = auditEvent.EventType,
            EventCategory = auditEvent.Category,
            Timestamp = DateTime.UtcNow,
            UserID = auditEvent.UserID,
            Username = auditEvent.Username,
            IPAddress = auditEvent.IPAddress,
            UserAgent = auditEvent.UserAgent,
            Action = auditEvent.Action,
            ResourceType = auditEvent.ResourceType,
            ResourceID = auditEvent.ResourceID,
            Success = auditEvent.Success,
            ErrorMessage = auditEvent.ErrorMessage,
            AdditionalData = JsonSerializer.Serialize(auditEvent.AdditionalData)
        };
        
        // Generate HMAC signature for tamper detection
        log.Signature = GenerateSignature(log);
        
        _db.AuditLogs.Add(log);
        await _db.SaveChangesAsync();
        
        // Also send to external SIEM if configured
        if (_config.GetValue<bool>("Audit:SendToSIEM"))
        {
            await SendToSIEMAsync(log);
        }
    }
    
    private string GenerateSignature(AuditLog log)
    {
        var data = $"{log.Timestamp:O}|{log.UserID}|{log.Action}|{log.ResourceID}";
        var key = _config["Audit:SigningKey"];
        using var hmac = new HMACSHA256(Encoding.UTF8.GetBytes(key));
        var hash = hmac.ComputeHash(Encoding.UTF8.GetBytes(data));
        return Convert.ToBase64String(hash);
    }
}
```

**Archival Strategy:**
```csharp
public class AuditArchivalService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // Run daily at 2 AM
            await Task.Delay(TimeSpan.FromHours(24), stoppingToken);
            
            var cutoffDate = DateTime.UtcNow.AddDays(-90);
            
            // Move logs older than 90 days to archive table
            await _db.Database.ExecuteSqlRawAsync(@"
                INSERT INTO AuditLogArchive 
                SELECT * FROM AuditLogs 
                WHERE Timestamp < @cutoffDate",
                new SqlParameter("@cutoffDate", cutoffDate));
            
            await _db.Database.ExecuteSqlRawAsync(@"
                DELETE FROM AuditLogs 
                WHERE Timestamp < @cutoffDate",
                new SqlParameter("@cutoffDate", cutoffDate));
        }
    }
}
```

#### 6. Performance Optimization

**Caching Strategy:**

**Technology:** Redis for distributed caching

**Cache Layers:**
1. **Study Metadata Cache** - 1 hour TTL
2. **Thumbnail Cache** - 24 hour TTL
3. **User Session Cache** - Session lifetime
4. **Worklist Cache** - 5 minute TTL

**Implementation:**
```csharp
public class StudyCacheService
{
    private readonly IDistributedCache _cache;
    private readonly IStudyRepository _repository;
    
    public async Task<StudyMetadata> GetStudyAsync(string studyInstanceUID)
    {
        var cacheKey = $"study:{studyInstanceUID}";
        var cached = await _cache.GetStringAsync(cacheKey);
        
        if (cached != null)
        {
            return JsonSerializer.Deserialize<StudyMetadata>(cached);
        }
        
        var study = await _repository.GetStudyAsync(studyInstanceUID);
        
        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(study),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(1)
            });
        
        return study;
    }
}
```

**Database Optimization:**
```sql
-- Indexed views for common queries
CREATE VIEW vw_StudyList WITH SCHEMABINDING AS
SELECT 
    s.StudyInstanceUID,
    s.PatientID,
    s.PatientName,
    s.StudyDate,
    s.Modality,
    s.StudyDescription,
    s.NumberOfImages,
    s.AssignedToUserID,
    s.Status
FROM dbo.Studies s;

CREATE UNIQUE CLUSTERED INDEX IX_StudyList 
ON vw_StudyList(StudyDate DESC, StudyInstanceUID);

-- Partitioning for large tables
CREATE PARTITION FUNCTION pf_StudyDate (DATE)
AS RANGE RIGHT FOR VALUES 
('2023-01-01', '2023-07-01', '2024-01-01', '2024-07-01', '2025-01-01');

CREATE PARTITION SCHEME ps_StudyDate
AS PARTITION pf_StudyDate
ALL TO ([PRIMARY]);

-- Apply to Studies table
CREATE TABLE Studies (
    StudyID INT IDENTITY,
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    StudyDate DATE NOT NULL,
    -- other columns
) ON ps_StudyDate(StudyDate);
```

**DICOM Compression:**
```json
{
  "Orthanc": {
    "StorageCompression": true,
    "CompressionLevel": 6,
    "IngestTranscoding": "1.2.840.10008.1.2.4.90",
    "DicomWeb": {
      "EnableWado": true,
      "WadoCompression": "jpeg"
    }
  }
}
```

**Connection Pooling:**
```csharp
services.AddDbContext<PacsDbContext>(options =>
{
    options.UseSqlServer(connectionString, sqlOptions =>
    {
        sqlOptions.EnableRetryOnFailure(
            maxRetryCount: 3,
            maxRetryDelay: TimeSpan.FromSeconds(5),
            errorNumbersToAdd: null);
        sqlOptions.CommandTimeout(30);
    });
}, ServiceLifetime.Scoped);

// Connection pool settings in connection string
"Server=...;Database=...;Max Pool Size=200;Min Pool Size=10;Connection Timeout=30;"
```

#### 7. Secure DICOM TLS and HTTPS

**DICOM TLS Configuration:**

**Technology:** Orthanc with DICOM TLS support

**Certificate Setup:**
```bash
# Generate CA certificate
openssl req -x509 -newkey rsa:4096 -keyout ca-key.pem -out ca-cert.pem -days 3650 -nodes

# Generate server certificate
openssl req -newkey rsa:4096 -keyout server-key.pem -out server-req.pem -nodes
openssl x509 -req -in server-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out server-cert.pem -days 365

# Generate client certificates for each modality
openssl req -newkey rsa:4096 -keyout client-key.pem -out client-req.pem -nodes
openssl x509 -req -in client-req.pem -CA ca-cert.pem -CAkey ca-key.pem -CAcreateserial -out client-cert.pem -days 365
```

**Orthanc Configuration:**
```json
{
  "DicomTlsEnabled": true,
  "DicomTlsCertificate": "/etc/orthanc/certs/server-cert.pem",
  "DicomTlsPrivateKey": "/etc/orthanc/certs/server-key.pem",
  "DicomTlsTrustedCertificates": "/etc/orthanc/certs/ca-cert.pem",
  "DicomTlsRemoteCertificateRequired": true,
  "DicomAlwaysAllowStore": false,
  "DicomCheckCalledAet": true,
  "DicomCheckModalityHost": true,
  "DicomModalities": {
    "CT_SCANNER_1": {
      "AET": "CT1",
      "Host": "192.168.1.100",
      "Port": 11112,
      "UseDicomTls": true,
      "Certificate": "/etc/orthanc/certs/ct1-cert.pem"
    }
  }
}
```

**HTTPS Configuration:**

**.NET API (Program.cs):**
```csharp
var builder = WebApplication.CreateBuilder(args);

builder.WebHost.ConfigureKestrel(options =>
{
    options.Listen(IPAddress.Any, 5000); // HTTP for internal
    options.Listen(IPAddress.Any, 5001, listenOptions =>
    {
        listenOptions.UseHttps(httpsOptions =>
        {
            httpsOptions.ServerCertificate = LoadCertificate();
            httpsOptions.SslProtocols = SslProtocols.Tls12 | SslProtocols.Tls13;
            httpsOptions.ClientCertificateMode = ClientCertificateMode.AllowCertificate;
        });
    });
});

// Enforce HTTPS
app.UseHttpsRedirection();
app.UseHsts();

// Security headers
app.Use(async (context, next) =>
{
    context.Response.Headers.Add("Strict-Transport-Security", "max-age=31536000; includeSubDomains");
    context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
    context.Response.Headers.Add("X-Frame-Options", "DENY");
    context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
    context.Response.Headers.Add("Content-Security-Policy", "default-src 'self'");
    await next();
});
```

**Nginx Reverse Proxy (Production):**
```nginx
server {
    listen 443 ssl http2;
    server_name pacs.hospital.com;
    
    ssl_certificate /etc/nginx/certs/pacs.crt;
    ssl_certificate_key /etc/nginx/certs/pacs.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    # HSTS
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    location /api/ {
        proxy_pass http://localhost:5000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    location /orthanc/ {
        proxy_pass http://localhost:8042/;
        proxy_set_header Host $host;
        proxy_request_buffering off;
        proxy_buffering off;
        client_max_body_size 4G;
    }
}
```

#### 8. Storage Optimization and Tiering

**Technology:** Custom .NET service + Orthanc storage plugins

**Storage Architecture:**
```
Hot Tier (SSD):     Recent studies (<30 days)     - Fast access
Warm Tier (HDD):    Older studies (30d - 1y)      - Moderate access
Cold Tier (Archive): Historical studies (>1y)     - Slow access, low cost
```

**Database Schema:**
```sql
CREATE TABLE StorageTiers (
    TierID INT PRIMARY KEY IDENTITY,
    TierName NVARCHAR(50) NOT NULL,
    StoragePath NVARCHAR(500) NOT NULL,
    TierType NVARCHAR(20) NOT NULL, -- HOT, WARM, COLD
    MaxCapacityGB INT NOT NULL,
    CurrentUsageGB DECIMAL(10,2) DEFAULT 0,
    IsActive BIT DEFAULT 1
);

CREATE TABLE StudyStorageLocation (
    StudyInstanceUID NVARCHAR(100) PRIMARY KEY,
    TierID INT NOT NULL,
    StoragePath NVARCHAR(500) NOT NULL,
    LastAccessDate DATETIME NOT NULL DEFAULT GETDATE(),
    MigrationDate DATETIME NULL,
    FileSize BIGINT NOT NULL,
    FOREIGN KEY (TierID) REFERENCES StorageTiers(TierID),
    INDEX IX_LastAccess (LastAccessDate),
    INDEX IX_TierID (TierID)
);
```

**Tiering Service:**
```csharp
public class StorageTieringService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromHours(1), stoppingToken);
            
            await MigrateToWarmTierAsync();
            await MigrateToColdTierAsync();
        }
    }
    
    private async Task MigrateToWarmTierAsync()
    {
        var cutoffDate = DateTime.UtcNow.AddDays(-30);
        
        var studiesToMigrate = await _db.StudyStorageLocation
            .Where(s => s.TierID == HOT_TIER_ID && 
                       s.LastAccessDate < cutoffDate)
            .Take(100)
            .ToListAsync();
        
        foreach (var study in studiesToMigrate)
        {
            await MigrateStudyAsync(study, WARM_TIER_ID);
        }
    }
    
    private async Task MigrateStudyAsync(StudyStorageLocation study, int targetTierID)
    {
        var targetTier = await _db.StorageTiers.FindAsync(targetTierID);
        var sourcePath = study.StoragePath;
        var targetPath = Path.Combine(targetTier.StoragePath, study.StudyInstanceUID);
        
        // Copy files
        await CopyDirectoryAsync(sourcePath, targetPath);
        
        // Verify integrity
        if (await VerifyIntegrityAsync(sourcePath, targetPath))
        {
            // Update database
            study.TierID = targetTierID;
            study.StoragePath = targetPath;
            study.MigrationDate = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            
            // Delete from source
            Directory.Delete(sourcePath, recursive: true);
            
            _logger.LogInformation($"Migrated study {study.StudyInstanceUID} to tier {targetTierID}");
        }
    }
}
```

**Orthanc Storage Plugin Configuration:**
```json
{
  "StorageDirectory": "/var/lib/orthanc/hot",
  "Plugins": [
    "/usr/share/orthanc/plugins/libOrthancStorageTiering.so"
  ],
  "StorageTiering": {
    "HotTier": "/var/lib/orthanc/hot",
    "WarmTier": "/mnt/warm/orthanc",
    "ColdTier": "/mnt/cold/orthanc",
    "HotTierDays": 30,
    "WarmTierDays": 365
  }
}
```

**Access Pattern Tracking:**
```csharp
public class StudyAccessTracker
{
    public async Task TrackAccessAsync(string studyInstanceUID)
    {
        var location = await _db.StudyStorageLocation
            .FirstOrDefaultAsync(s => s.StudyInstanceUID == studyInstanceUID);
        
        if (location != null)
        {
            location.LastAccessDate = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            
            // If study is in cold tier and accessed, consider promoting
            if (location.TierID == COLD_TIER_ID)
            {
                await ConsiderPromotionAsync(location);
            }
        }
    }
}
```

### Phase 2 Components

#### 9. HL7 Integration Service

**Technology:** .NET 8 with NHapi library for HL7 parsing

**Architecture:**
```
HL7 Source (HIS/EMR) → TCP Listener → Message Queue → Message Processor → Database
                                    ↓
                              Dead Letter Queue
```

**Database Schema:**
```sql
CREATE TABLE HL7Messages (
    MessageID BIGINT PRIMARY KEY IDENTITY,
    MessageType NVARCHAR(20) NOT NULL, -- ADT^A01, ORM^O01, ORU^R01
    MessageControlID NVARCHAR(50) NOT NULL,
    RawMessage NVARCHAR(MAX) NOT NULL,
    ReceivedDate DATETIME DEFAULT GETDATE(),
    ProcessedDate DATETIME NULL,
    Status NVARCHAR(20) DEFAULT 'PENDING', -- PENDING, PROCESSED, FAILED
    ErrorMessage NVARCHAR(MAX) NULL,
    RetryCount INT DEFAULT 0,
    INDEX IX_Status (Status, ReceivedDate),
    INDEX IX_MessageControlID (MessageControlID)
);

CREATE TABLE HL7DeadLetterQueue (
    -- Same schema as HL7Messages
    MovedToDeadLetterDate DATETIME DEFAULT GETDATE()
);
```

**HL7 Listener Service:**
```csharp
public class HL7ListenerService : BackgroundService
{
    private TcpListener _listener;
    private readonly IMessageQueue _messageQueue;
    
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var port = _config.GetValue<int>("HL7:Port", 2575);
        _listener = new TcpListener(IPAddress.Any, port);
        _listener.Start();
        
        _logger.LogInformation($"HL7 Listener started on port {port}");
        
        while (!stoppingToken.IsCancellationRequested)
        {
            var client = await _listener.AcceptTcpClientAsync();
            _ = HandleClientAsync(client, stoppingToken);
        }
    }
    
    private async Task HandleClientAsync(TcpClient client, CancellationToken ct)
    {
        using var stream = client.GetStream();
        using var reader = new StreamReader(stream);
        using var writer = new StreamWriter(stream) { AutoFlush = true };
        
        try
        {
            var message = await ReadHL7MessageAsync(reader);
            
            // Store in database
            var messageEntity = new HL7Message
            {
                RawMessage = message,
                MessageType = ExtractMessageType(message),
                MessageControlID = ExtractControlID(message),
                Status = "PENDING"
            };
            
            await _db.HL7Messages.AddAsync(messageEntity);
            await _db.SaveChangesAsync();
            
            // Queue for processing
            await _messageQueue.EnqueueAsync(messageEntity.MessageID);
            
            // Send ACK
            var ack = GenerateACK(message, "AA"); // Application Accept
            await writer.WriteAsync(ack);
            
            _logger.LogInformation($"Received HL7 message: {messageEntity.MessageControlID}");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error processing HL7 message");
            
            // Send NACK
            var nack = GenerateACK("", "AE", ex.Message); // Application Error
            await writer.WriteAsync(nack);
        }
    }
    
    private async Task<string> ReadHL7MessageAsync(StreamReader reader)
    {
        var sb = new StringBuilder();
        int b;
        
        // HL7 messages start with 0x0B and end with 0x1C 0x0D
        while ((b = await reader.ReadAsync()) != -1)
        {
            if (b == 0x0B) // Start of message
            {
                sb.Clear();
                continue;
            }
            if (b == 0x1C) // End of message
            {
                await reader.ReadAsync(); // Read trailing 0x0D
                break;
            }
            sb.Append((char)b);
        }
        
        return sb.ToString();
    }
}
```

**HL7 Message Processor:**
```csharp
public class HL7MessageProcessor : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var messageId = await _messageQueue.DequeueAsync(stoppingToken);
            await ProcessMessageAsync(messageId);
        }
    }
    
    private async Task ProcessMessageAsync(long messageId)
    {
        var message = await _db.HL7Messages.FindAsync(messageId);
        
        try
        {
            var parser = new PipeParser();
            var parsedMessage = parser.Parse(message.RawMessage);
            
            switch (message.MessageType)
            {
                case "ADT^A01": // Patient Admission
                case "ADT^A04": // Patient Registration
                case "ADT^A08": // Patient Update
                    await ProcessADTMessageAsync(parsedMessage);
                    break;
                    
                case "ORM^O01": // Order Message
                    await ProcessORMMessageAsync(parsedMessage);
                    break;
                    
                case "ORU^R01": // Observation Result
                    await ProcessORUMessageAsync(parsedMessage);
                    break;
                    
                default:
                    _logger.LogWarning($"Unsupported message type: {message.MessageType}");
                    break;
            }
            
            message.Status = "PROCESSED";
            message.ProcessedDate = DateTime.UtcNow;
            await _db.SaveChangesAsync();
        }
        catch (Exception ex)
        {
            message.RetryCount++;
            message.ErrorMessage = ex.Message;
            
            if (message.RetryCount >= 5)
            {
                // Move to dead letter queue
                await MoveToDeadLetterQueueAsync(message);
            }
            else
            {
                message.Status = "PENDING";
                await _db.SaveChangesAsync();
                
                // Re-queue with exponential backoff
                var delay = TimeSpan.FromMinutes(Math.Pow(2, message.RetryCount));
                await Task.Delay(delay);
                await _messageQueue.EnqueueAsync(messageId);
            }
        }
    }
    
    private async Task ProcessADTMessageAsync(IMessage message)
    {
        var adt = message as ADT_A01;
        var pid = adt.PID;
        
        var patient = new Patient
        {
            PatientID = pid.PatientID.ID.Value,
            PatientName = $"{pid.PatientName[0].FamilyName.Surname.Value}^{pid.PatientName[0].GivenName.Value}",
            DateOfBirth = DateTime.ParseExact(pid.DateTimeOfBirth.Time.Value, "yyyyMMdd", null),
            Sex = pid.AdministrativeSex.Value
        };
        
        await _patientService.UpsertPatientAsync(patient);
    }
    
    private async Task ProcessORMMessageAsync(IMessage message)
    {
        var orm = message as ORM_O01;
        var pid = orm.PATIENT.PID;
        var orc = orm.ORDER.ORC;
        var obr = orm.ORDER.ORDER_DETAIL.OBR;
        
        var worklistEntry = new WorklistEntry
        {
            AccessionNumber = obr.FillerOrderNumber.EntityIdentifier.Value,
            PatientID = pid.PatientID.ID.Value,
            PatientName = $"{pid.PatientName[0].FamilyName.Surname.Value}^{pid.PatientName[0].GivenName.Value}",
            ScheduledProcedureStepStartDate = DateTime.ParseExact(
                obr.ObservationDateTime.Time.Value, "yyyyMMddHHmmss", null),
            Modality = obr.UniversalServiceIdentifier.Identifier.Value,
            ScheduledProcedureStepDescription = obr.UniversalServiceIdentifier.Text.Value,
            ReferringPhysicianName = obr.OrderingProvider[0].FamilyName.Surname.Value
        };
        
        await _worklistService.CreateWorklistEntryAsync(worklistEntry);
    }
}
```

**HL7 Configuration:**
```json
{
  "HL7": {
    "Port": 2575,
    "Enabled": true,
    "SendingApplication": "PACS",
    "SendingFacility": "HOSPITAL",
    "ProcessingID": "P",
    "VersionID": "2.5",
    "RetryAttempts": 5,
    "RetryDelayMinutes": 2
  }
}
```

#### 10. Structured Reporting Module

**Technology:** .NET 8 API with template engine

**Database Schema:**
```sql
CREATE TABLE ReportTemplates (
    TemplateID INT PRIMARY KEY IDENTITY,
    TemplateName NVARCHAR(200) NOT NULL,
    Modality NVARCHAR(10) NOT NULL,
    BodyPart NVARCHAR(100),
    TemplateJSON NVARCHAR(MAX) NOT NULL, -- JSON structure
    Version INT DEFAULT 1,
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE(),
    INDEX IX_Modality_BodyPart (Modality, BodyPart)
);

CREATE TABLE Reports (
    ReportID INT PRIMARY KEY IDENTITY,
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    TemplateID INT NULL,
    ReportData NVARCHAR(MAX) NOT NULL, -- JSON
    ReportText NVARCHAR(MAX) NOT NULL, -- Rendered text
    Status NVARCHAR(20) DEFAULT 'DRAFT', -- DRAFT, PRELIMINARY, FINAL
    CreatedByUserID INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    FinalizedByUserID INT NULL,
    FinalizedDate DATETIME NULL,
    FOREIGN KEY (TemplateID) REFERENCES ReportTemplates(TemplateID),
    FOREIGN KEY (CreatedByUserID) REFERENCES Users(UserID),
    INDEX IX_StudyUID (StudyInstanceUID),
    INDEX IX_Status (Status)
);
```

**Template JSON Structure:**
```json
{
  "templateName": "CT Head",
  "modality": "CT",
  "bodyPart": "HEAD",
  "sections": [
    {
      "sectionName": "Clinical Indication",
      "fieldType": "textarea",
      "required": true,
      "maxLength": 500
    },
    {
      "sectionName": "Technique",
      "fieldType": "template",
      "defaultValue": "Non-contrast CT of the head was performed with 5mm axial slices."
    },
    {
      "sectionName": "Findings",
      "fields": [
        {
          "fieldName": "Brain Parenchyma",
          "fieldType": "select",
          "options": ["Normal", "Abnormal"],
          "required": true
        },
        {
          "fieldName": "Abnormality Description",
          "fieldType": "textarea",
          "conditionalOn": {
            "field": "Brain Parenchyma",
            "value": "Abnormal"
          }
        },
        {
          "fieldName": "Ventricles",
          "fieldType": "select",
          "options": ["Normal size", "Enlarged", "Compressed"],
          "required": true
        },
        {
          "fieldName": "Hemorrhage",
          "fieldType": "checkbox",
          "label": "Evidence of hemorrhage"
        },
        {
          "fieldName": "Hemorrhage Location",
          "fieldType": "multiselect",
          "options": ["Subdural", "Epidural", "Subarachnoid", "Intraparenchymal"],
          "conditionalOn": {
            "field": "Hemorrhage",
            "value": true
          }
        }
      ]
    },
    {
      "sectionName": "Impression",
      "fieldType": "textarea",
      "required": true,
      "maxLength": 1000
    }
  ]
}
```

**Report Service:**
```csharp
public class ReportService
{
    public async Task<Report> CreateReportAsync(string studyInstanceUID, int? templateID, int userID)
    {
        ReportTemplate template = null;
        
        if (templateID.HasValue)
        {
            template = await _db.ReportTemplates.FindAsync(templateID.Value);
        }
        else
        {
            // Auto-select template based on study
            var study = await _studyRepository.GetStudyAsync(studyInstanceUID);
            template = await _db.ReportTemplates
                .Where(t => t.Modality == study.Modality && 
                           t.BodyPart == study.BodyPartExamined &&
                           t.IsActive)
                .OrderByDescending(t => t.Version)
                .FirstOrDefaultAsync();
        }
        
        var report = new Report
        {
            StudyInstanceUID = studyInstanceUID,
            TemplateID = template?.TemplateID,
            ReportData = template != null ? InitializeReportData(template) : "{}",
            ReportText = "",
            Status = "DRAFT",
            CreatedByUserID = userID,
            CreatedDate = DateTime.UtcNow
        };
        
        _db.Reports.Add(report);
        await _db.SaveChangesAsync();
        
        return report;
    }
    
    public async Task<Report> UpdateReportAsync(int reportID, Dictionary<string, object> fieldValues)
    {
        var report = await _db.Reports.FindAsync(reportID);
        
        if (report.Status == "FINAL")
            throw new InvalidOperationException("Cannot modify finalized report");
        
        var reportData = JsonSerializer.Deserialize<Dictionary<string, object>>(report.ReportData);
        
        foreach (var kvp in fieldValues)
        {
            reportData[kvp.Key] = kvp.Value;
        }
        
        report.ReportData = JsonSerializer.Serialize(reportData);
        report.ReportText = await RenderReportTextAsync(report);
        
        await _db.SaveChangesAsync();
        
        return report;
    }
    
    public async Task<Report> FinalizeReportAsync(int reportID, int userID)
    {
        var report = await _db.Reports.FindAsync(reportID);
        
        // Validate all required fields are completed
        await ValidateReportAsync(report);
        
        report.Status = "FINAL";
        report.FinalizedByUserID = userID;
        report.FinalizedDate = DateTime.UtcNow;
        
        await _db.SaveChangesAsync();
        
        // Notify RIS
        await _risIntegration.NotifyReportFinalizedAsync(report);
        
        return report;
    }
    
    private async Task<string> RenderReportTextAsync(Report report)
    {
        var template = await _db.ReportTemplates.FindAsync(report.TemplateID);
        var data = JsonSerializer.Deserialize<Dictionary<string, object>>(report.ReportData);
        
        var sb = new StringBuilder();
        var templateStructure = JsonSerializer.Deserialize<ReportTemplateStructure>(template.TemplateJSON);
        
        foreach (var section in templateStructure.Sections)
        {
            sb.AppendLine($"{section.SectionName}:");
            sb.AppendLine(RenderSection(section, data));
            sb.AppendLine();
        }
        
        return sb.ToString();
    }
}
```

#### 11. Monitoring and Observability

**Technology Stack:**
- Prometheus for metrics collection
- Grafana for dashboards
- Application Insights / ELK for logging
- AlertManager for alerting

**Metrics to Collect:**
```csharp
public class PacsMetrics
{
    // System metrics
    public static readonly Counter StudiesReceived = Metrics.CreateCounter(
        "pacs_studies_received_total", 
        "Total number of studies received");
    
    public static readonly Histogram StudyIngestionDuration = Metrics.CreateHistogram(
        "pacs_study_ingestion_duration_seconds",
        "Time to ingest a study");
    
    public static readonly Gauge ActiveUsers = Metrics.CreateGauge(
        "pacs_active_users",
        "Number of currently active users");
    
    public static readonly Counter ApiRequests = Metrics.CreateCounter(
        "pacs_api_requests_total",
        "Total API requests",
        new CounterConfiguration { LabelNames = new[] { "endpoint", "method", "status" } });
    
    public static readonly Histogram ApiResponseTime = Metrics.CreateHistogram(
        "pacs_api_response_time_seconds",
        "API response time",
        new HistogramConfiguration { LabelNames = new[] { "endpoint" } });
    
    public static readonly Gauge StorageUsage = Metrics.CreateGauge(
        "pacs_storage_usage_bytes",
        "Storage usage by tier",
        new GaugeConfiguration { LabelNames = new[] { "tier" } });
    
    public static readonly Counter HL7MessagesProcessed = Metrics.CreateCounter(
        "pacs_hl7_messages_processed_total",
        "HL7 messages processed",
        new CounterConfiguration { LabelNames = new[] { "message_type", "status" } });
}
```

**Prometheus Configuration:**
```yaml
# prometheus.yml
global:
  scrape_interval: 30s
  evaluation_interval: 30s

scrape_configs:
  - job_name: 'pacs-api'
    static_configs:
      - targets: ['localhost:5000']
    metrics_path: '/metrics'
  
  - job_name: 'orthanc'
    static_configs:
      - targets: ['localhost:8042']
    metrics_path: '/tools/metrics-prometheus'
  
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['localhost:9100']

alerting:
  alertmanagers:
    - static_configs:
        - targets: ['localhost:9093']

rule_files:
  - 'alerts.yml'
```

**Alert Rules:**
```yaml
# alerts.yml
groups:
  - name: pacs_alerts
    interval: 30s
    rules:
      - alert: HighDiskUsage
        expr: pacs_storage_usage_bytes / pacs_storage_capacity_bytes > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High disk usage on {{ $labels.tier }} tier"
          description: "Storage usage is {{ $value | humanizePercentage }}"
      
      - alert: StudyIngestionFailed
        expr: rate(pacs_studies_received_total{status="failed"}[5m]) > 0
        for: 5m
        labels:
          severity: critical
        annotations:
          summary: "Study ingestion failures detected"
      
      - alert: HighAPILatency
        expr: histogram_quantile(0.95, pacs_api_response_time_seconds) > 5
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High API latency detected"
          description: "95th percentile response time is {{ $value }}s"
      
      - alert: HL7ProcessingBacklog
        expr: pacs_hl7_messages_pending > 100
        for: 10m
        labels:
          severity: warning
        annotations:
          summary: "HL7 message processing backlog"
```

**Grafana Dashboard JSON (excerpt):**
```json
{
  "dashboard": {
    "title": "PACS System Overview",
    "panels": [
      {
        "title": "Studies Received (24h)",
        "targets": [
          {
            "expr": "sum(increase(pacs_studies_received_total[24h]))"
          }
        ],
        "type": "stat"
      },
      {
        "title": "API Response Time (p95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, rate(pacs_api_response_time_seconds_bucket[5m]))"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Storage Usage by Tier",
        "targets": [
          {
            "expr": "pacs_storage_usage_bytes",
            "legendFormat": "{{ tier }}"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Active Users",
        "targets": [
          {
            "expr": "pacs_active_users"
          }
        ],
        "type": "stat"
      }
    ]
  }
}
```

#### 12. High Availability Setup

**Architecture:**
```
                    ┌─────────────────┐
                    │  Load Balancer  │
                    │   (HAProxy)     │
                    └────────┬────────┘
                             │
              ┌──────────────┼──────────────┐
              │              │              │
       ┌──────▼──────┐ ┌────▼──────┐ ┌────▼──────┐
       │  API Node 1 │ │ API Node 2│ │ API Node 3│
       └──────┬──────┘ └────┬──────┘ └────┬──────┘
              │              │              │
              └──────────────┼──────────────┘
                             │
                    ┌────────▼────────┐
                    │  MSSQL Always   │
                    │  On Availability│
                    │  Group          │
                    │  ┌───────────┐  │
                    │  │ Primary   │  │
                    │  └─────┬─────┘  │
                    │        │         │
                    │  ┌─────▼─────┐  │
                    │  │Secondary 1│  │
                    │  └───────────┘  │
                    │  ┌───────────┐  │
                    │  │Secondary 2│  │
                    │  └───────────┘  │
                    └─────────────────┘
```

**HAProxy Configuration:**
```
# haproxy.cfg
global
    maxconn 4096
    log /dev/log local0

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms
    option httplog
    option dontlognull

frontend pacs_frontend
    bind *:443 ssl crt /etc/haproxy/certs/pacs.pem
    default_backend pacs_api_backend
    
    # Health check endpoint
    acl health_check path /health
    use_backend health_backend if health_check

backend pacs_api_backend
    balance roundrobin
    option httpchk GET /health
    http-check expect status 200
    
    server api1 10.0.1.10:5000 check inter 2000 rise 2 fall 3
    server api2 10.0.1.11:5000 check inter 2000 rise 2 fall 3
    server api3 10.0.1.12:5000 check inter 2000 rise 2 fall 3

backend health_backend
    server health 127.0.0.1:5000

listen stats
    bind *:8404
    stats enable
    stats uri /stats
    stats refresh 30s
```

**MSSQL Always On Configuration:**
```sql
-- On primary replica
CREATE AVAILABILITY GROUP [PACS_AG]
WITH (
    AUTOMATED_BACKUP_PREFERENCE = SECONDARY,
    DB_FAILOVER = ON,
    DTC_SUPPORT = NONE
)
FOR DATABASE [PACS]
REPLICA ON 
    'SQL1' WITH (
        ENDPOINT_URL = 'TCP://sql1.hospital.local:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC
    ),
    'SQL2' WITH (
        ENDPOINT_URL = 'TCP://sql2.hospital.local:5022',
        AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,
        FAILOVER_MODE = AUTOMATIC,
        SEEDING_MODE = AUTOMATIC
    ),
    'SQL3' WITH (
        ENDPOINT_URL = 'TCP://sql3.hospital.local:5022',
        AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT,
        FAILOVER_MODE = MANUAL,
        SEEDING_MODE = AUTOMATIC
    );

-- Create listener
ALTER AVAILABILITY GROUP [PACS_AG]
ADD LISTENER 'PACS_AG_Listener' (
    WITH IP ((N'10.0.1.100', N'255.255.255.0')),
    PORT = 1433
);
```

**Connection String with Failover:**
```json
{
  "ConnectionStrings": {
    "PacsDb": "Server=PACS_AG_Listener;Database=PACS;User Id=pacs_user;Password=***;MultipleActiveResultSets=true;ApplicationIntent=ReadWrite;MultiSubnetFailover=True;ConnectRetryCount=3;ConnectRetryInterval=10;"
  }
}
```

**Health Check Endpoint:**
```csharp
app.MapGet("/health", async (PacsDbContext db) =>
{
    try
    {
        // Check database connectivity
        await db.Database.ExecuteSqlRawAsync("SELECT 1");
        
        // Check Orthanc connectivity
        var orthancHealth = await CheckOrthancHealthAsync();
        
        // Check Redis connectivity
        var redisHealth = await CheckRedisHealthAsync();
        
        if (orthancHealth && redisHealth)
        {
            return Results.Ok(new { status = "healthy", timestamp = DateTime.UtcNow });
        }
        else
        {
            return Results.StatusCode(503);
        }
    }
    catch
    {
        return Results.StatusCode(503);
    }
});
```

#### 13. Backup and Disaster Recovery

**Backup Strategy:**
```
Daily:      Incremental backup of studies (changed files only)
Weekly:     Full backup of database
Monthly:    Full backup of entire system
Retention:  7 years (regulatory requirement)
Location:   Off-site / cloud storage
```

**Database Backup Script:**
```sql
-- Full backup
BACKUP DATABASE [PACS]
TO DISK = 'D:\Backups\PACS_Full_20240101.bak'
WITH COMPRESSION, CHECKSUM, STATS = 10;

-- Differential backup
BACKUP DATABASE [PACS]
TO DISK = 'D:\Backups\PACS_Diff_20240101.bak'
WITH DIFFERENTIAL, COMPRESSION, CHECKSUM;

-- Transaction log backup (every 15 minutes)
BACKUP LOG [PACS]
TO DISK = 'D:\Backups\PACS_Log_20240101_1200.trn'
WITH COMPRESSION, CHECKSUM;
```

**Backup Service:**
```csharp
public class BackupService : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            var now = DateTime.Now;
            
            // Daily incremental backup at 2 AM
            if (now.Hour == 2 && now.Minute == 0)
            {
                await PerformIncrementalBackupAsync();
            }
            
            // Weekly full backup on Sunday at 1 AM
            if (now.DayOfWeek == DayOfWeek.Sunday && now.Hour == 1 && now.Minute == 0)
            {
                await PerformFullBackupAsync();
            }
            
            await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
        }
    }
    
    private async Task PerformIncrementalBackupAsync()
    {
        var backupDate = DateTime.Now.AddDays(-1).Date;
        var studies = await _db.Studies
            .Where(s => s.ReceivedDate >= backupDate)
            .ToListAsync();
        
        foreach (var study in studies)
        {
            var sourcePath = await _storageService.GetStudyPathAsync(study.StudyInstanceUID);
            var backupPath = Path.Combine(_config["Backup:Path"], 
                backupDate.ToString("yyyy-MM-dd"), 
                study.StudyInstanceUID);
            
            await CopyDirectoryAsync(sourcePath, backupPath);
            await VerifyBackupIntegrityAsync(sourcePath, backupPath);
        }
        
        // Upload to cloud
        await UploadToCloudAsync(backupDate);
        
        _logger.LogInformation($"Incremental backup completed: {studies.Count} studies");
    }
    
    private async Task PerformFullBackupAsync()
    {
        // Database backup
        await _db.Database.ExecuteSqlRawAsync(@"
            BACKUP DATABASE [PACS]
            TO DISK = @path
            WITH COMPRESSION, CHECKSUM",
            new SqlParameter("@path", $"D:\\Backups\\PACS_Full_{DateTime.Now:yyyyMMdd}.bak"));
        
        // Verify backup
        await _db.Database.ExecuteSqlRawAsync(@"
            RESTORE VERIFYONLY
            FROM DISK = @path",
            new SqlParameter("@path", $"D:\\Backups\\PACS_Full_{DateTime.Now:yyyyMMdd}.bak"));
        
        _logger.LogInformation("Full database backup completed");
    }
}
```

**Disaster Recovery Procedures:**
```markdown
## RTO: 4 hours | RPO: 24 hours

### Recovery Steps:

1. **Restore Database (30 minutes)**
   - Restore latest full backup
   - Apply differential backup
   - Apply transaction log backups
   - Verify database integrity

2. **Restore Studies (2 hours)**
   - Mount backup storage
   - Copy studies to hot tier
   - Verify DICOM integrity
   - Update storage location metadata

3. **Restore Configuration (30 minutes)**
   - Restore Orthanc configuration
   - Restore API configuration
   - Restore certificates and keys

4. **Validation (1 hour)**
   - Test DICOM connectivity
   - Test API endpoints
   - Test viewer functionality
   - Verify user authentication
   - Check audit logs

5. **Cutover**
   - Update DNS records
   - Notify users
   - Monitor system health
```

**Cloud Backup Integration:**
```csharp
public class CloudBackupService
{
    private readonly BlobServiceClient _blobClient;
    
    public async Task UploadToCloudAsync(DateTime backupDate)
    {
        var containerClient = _blobClient.GetBlobContainerClient("pacs-backups");
        var localPath = Path.Combine(_config["Backup:Path"], backupDate.ToString("yyyy-MM-dd"));
        
        foreach (var file in Directory.GetFiles(localPath, "*", SearchOption.AllDirectories))
        {
            var relativePath = Path.GetRelativePath(localPath, file);
            var blobClient = containerClient.GetBlobClient($"{backupDate:yyyy-MM-dd}/{relativePath}");
            
            using var fileStream = File.OpenRead(file);
            await blobClient.UploadAsync(fileStream, overwrite: false);
        }
        
        // Set lifecycle policy for automatic tiering
        await SetLifecyclePolicyAsync(containerClient);
    }
    
    private async Task SetLifecyclePolicyAsync(BlobContainerClient container)
    {
        // Move to cool tier after 90 days
        // Move to archive tier after 1 year
        // Delete after 7 years
    }
}
```

### Phase 3 Components

#### 14. Multi-Site Architecture

**Design Pattern:** Hub-and-Spoke with Federated Query

**Components:**
- **Global Study Index**: Central registry of study locations
- **Site Router**: Routes queries and studies between sites
- **Replication Service**: Replicates critical studies across sites

**Database Schema:**
```sql
CREATE TABLE Sites (
    SiteID INT PRIMARY KEY IDENTITY,
    SiteName NVARCHAR(100) NOT NULL,
    SiteCode NVARCHAR(10) NOT NULL UNIQUE,
    OrthancURL NVARCHAR(200) NOT NULL,
    APIURL NVARCHAR(200) NOT NULL,
    IsActive BIT DEFAULT 1,
    IsPrimary BIT DEFAULT 0
);

CREATE TABLE GlobalStudyIndex (
    StudyInstanceUID NVARCHAR(100) PRIMARY KEY,
    PrimarySiteID INT NOT NULL,
    PatientID NVARCHAR(50) NOT NULL,
    StudyDate DATE NOT NULL,
    Modality NVARCHAR(10) NOT NULL,
    IndexedDate DATETIME DEFAULT GETDATE(),
    FOREIGN KEY (PrimarySiteID) REFERENCES Sites(SiteID),
    INDEX IX_PatientID (PatientID),
    INDEX IX_StudyDate (StudyDate)
);

CREATE TABLE StudyReplication (
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    SiteID INT NOT NULL,
    ReplicationStatus NVARCHAR(20) DEFAULT 'PENDING',
    ReplicationDate DATETIME NULL,
    PRIMARY KEY (StudyInstanceUID, SiteID),
    FOREIGN KEY (SiteID) REFERENCES Sites(SiteID)
);
```

**Federated Query Service:**
```csharp
public class FederatedQueryService
{
    public async Task<List<StudyResult>> QueryStudiesAsync(StudyQueryParameters query)
    {
        // First check global index
        var studyLocations = await _db.GlobalStudyIndex
            .Where(s => s.PatientID == query.PatientID)
            .ToListAsync();
        
        var results = new List<StudyResult>();
        
        // Query each site in parallel
        var tasks = studyLocations
            .GroupBy(s => s.PrimarySiteID)
            .Select(async group =>
            {
                var site = await _db.Sites.FindAsync(group.Key);
                return await QuerySiteAsync(site, query);
            });
        
        var siteResults = await Task.WhenAll(tasks);
        results.AddRange(siteResults.SelectMany(r => r));
        
        return results;
    }
    
    private async Task<List<StudyResult>> QuerySiteAsync(Site site, StudyQueryParameters query)
    {
        try
        {
            var client = _httpClientFactory.CreateClient();
            client.BaseAddress = new Uri(site.APIURL);
            
            var response = await client.PostAsJsonAsync("/api/studies/query", query);
            response.EnsureSuccessStatusCode();
            
            var results = await response.Content.ReadFromJsonAsync<List<StudyResult>>();
            
            // Tag results with site information
            foreach (var result in results)
            {
                result.SiteID = site.SiteID;
                result.SiteName = site.SiteName;
            }
            
            return results;
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, $"Failed to query site {site.SiteName}");
            return new List<StudyResult>();
        }
    }
}
```

**Study Routing Service:**
```csharp
public class MultiSiteRoutingService
{
    public async Task RouteStudyAsync(string studyInstanceUID, int targetSiteID)
    {
        var sourceSite = await GetStudySiteAsync(studyInstanceUID);
        var targetSite = await _db.Sites.FindAsync(targetSiteID);
        
        // Use DICOM C-MOVE to transfer study
        var orthancClient = new OrthancClient(sourceSite.OrthancURL);
        await orthancClient.MoveStudyAsync(
            studyInstanceUID,
            targetSite.SiteCode,
            targetSite.OrthancURL);
        
        // Update global index
        await _db.StudyReplication.AddAsync(new StudyReplication
        {
            StudyInstanceUID = studyInstanceUID,
            SiteID = targetSiteID,
            ReplicationStatus = "IN_PROGRESS"
        });
        
        await _db.SaveChangesAsync();
    }
}
```

**Automatic Replication Rules:**
```csharp
public class ReplicationRuleEngine
{
    public async Task EvaluateReplicationAsync(string studyInstanceUID)
    {
        var study = await _studyRepository.GetStudyAsync(studyInstanceUID);
        var rules = await _db.ReplicationRules
            .Where(r => r.IsActive)
            .OrderBy(r => r.Priority)
            .ToListAsync();
        
        foreach (var rule in rules)
        {
            if (await RuleMatchesAsync(rule, study))
            {
                foreach (var targetSiteID in rule.TargetSites)
                {
                    await _routingService.RouteStudyAsync(studyInstanceUID, targetSiteID);
                }
                break; // Apply first matching rule only
            }
        }
    }
}
```

#### 15. Cloud/Hybrid Deployment

**Architecture Options:**

**Option 1: Hybrid (Recommended)**
```
On-Premises:
- Orthanc DICOM server (hot storage)
- Local cache
- DICOM modality connectivity

Cloud (Azure):
- .NET API (App Service)
- MSSQL (Azure SQL)
- Cold storage (Blob Storage)
- Redis Cache
- Application Insights
```

**Option 2: Full Cloud**
```
Azure:
- Orthanc (Container Instances / AKS)
- .NET API (App Service / AKS)
- Azure SQL Database
- Blob Storage (all tiers)
- Redis Cache
- Application Gateway
- Azure Monitor
```

**Terraform Configuration (Azure):**
```hcl
# Resource Group
resource "azurerm_resource_group" "pacs" {
  name     = "rg-pacs-prod"
  location = "East US"
}

# Azure SQL Database
resource "azurerm_mssql_server" "pacs" {
  name                         = "sql-pacs-prod"
  resource_group_name          = azurerm_resource_group.pacs.name
  location                     = azurerm_resource_group.pacs.location
  version                      = "12.0"
  administrator_login          = "pacsadmin"
  administrator_login_password = var.sql_admin_password
  
  azuread_administrator {
    login_username = "pacs-admins"
    object_id      = var.admin_group_object_id
  }
}

resource "azurerm_mssql_database" "pacs" {
  name           = "PACS"
  server_id      = azurerm_mssql_server.pacs.id
  sku_name       = "S3"
  max_size_gb    = 250
  
  threat_detection_policy {
    state                      = "Enabled"
    email_account_admins       = "Enabled"
    retention_days             = 30
  }
}

# App Service for API
resource "azurerm_service_plan" "pacs" {
  name                = "asp-pacs-prod"
  resource_group_name = azurerm_resource_group.pacs.name
  location            = azurerm_resource_group.pacs.location
  os_type             = "Linux"
  sku_name            = "P2v3"
}

resource "azurerm_linux_web_app" "pacs_api" {
  name                = "app-pacs-api-prod"
  resource_group_name = azurerm_resource_group.pacs.name
  location            = azurerm_resource_group.pacs.location
  service_plan_id     = azurerm_service_plan.pacs.id
  
  site_config {
    always_on = true
    
    application_stack {
      dotnet_version = "8.0"
    }
    
    health_check_path = "/health"
  }
  
  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Production"
    "ConnectionStrings__PacsDb" = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.db_connection.id})"
  }
  
  identity {
    type = "SystemAssigned"
  }
}

# Storage Account for DICOM images
resource "azurerm_storage_account" "pacs" {
  name                     = "stpacsprod"
  resource_group_name      = azurerm_resource_group.pacs.name
  location                 = azurerm_resource_group.pacs.location
  account_tier             = "Standard"
  account_replication_type = "GRS"
  
  blob_properties {
    versioning_enabled = true
    
    container_delete_retention_policy {
      days = 30
    }
  }
}

resource "azurerm_storage_container" "hot" {
  name                  = "hot-studies"
  storage_account_name  = azurerm_storage_account.pacs.name
  container_access_type = "private"
}

resource "azurerm_storage_container" "cold" {
  name                  = "cold-studies"
  storage_account_name  = azurerm_storage_account.pacs.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "pacs" {
  storage_account_id = azurerm_storage_account.pacs.id
  
  rule {
    name    = "tier-to-cool"
    enabled = true
    
    filters {
      blob_types = ["blockBlob"]
    }
    
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
        tier_to_archive_after_days_since_modification_greater_than = 365
      }
    }
  }
}

# Redis Cache
resource "azurerm_redis_cache" "pacs" {
  name                = "redis-pacs-prod"
  location            = azurerm_resource_group.pacs.location
  resource_group_name = azurerm_resource_group.pacs.name
  capacity            = 2
  family              = "P"
  sku_name            = "Premium"
  enable_non_ssl_port = false
  minimum_tls_version = "1.2"
  
  redis_configuration {
    maxmemory_policy = "allkeys-lru"
  }
}

# Application Insights
resource "azurerm_application_insights" "pacs" {
  name                = "appi-pacs-prod"
  location            = azurerm_resource_group.pacs.location
  resource_group_name = azurerm_resource_group.pacs.name
  application_type    = "web"
  retention_in_days   = 90
}

# Key Vault
resource "azurerm_key_vault" "pacs" {
  name                = "kv-pacs-prod"
  location            = azurerm_resource_group.pacs.location
  resource_group_name = azurerm_resource_group.pacs.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = azurerm_linux_web_app.pacs_api.identity[0].principal_id
    
    secret_permissions = ["Get", "List"]
  }
}
```
