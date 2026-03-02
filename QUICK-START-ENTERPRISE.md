# 🚀 Quick Start: Enterprise PACS

## System is Running!

All services are up and operational with enterprise features enabled.

---

## 📍 Access Points

### Frontend Application
**URL:** http://localhost:3000

**Login Credentials:**
- Email: `admin@pacs.local`
- Password: `Admin123!`

### API Documentation
**URL:** http://localhost:5000/swagger

### Orthanc DICOM Server
**URL:** http://localhost:8042
- Username: `orthanc`
- Password: `orthanc`

---

## ✨ New Features You Can Try

### 1. Share OHIF Viewer with Patient 📧

**Steps:**
1. Login to http://localhost:3000
2. Go to "Worklist"
3. Click "View" on any study
4. Click "Share with Patient" button (purple button)
5. Enter patient email
6. Add optional message
7. Click "Send to Patient"

**What happens:**
- System generates a secure share link
- Link expires in 24 hours (configurable)
- Patient receives email with link to view study in OHIF viewer
- No login required for patient

**Note:** Backend implementation needed for email sending. Frontend UI is complete!

---

### 2. View Enterprise Database Tables 🗄️

**Check what's been added:**
```powershell
# Connect to SQL Server
docker exec -it pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -d PACSDB

# List all tables
SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' ORDER BY TABLE_NAME;
GO

# View permissions
SELECT * FROM Permissions;
GO

# View roles
SELECT * FROM Roles;
GO

# View departments
SELECT * FROM Departments;
GO

# Exit
EXIT
```

---

### 3. Test Worklist Management (Frontend Ready) 📅

**Access:** http://localhost:3000/worklist-management

**Features:**
- Schedule procedures for modalities
- Filter by modality, status, date
- View scheduled procedures
- Delete entries

**Note:** Backend API endpoints needed. Frontend UI is complete!

---

## 🔧 Manage Docker Services

### View Logs
```powershell
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f pacs-api
docker-compose logs -f pacs-sqlserver
docker-compose logs -f orthanc
docker-compose logs -f pacs-frontend
```

### Restart Services
```powershell
# Restart all
docker-compose restart

# Restart specific service
docker-compose restart pacs-api
```

### Stop System
```powershell
docker-compose down
```

### Start System
```powershell
docker-compose up -d
```

### Rebuild After Code Changes
```powershell
docker-compose down
docker-compose up -d --build
```

---

## 📊 Database Schema

### New Enterprise Tables (13)
1. `WorklistEntries` - Modality worklist scheduling
2. `RoutingRules` - Study routing rules
3. `StudyAssignments` - Study assignments
4. `Permissions` - 28 granular permissions
5. `Roles` - 6 default roles
6. `RolePermissions` - Role-permission mapping
7. `UserRoles` - User-role assignments
8. `Departments` - 4 departments
9. `UserDepartments` - User-department mapping
10. `StudyAccessControl` - Explicit study access
11. `AuditLogsEnhanced` - Enhanced audit logging
12. `AuditLogArchive` - Archived logs

### Existing Tables (7)
- Users, Patients, Studies, Series, Instances, Reports, AuditLogs

---

## 🎯 What Works Now

### ✅ Fully Functional
- User authentication (JWT)
- Study viewing (OHIF integration)
- Report creation
- Worklist management (basic)
- Patient demographics
- Study metadata

### ✅ Frontend Ready (Backend Needed)
- OHIF viewer patient sharing
- Worklist management UI
- Enterprise API integration
- Permission checking
- Audit log viewing

### 🔄 Database Ready (Implementation Needed)
- Modality worklist (MWL)
- Study routing rules
- Granular RBAC permissions
- Enhanced audit logging
- Department-based access

---

## 🚀 Next Steps

### For Developers

**1. Implement Backend Services**
```
backend/PACS.Infrastructure/Services/
├── WorklistService.cs
├── RoutingService.cs
├── PermissionService.cs
├── AuditServiceEnhanced.cs
└── ViewerSharingService.cs
```

**2. Create API Controllers**
```
backend/PACS.API/Controllers/
├── WorklistController.cs
├── RoutingController.cs
├── PermissionController.cs
├── RoleController.cs
├── DepartmentController.cs
├── AuditController.cs
└── ViewerSharingController.cs
```

**3. Add Middleware**
```
backend/PACS.API/Middleware/
├── AuthorizationMiddleware.cs
└── AuditMiddleware.cs
```

**4. Update DbContext**
Add new entities to `PACSDbContext.cs`

---

## 📧 Patient Sharing Flow (When Complete)

### Radiologist Side:
1. View study in OHIF
2. Click "Share with Patient"
3. Enter patient email
4. System generates secure token
5. Email sent to patient

### Patient Side:
1. Receives email with link
2. Clicks link (no login required)
3. Views study in OHIF viewer
4. Link expires after 24 hours

### Security:
- Unique token per share
- Configurable expiration (1-168 hours)
- Can revoke access anytime
- All access logged in audit

---

## 🔐 Permissions System

### Permission Categories
- **STUDY** (8 permissions)
- **REPORT** (6 permissions)
- **WORKLIST** (5 permissions)
- **ROUTING** (4 permissions)
- **ADMIN** (5 permissions)

### Default Roles
1. **SuperAdmin** - All permissions
2. **Admin** - Most permissions except system config
3. **Radiologist** - Study viewing, reporting
4. **Technologist** - Worklist management
5. **Referrer** - View studies and reports
6. **Scheduler** - Worklist scheduling

### Check User Permissions
```sql
-- Get all permissions for a user
EXEC sp_GetUserPermissions @UserID = 1;

-- Check specific permission
EXEC sp_CheckUserPermission @UserID = 1, @PermissionName = 'study.view.all';
```

---

## 📝 Troubleshooting

### Services Not Starting
```powershell
# Check status
docker-compose ps

# View logs
docker-compose logs

# Restart
docker-compose restart
```

### Database Connection Issues
```powershell
# Check SQL Server health
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -Q "SELECT @@VERSION"

# Reinitialize database
.\init-enterprise-db.ps1
```

### Frontend Not Loading
```powershell
# Check frontend logs
docker-compose logs pacs-frontend

# Rebuild frontend
docker-compose up -d --build pacs-frontend
```

### API Not Responding
```powershell
# Check API logs
docker-compose logs pacs-api

# Restart API
docker-compose restart pacs-api
```

---

## 📚 Documentation

- **Full Architecture:** `ARCHITECTURE.md`
- **All Features:** `FEATURES.md`
- **Implementation Status:** `ENTERPRISE-IMPLEMENTATION-STATUS.md`
- **Deployment Complete:** `ENTERPRISE-DEPLOYMENT-COMPLETE.md`
- **Deployment Guide:** `DEPLOYMENT.md`

---

## 🎉 You're All Set!

Your Enterprise PACS is running with 20-25% of enterprise features implemented end-to-end.

**What's Working:**
- ✅ All basic PACS functionality
- ✅ Enterprise database schema
- ✅ Frontend UI for new features
- ✅ OHIF viewer patient sharing (UI ready)

**What's Next:**
- Implement backend services
- Create API controllers
- Add middleware
- Test end-to-end

**Estimated Time:** 3-4 weeks to full production

---

**Happy Coding! 🚀**
