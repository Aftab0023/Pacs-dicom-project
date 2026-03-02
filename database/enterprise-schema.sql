-- Enterprise PACS Schema Extensions
-- Phase 1: Enhanced Modality Worklist, Routing, RBAC, Audit

USE PACSDB;
GO

-- ============================================================================
-- 1. MODALITY WORKLIST TABLES
-- ============================================================================

CREATE TABLE WorklistEntries (
    WorklistID INT PRIMARY KEY IDENTITY(1,1),
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
    Status NVARCHAR(20) DEFAULT 'SCHEDULED', -- SCHEDULED, IN_PROGRESS, COMPLETED, CANCELLED
    CreatedDate DATETIME DEFAULT GETDATE(),
    CompletedDate DATETIME NULL,
    CreatedBy INT NULL,
    CONSTRAINT FK_WorklistEntries_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    INDEX IX_AccessionNumber (AccessionNumber),
    INDEX IX_ScheduledDate (ScheduledProcedureStepStartDate),
    INDEX IX_Modality (Modality),
    INDEX IX_Status (Status),
    INDEX IX_PatientID (PatientID)
);
GO

-- ============================================================================
-- 2. STUDY ROUTING TABLES
-- ============================================================================

CREATE TABLE RoutingRules (
    RuleID INT PRIMARY KEY IDENTITY(1,1),
    RuleName NVARCHAR(100) NOT NULL,
    Priority INT NOT NULL DEFAULT 100,
    IsActive BIT NOT NULL DEFAULT 1,
    Conditions NVARCHAR(MAX) NOT NULL, -- JSON: {modality, bodyPart, timeOfDay, etc}
    Actions NVARCHAR(MAX) NOT NULL,    -- JSON: {assignTo, priority, notify}
    CreatedDate DATETIME DEFAULT GETDATE(),
    ModifiedDate DATETIME DEFAULT GETDATE(),
    CreatedBy INT NULL,
    CONSTRAINT FK_RoutingRules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    INDEX IX_Priority (Priority DESC, IsActive)
);
GO

CREATE TABLE StudyAssignments (
    AssignmentID INT PRIMARY KEY IDENTITY(1,1),
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    AssignedToUserID INT NOT NULL,
    AssignedDate DATETIME DEFAULT GETDATE(),
    AssignedByRuleID INT NULL,
    Priority NVARCHAR(20) DEFAULT 'ROUTINE', -- STAT, URGENT, ROUTINE
    Status NVARCHAR(20) DEFAULT 'PENDING', -- PENDING, IN_PROGRESS, COMPLETED
    NotificationSent BIT DEFAULT 0,
    CONSTRAINT FK_StudyAssignments_User FOREIGN KEY (AssignedToUserID) REFERENCES Users(UserId),
    CONSTRAINT FK_StudyAssignments_Rule FOREIGN KEY (AssignedByRuleID) REFERENCES RoutingRules(RuleID),
    INDEX IX_StudyUID (StudyInstanceUID),
    INDEX IX_AssignedUser (AssignedToUserID, Status),
    INDEX IX_Priority (Priority, Status)
);
GO

-- ============================================================================
-- 3. RBAC PERMISSION TABLES
-- ============================================================================

CREATE TABLE Permissions (
    PermissionID INT PRIMARY KEY IDENTITY(1,1),
    PermissionName NVARCHAR(100) NOT NULL UNIQUE,
    Category NVARCHAR(50) NOT NULL, -- STUDY, ADMIN, REPORT, WORKLIST, ROUTING
    Description NVARCHAR(500),
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE Roles (
    RoleID INT PRIMARY KEY IDENTITY(1,1),
    RoleName NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    IsSystemRole BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE RolePermissions (
    RoleID INT NOT NULL,
    PermissionID INT NOT NULL,
    PRIMARY KEY (RoleID, PermissionID),
    CONSTRAINT FK_RolePermissions_Role FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE,
    CONSTRAINT FK_RolePermissions_Permission FOREIGN KEY (PermissionID) REFERENCES Permissions(PermissionID) ON DELETE CASCADE
);
GO

CREATE TABLE UserRoles (
    UserID INT NOT NULL,
    RoleID INT NOT NULL,
    AssignedDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (UserID, RoleID),
    CONSTRAINT FK_UserRoles_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserRoles_Role FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE
);
GO

CREATE TABLE Departments (
    DepartmentID INT PRIMARY KEY IDENTITY(1,1),
    DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    IsActive BIT DEFAULT 1,
    CreatedDate DATETIME DEFAULT GETDATE()
);
GO

CREATE TABLE UserDepartments (
    UserID INT NOT NULL,
    DepartmentID INT NOT NULL,
    AssignedDate DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (UserID, DepartmentID),
    CONSTRAINT FK_UserDepartments_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE CASCADE,
    CONSTRAINT FK_UserDepartments_Dept FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE CASCADE
);
GO

CREATE TABLE StudyAccessControl (
    AccessID INT PRIMARY KEY IDENTITY(1,1),
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    DepartmentID INT NULL,
    UserID INT NULL,
    AccessType NVARCHAR(20) NOT NULL, -- VIEW, DOWNLOAD, DELETE, SHARE, PRINT
    GrantedBy INT NULL,
    GrantedDate DATETIME DEFAULT GETDATE(),
    ExpiresAt DATETIME NULL,
    CONSTRAINT FK_StudyAccess_Dept FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
    CONSTRAINT FK_StudyAccess_User FOREIGN KEY (UserID) REFERENCES Users(UserId),
    CONSTRAINT FK_StudyAccess_GrantedBy FOREIGN KEY (GrantedBy) REFERENCES Users(UserId),
    INDEX IX_StudyUID (StudyInstanceUID),
    INDEX IX_UserAccess (UserID, AccessType),
    INDEX IX_DeptAccess (DepartmentID, AccessType)
);
GO

-- ============================================================================
-- 4. ENHANCED AUDIT LOGGING
-- ============================================================================

CREATE TABLE AuditLogsEnhanced (
    AuditID BIGINT PRIMARY KEY IDENTITY(1,1),
    EventType NVARCHAR(50) NOT NULL,
    EventCategory NVARCHAR(50) NOT NULL, -- AUTH, STUDY_ACCESS, CONFIG, DICOM, WORKLIST, ROUTING
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
    CONSTRAINT FK_AuditEnhanced_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE SET NULL,
    INDEX IX_Timestamp (Timestamp DESC),
    INDEX IX_UserID (UserID, Timestamp),
    INDEX IX_EventType (EventType, Timestamp),
    INDEX IX_ResourceID (ResourceID, Timestamp),
    INDEX IX_EventCategory (EventCategory, Timestamp)
);
GO

CREATE TABLE AuditLogArchive (
    AuditID BIGINT PRIMARY KEY,
    EventType NVARCHAR(50) NOT NULL,
    EventCategory NVARCHAR(50) NOT NULL,
    Timestamp DATETIME2 NOT NULL,
    UserID INT NULL,
    Username NVARCHAR(100),
    IPAddress NVARCHAR(50),
    UserAgent NVARCHAR(500),
    Action NVARCHAR(100) NOT NULL,
    ResourceType NVARCHAR(50),
    ResourceID NVARCHAR(200),
    Success BIT NOT NULL,
    ErrorMessage NVARCHAR(MAX),
    AdditionalData NVARCHAR(MAX),
    Signature NVARCHAR(500),
    ArchivedDate DATETIME2 DEFAULT SYSUTCDATETIME(),
    INDEX IX_Archive_Timestamp (Timestamp DESC),
    INDEX IX_Archive_UserID (UserID, Timestamp)
);
GO

-- ============================================================================
-- 5. SEED DATA - PERMISSIONS
-- ============================================================================

-- Insert Permissions
INSERT INTO Permissions (PermissionName, Category, Description) VALUES
-- Study Permissions
('study.view.all', 'STUDY', 'View all studies in the system'),
('study.view.department', 'STUDY', 'View studies in user''s department'),
('study.view.assigned', 'STUDY', 'View only assigned studies'),
('study.download', 'STUDY', 'Download studies'),
('study.delete', 'STUDY', 'Delete studies'),
('study.share.external', 'STUDY', 'Share studies externally'),
('study.print', 'STUDY', 'Print studies'),
('study.export', 'STUDY', 'Export studies'),

-- Report Permissions
('report.create', 'REPORT', 'Create reports'),
('report.edit.own', 'REPORT', 'Edit own reports'),
('report.edit.all', 'REPORT', 'Edit all reports'),
('report.finalize', 'REPORT', 'Finalize reports'),
('report.delete', 'REPORT', 'Delete reports'),
('report.view.all', 'REPORT', 'View all reports'),

-- Worklist Permissions
('worklist.view', 'WORKLIST', 'View worklist'),
('worklist.create', 'WORKLIST', 'Create worklist entries'),
('worklist.edit', 'WORKLIST', 'Edit worklist entries'),
('worklist.delete', 'WORKLIST', 'Delete worklist entries'),
('worklist.assign', 'WORKLIST', 'Assign studies from worklist'),

-- Routing Permissions
('routing.view', 'ROUTING', 'View routing rules'),
('routing.create', 'ROUTING', 'Create routing rules'),
('routing.edit', 'ROUTING', 'Edit routing rules'),
('routing.delete', 'ROUTING', 'Delete routing rules'),

-- Admin Permissions
('admin.users.manage', 'ADMIN', 'Manage users'),
('admin.roles.manage', 'ADMIN', 'Manage roles and permissions'),
('admin.departments.manage', 'ADMIN', 'Manage departments'),
('admin.system.configure', 'ADMIN', 'Configure system settings'),
('admin.audit.view', 'ADMIN', 'View audit logs');
GO

-- Insert Roles
INSERT INTO Roles (RoleName, Description, IsSystemRole) VALUES
('SuperAdmin', 'Full system access', 1),
('Admin', 'Administrative access', 1),
('Radiologist', 'Radiologist with reporting capabilities', 1),
('Technologist', 'Radiology technologist', 1),
('Referrer', 'Referring physician', 1),
('Scheduler', 'Scheduling staff', 1);
GO

-- Assign Permissions to SuperAdmin (all permissions)
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Roles r
CROSS JOIN Permissions p
WHERE r.RoleName = 'SuperAdmin';
GO

-- Assign Permissions to Admin
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Roles r
CROSS JOIN Permissions p
WHERE r.RoleName = 'Admin'
AND p.PermissionName IN (
    'study.view.all', 'study.download', 'study.print', 'study.export',
    'report.view.all', 'report.create', 'report.edit.all', 'report.finalize',
    'worklist.view', 'worklist.create', 'worklist.edit', 'worklist.assign',
    'routing.view', 'routing.create', 'routing.edit',
    'admin.users.manage', 'admin.departments.manage', 'admin.audit.view'
);
GO

-- Assign Permissions to Radiologist
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Roles r
CROSS JOIN Permissions p
WHERE r.RoleName = 'Radiologist'
AND p.PermissionName IN (
    'study.view.assigned', 'study.view.department', 'study.download', 'study.print',
    'report.create', 'report.edit.own', 'report.finalize', 'report.view.all',
    'worklist.view'
);
GO

-- Assign Permissions to Technologist
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Roles r
CROSS JOIN Permissions p
WHERE r.RoleName = 'Technologist'
AND p.PermissionName IN (
    'study.view.department', 'worklist.view', 'worklist.create', 'worklist.edit'
);
GO

-- Assign Permissions to Scheduler
INSERT INTO RolePermissions (RoleID, PermissionID)
SELECT r.RoleID, p.PermissionID
FROM Roles r
CROSS JOIN Permissions p
WHERE r.RoleName = 'Scheduler'
AND p.PermissionName IN (
    'worklist.view', 'worklist.create', 'worklist.edit', 'worklist.delete'
);
GO

-- Insert Default Departments
INSERT INTO Departments (DepartmentName, Description) VALUES
('Radiology', 'General Radiology Department'),
('Cardiology', 'Cardiac Imaging'),
('Neurology', 'Neurological Imaging'),
('Emergency', 'Emergency Department Imaging');
GO

-- Assign existing users to roles
-- Update existing admin user
INSERT INTO UserRoles (UserID, RoleID)
SELECT u.UserId, r.RoleID
FROM Users u
CROSS JOIN Roles r
WHERE u.Username = 'admin' AND r.RoleName = 'SuperAdmin';
GO

-- Update existing radiologist user
INSERT INTO UserRoles (UserID, RoleID)
SELECT u.UserId, r.RoleID
FROM Users u
CROSS JOIN Roles r
WHERE u.Username = 'radiologist' AND r.RoleName = 'Radiologist';
GO

-- Assign users to default department (Radiology)
INSERT INTO UserDepartments (UserID, DepartmentID)
SELECT u.UserId, d.DepartmentID
FROM Users u
CROSS JOIN Departments d
WHERE d.DepartmentName = 'Radiology';
GO

-- ============================================================================
-- 6. STORED PROCEDURES
-- ============================================================================

-- Procedure to get user permissions
CREATE PROCEDURE sp_GetUserPermissions
    @UserID INT
AS
BEGIN
    SELECT DISTINCT p.PermissionName, p.Category, p.Description
    FROM Permissions p
    INNER JOIN RolePermissions rp ON p.PermissionID = rp.PermissionID
    INNER JOIN UserRoles ur ON rp.RoleID = ur.RoleID
    WHERE ur.UserID = @UserID;
END;
GO

-- Procedure to check if user has permission
CREATE PROCEDURE sp_CheckUserPermission
    @UserID INT,
    @PermissionName NVARCHAR(100)
AS
BEGIN
    SELECT CASE WHEN EXISTS (
        SELECT 1
        FROM Permissions p
        INNER JOIN RolePermissions rp ON p.PermissionID = rp.PermissionID
        INNER JOIN UserRoles ur ON rp.RoleID = ur.RoleID
        WHERE ur.UserID = @UserID AND p.PermissionName = @PermissionName
    ) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END AS HasPermission;
END;
GO

-- Procedure to get active worklist entries
CREATE PROCEDURE sp_GetWorklistEntries
    @Modality NVARCHAR(10) = NULL,
    @Status NVARCHAR(20) = NULL,
    @StartDate DATETIME = NULL,
    @EndDate DATETIME = NULL
AS
BEGIN
    SELECT 
        WorklistID, AccessionNumber, PatientID, PatientName,
        PatientBirthDate, PatientSex, ScheduledProcedureStepStartDate,
        ScheduledProcedureStepStartTime, Modality, ScheduledStationAETitle,
        ScheduledProcedureStepDescription, StudyInstanceUID,
        RequestedProcedureID, ReferringPhysicianName, Status,
        CreatedDate, CompletedDate
    FROM WorklistEntries
    WHERE (@Modality IS NULL OR Modality = @Modality)
    AND (@Status IS NULL OR Status = @Status)
    AND (@StartDate IS NULL OR ScheduledProcedureStepStartDate >= @StartDate)
    AND (@EndDate IS NULL OR ScheduledProcedureStepStartDate <= @EndDate)
    ORDER BY ScheduledProcedureStepStartDate, ScheduledProcedureStepStartTime;
END;
GO

PRINT 'Enterprise schema created successfully!';
GO
