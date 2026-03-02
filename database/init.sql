-- PACS Database Initialization Script
USE PACSDB;
GO

-- Create Users table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Users')
BEGIN
    CREATE TABLE Users (
        UserId INT PRIMARY KEY IDENTITY(1,1),
        Username NVARCHAR(100) NOT NULL UNIQUE,
        Email NVARCHAR(200) NOT NULL UNIQUE,
        PasswordHash NVARCHAR(500) NOT NULL,
        Role NVARCHAR(50) NOT NULL,
        FirstName NVARCHAR(100),
        LastName NVARCHAR(100),
        IsActive BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        LastLoginAt DATETIME2 NULL
    );
    
    CREATE INDEX IX_Users_Email ON Users(Email);
    CREATE INDEX IX_Users_Username ON Users(Username);
END
GO

-- Create Patients table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Patients')
BEGIN
    CREATE TABLE Patients (
        PatientId INT PRIMARY KEY IDENTITY(1,1),
        MRN NVARCHAR(50) NOT NULL UNIQUE,
        FirstName NVARCHAR(100) NOT NULL,
        LastName NVARCHAR(100) NOT NULL,
        DateOfBirth DATETIME2 NOT NULL,
        Gender NVARCHAR(10),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NULL
    );
    
    CREATE INDEX IX_Patients_MRN ON Patients(MRN);
END
GO

-- Create Studies table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Studies')
BEGIN
    CREATE TABLE Studies (
        StudyId INT PRIMARY KEY IDENTITY(1,1),
        StudyInstanceUID NVARCHAR(200) NOT NULL UNIQUE,
        PatientId INT NOT NULL,
        StudyDate DATETIME2 NOT NULL,
        Modality NVARCHAR(50),
        Description NVARCHAR(500),
        AccessionNumber NVARCHAR(50),
        OrthancStudyId NVARCHAR(100),
        Status NVARCHAR(50) NOT NULL DEFAULT 'Pending',
        AssignedRadiologistId INT NULL,
        IsPriority BIT NOT NULL DEFAULT 0,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NULL,
        CONSTRAINT FK_Studies_Patients FOREIGN KEY (PatientId) REFERENCES Patients(PatientId),
        CONSTRAINT FK_Studies_Users FOREIGN KEY (AssignedRadiologistId) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_Studies_StudyInstanceUID ON Studies(StudyInstanceUID);
    CREATE INDEX IX_Studies_StudyDate ON Studies(StudyDate);
    CREATE INDEX IX_Studies_Status ON Studies(Status);
    CREATE INDEX IX_Studies_AccessionNumber ON Studies(AccessionNumber);
    CREATE INDEX IX_Studies_PatientId ON Studies(PatientId);
END
GO

-- Create Series table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Series')
BEGIN
    CREATE TABLE Series (
        SeriesId INT PRIMARY KEY IDENTITY(1,1),
        SeriesInstanceUID NVARCHAR(200) NOT NULL UNIQUE,
        StudyId INT NOT NULL,
        Modality NVARCHAR(50),
        BodyPart NVARCHAR(100),
        SeriesNumber INT NOT NULL,
        Description NVARCHAR(500),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Series_Studies FOREIGN KEY (StudyId) REFERENCES Studies(StudyId) ON DELETE CASCADE
    );
    
    CREATE INDEX IX_Series_SeriesInstanceUID ON Series(SeriesInstanceUID);
    CREATE INDEX IX_Series_StudyId ON Series(StudyId);
END
GO

-- Create Instances table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Instances')
BEGIN
    CREATE TABLE Instances (
        InstanceId INT PRIMARY KEY IDENTITY(1,1),
        SOPInstanceUID NVARCHAR(200) NOT NULL UNIQUE,
        SeriesId INT NOT NULL,
        InstanceNumber INT NOT NULL,
        FilePath NVARCHAR(1000),
        FileSize BIGINT NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_Instances_Series FOREIGN KEY (SeriesId) REFERENCES Series(SeriesId) ON DELETE CASCADE
    );
    
    CREATE INDEX IX_Instances_SOPInstanceUID ON Instances(SOPInstanceUID);
    CREATE INDEX IX_Instances_SeriesId ON Instances(SeriesId);
END
GO

-- Create Reports table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Reports')
BEGIN
    CREATE TABLE Reports (
        ReportId INT PRIMARY KEY IDENTITY(1,1),
        StudyId INT NOT NULL,
        RadiologistId INT NOT NULL,
        Status NVARCHAR(50) NOT NULL DEFAULT 'Draft',
        ReportText NVARCHAR(MAX),
        Findings NVARCHAR(MAX),
        Impression NVARCHAR(MAX),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        FinalizedAt DATETIME2 NULL,
        DigitalSignature NVARCHAR(1000) NULL,
        CONSTRAINT FK_Reports_Studies FOREIGN KEY (StudyId) REFERENCES Studies(StudyId) ON DELETE CASCADE,
        CONSTRAINT FK_Reports_Users FOREIGN KEY (RadiologistId) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_Reports_StudyId ON Reports(StudyId);
    CREATE INDEX IX_Reports_Status ON Reports(Status);
END
GO

-- Create AuditLogs table
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLogs')
BEGIN
    CREATE TABLE AuditLogs (
        AuditLogId INT PRIMARY KEY IDENTITY(1,1),
        UserId INT NULL,
        Action NVARCHAR(100),
        EntityType NVARCHAR(100),
        EntityId NVARCHAR(100),
        Details NVARCHAR(MAX),
        IpAddress NVARCHAR(50),
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        CONSTRAINT FK_AuditLogs_Users FOREIGN KEY (UserId) REFERENCES Users(UserId) ON DELETE SET NULL
    );
    
    CREATE INDEX IX_AuditLogs_CreatedAt ON AuditLogs(CreatedAt);
    CREATE INDEX IX_AuditLogs_UserId ON AuditLogs(UserId);
END
GO

-- Insert default users (passwords are BCrypt hashed)
-- Password for both users: admin123
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'admin@pacs.local')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive, CreatedAt)
    VALUES 
    ('admin', 'admin@pacs.local', '$2a$11$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vYGCYQC/ohDgXQvQvfKBZu', 'Admin', 'System', 'Administrator', 1, GETUTCDATE()),
    ('radiologist', 'radiologist@pacs.local', '$2a$11$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vYGCYQC/ohDgXQvQvfKBZu', 'Radiologist', 'John', 'Radiologist', 1, GETUTCDATE());
END
GO

PRINT 'Database initialization completed successfully!';
GO

-- ============================================================================
-- ENTERPRISE FEATURES - Phase 1
-- ============================================================================

-- 1. MODALITY WORKLIST TABLES
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'WorklistEntries')
BEGIN
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
        Status NVARCHAR(20) DEFAULT 'SCHEDULED',
        CreatedDate DATETIME DEFAULT GETDATE(),
        CompletedDate DATETIME NULL,
        CreatedBy INT NULL,
        CONSTRAINT FK_WorklistEntries_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_WorklistEntries_AccessionNumber ON WorklistEntries(AccessionNumber);
    CREATE INDEX IX_WorklistEntries_ScheduledDate ON WorklistEntries(ScheduledProcedureStepStartDate);
    CREATE INDEX IX_WorklistEntries_Modality ON WorklistEntries(Modality);
    CREATE INDEX IX_WorklistEntries_Status ON WorklistEntries(Status);
    CREATE INDEX IX_WorklistEntries_PatientID ON WorklistEntries(PatientID);
END
GO

-- 2. STUDY ROUTING TABLES
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RoutingRules')
BEGIN
    CREATE TABLE RoutingRules (
        RuleID INT PRIMARY KEY IDENTITY(1,1),
        RuleName NVARCHAR(100) NOT NULL,
        Priority INT NOT NULL DEFAULT 100,
        IsActive BIT NOT NULL DEFAULT 1,
        Conditions NVARCHAR(MAX) NOT NULL,
        Actions NVARCHAR(MAX) NOT NULL,
        CreatedDate DATETIME DEFAULT GETDATE(),
        ModifiedDate DATETIME DEFAULT GETDATE(),
        CreatedBy INT NULL,
        CONSTRAINT FK_RoutingRules_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_RoutingRules_Priority ON RoutingRules(Priority DESC, IsActive);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StudyAssignments')
BEGIN
    CREATE TABLE StudyAssignments (
        AssignmentID INT PRIMARY KEY IDENTITY(1,1),
        StudyInstanceUID NVARCHAR(100) NOT NULL,
        AssignedToUserID INT NOT NULL,
        AssignedDate DATETIME DEFAULT GETDATE(),
        AssignedByRuleID INT NULL,
        Priority NVARCHAR(20) DEFAULT 'ROUTINE',
        Status NVARCHAR(20) DEFAULT 'PENDING',
        NotificationSent BIT DEFAULT 0,
        CONSTRAINT FK_StudyAssignments_User FOREIGN KEY (AssignedToUserID) REFERENCES Users(UserId),
        CONSTRAINT FK_StudyAssignments_Rule FOREIGN KEY (AssignedByRuleID) REFERENCES RoutingRules(RuleID)
    );
    
    CREATE INDEX IX_StudyAssignments_StudyUID ON StudyAssignments(StudyInstanceUID);
    CREATE INDEX IX_StudyAssignments_AssignedUser ON StudyAssignments(AssignedToUserID, Status);
    CREATE INDEX IX_StudyAssignments_Priority ON StudyAssignments(Priority, Status);
END
GO

-- 3. RBAC PERMISSION TABLES
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Permissions')
BEGIN
    CREATE TABLE Permissions (
        PermissionID INT PRIMARY KEY IDENTITY(1,1),
        PermissionName NVARCHAR(100) NOT NULL UNIQUE,
        Category NVARCHAR(50) NOT NULL,
        Description NVARCHAR(500),
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Roles')
BEGIN
    CREATE TABLE Roles (
        RoleID INT PRIMARY KEY IDENTITY(1,1),
        RoleName NVARCHAR(50) NOT NULL UNIQUE,
        Description NVARCHAR(500),
        IsSystemRole BIT DEFAULT 0,
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'RolePermissions')
BEGIN
    CREATE TABLE RolePermissions (
        RoleID INT NOT NULL,
        PermissionID INT NOT NULL,
        PRIMARY KEY (RoleID, PermissionID),
        CONSTRAINT FK_RolePermissions_Role FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE,
        CONSTRAINT FK_RolePermissions_Permission FOREIGN KEY (PermissionID) REFERENCES Permissions(PermissionID) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserRoles')
BEGIN
    CREATE TABLE UserRoles (
        UserID INT NOT NULL,
        RoleID INT NOT NULL,
        AssignedDate DATETIME DEFAULT GETDATE(),
        PRIMARY KEY (UserID, RoleID),
        CONSTRAINT FK_UserRoles_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE CASCADE,
        CONSTRAINT FK_UserRoles_Role FOREIGN KEY (RoleID) REFERENCES Roles(RoleID) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'Departments')
BEGIN
    CREATE TABLE Departments (
        DepartmentID INT PRIMARY KEY IDENTITY(1,1),
        DepartmentName NVARCHAR(100) NOT NULL UNIQUE,
        Description NVARCHAR(500),
        IsActive BIT DEFAULT 1,
        CreatedDate DATETIME DEFAULT GETDATE()
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'UserDepartments')
BEGIN
    CREATE TABLE UserDepartments (
        UserID INT NOT NULL,
        DepartmentID INT NOT NULL,
        AssignedDate DATETIME DEFAULT GETDATE(),
        PRIMARY KEY (UserID, DepartmentID),
        CONSTRAINT FK_UserDepartments_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE CASCADE,
        CONSTRAINT FK_UserDepartments_Dept FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID) ON DELETE CASCADE
    );
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'StudyAccessControl')
BEGIN
    CREATE TABLE StudyAccessControl (
        AccessID INT PRIMARY KEY IDENTITY(1,1),
        StudyInstanceUID NVARCHAR(100) NOT NULL,
        DepartmentID INT NULL,
        UserID INT NULL,
        AccessType NVARCHAR(20) NOT NULL,
        GrantedBy INT NULL,
        GrantedDate DATETIME DEFAULT GETDATE(),
        ExpiresAt DATETIME NULL,
        CONSTRAINT FK_StudyAccess_Dept FOREIGN KEY (DepartmentID) REFERENCES Departments(DepartmentID),
        CONSTRAINT FK_StudyAccess_User FOREIGN KEY (UserID) REFERENCES Users(UserId),
        CONSTRAINT FK_StudyAccess_GrantedBy FOREIGN KEY (GrantedBy) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_StudyAccess_StudyUID ON StudyAccessControl(StudyInstanceUID);
    CREATE INDEX IX_StudyAccess_UserAccess ON StudyAccessControl(UserID, AccessType);
    CREATE INDEX IX_StudyAccess_DeptAccess ON StudyAccessControl(DepartmentID, AccessType);
END
GO

-- 4. ENHANCED AUDIT LOGGING
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'AuditLogsEnhanced')
BEGIN
    CREATE TABLE AuditLogsEnhanced (
        AuditID BIGINT PRIMARY KEY IDENTITY(1,1),
        EventType NVARCHAR(50) NOT NULL,
        EventCategory NVARCHAR(50) NOT NULL,
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
        AdditionalData NVARCHAR(MAX),
        Signature NVARCHAR(500),
        CONSTRAINT FK_AuditEnhanced_User FOREIGN KEY (UserID) REFERENCES Users(UserId) ON DELETE SET NULL
    );
    
    CREATE INDEX IX_AuditEnhanced_Timestamp ON AuditLogsEnhanced(Timestamp DESC);
    CREATE INDEX IX_AuditEnhanced_UserID ON AuditLogsEnhanced(UserID, Timestamp);
    CREATE INDEX IX_AuditEnhanced_EventType ON AuditLogsEnhanced(EventType, Timestamp);
    CREATE INDEX IX_AuditEnhanced_ResourceID ON AuditLogsEnhanced(ResourceID, Timestamp);
    CREATE INDEX IX_AuditEnhanced_EventCategory ON AuditLogsEnhanced(EventCategory, Timestamp);
END
GO

-- 5. SEED DATA - PERMISSIONS
IF NOT EXISTS (SELECT * FROM Permissions WHERE PermissionName = 'study.view.all')
BEGIN
    INSERT INTO Permissions (PermissionName, Category, Description) VALUES
    ('study.view.all', 'STUDY', 'View all studies in the system'),
    ('study.view.department', 'STUDY', 'View studies in user''s department'),
    ('study.view.assigned', 'STUDY', 'View only assigned studies'),
    ('study.download', 'STUDY', 'Download studies'),
    ('study.delete', 'STUDY', 'Delete studies'),
    ('study.share.external', 'STUDY', 'Share studies externally'),
    ('study.print', 'STUDY', 'Print studies'),
    ('study.export', 'STUDY', 'Export studies'),
    ('report.create', 'REPORT', 'Create reports'),
    ('report.edit.own', 'REPORT', 'Edit own reports'),
    ('report.edit.all', 'REPORT', 'Edit all reports'),
    ('report.finalize', 'REPORT', 'Finalize reports'),
    ('report.delete', 'REPORT', 'Delete reports'),
    ('report.view.all', 'REPORT', 'View all reports'),
    ('worklist.view', 'WORKLIST', 'View worklist'),
    ('worklist.create', 'WORKLIST', 'Create worklist entries'),
    ('worklist.edit', 'WORKLIST', 'Edit worklist entries'),
    ('worklist.delete', 'WORKLIST', 'Delete worklist entries'),
    ('worklist.assign', 'WORKLIST', 'Assign studies from worklist'),
    ('routing.view', 'ROUTING', 'View routing rules'),
    ('routing.create', 'ROUTING', 'Create routing rules'),
    ('routing.edit', 'ROUTING', 'Edit routing rules'),
    ('routing.delete', 'ROUTING', 'Delete routing rules'),
    ('admin.users.manage', 'ADMIN', 'Manage users'),
    ('admin.roles.manage', 'ADMIN', 'Manage roles and permissions'),
    ('admin.departments.manage', 'ADMIN', 'Manage departments'),
    ('admin.system.configure', 'ADMIN', 'Configure system settings'),
    ('admin.audit.view', 'ADMIN', 'View audit logs');
END
GO

-- Insert Roles
IF NOT EXISTS (SELECT * FROM Roles WHERE RoleName = 'SuperAdmin')
BEGIN
    INSERT INTO Roles (RoleName, Description, IsSystemRole) VALUES
    ('SuperAdmin', 'Full system access', 1),
    ('Admin', 'Administrative access', 1),
    ('Radiologist', 'Radiologist with reporting capabilities', 1),
    ('Technologist', 'Radiology technologist', 1),
    ('Referrer', 'Referring physician', 1),
    ('Scheduler', 'Scheduling staff', 1);
END
GO

-- Assign Permissions to SuperAdmin
IF NOT EXISTS (SELECT * FROM RolePermissions rp INNER JOIN Roles r ON rp.RoleID = r.RoleID WHERE r.RoleName = 'SuperAdmin')
BEGIN
    INSERT INTO RolePermissions (RoleID, PermissionID)
    SELECT r.RoleID, p.PermissionID
    FROM Roles r
    CROSS JOIN Permissions p
    WHERE r.RoleName = 'SuperAdmin';
END
GO

-- Insert Default Departments
IF NOT EXISTS (SELECT * FROM Departments WHERE DepartmentName = 'Radiology')
BEGIN
    INSERT INTO Departments (DepartmentName, Description) VALUES
    ('Radiology', 'General Radiology Department'),
    ('Cardiology', 'Cardiac Imaging'),
    ('Neurology', 'Neurological Imaging'),
    ('Emergency', 'Emergency Department Imaging');
END
GO

-- Assign existing users to roles
IF NOT EXISTS (SELECT * FROM UserRoles ur INNER JOIN Users u ON ur.UserID = u.UserId WHERE u.Username = 'admin')
BEGIN
    INSERT INTO UserRoles (UserID, RoleID)
    SELECT u.UserId, r.RoleID
    FROM Users u
    CROSS JOIN Roles r
    WHERE u.Username = 'admin' AND r.RoleName = 'SuperAdmin';
END
GO

IF NOT EXISTS (SELECT * FROM UserRoles ur INNER JOIN Users u ON ur.UserID = u.UserId WHERE u.Username = 'radiologist')
BEGIN
    INSERT INTO UserRoles (UserID, RoleID)
    SELECT u.UserId, r.RoleID
    FROM Users u
    CROSS JOIN Roles r
    WHERE u.Username = 'radiologist' AND r.RoleName = 'Radiologist';
END
GO

-- Assign users to default department
IF NOT EXISTS (SELECT * FROM UserDepartments)
BEGIN
    INSERT INTO UserDepartments (UserID, DepartmentID)
    SELECT u.UserId, d.DepartmentID
    FROM Users u
    CROSS JOIN Departments d
    WHERE d.DepartmentName = 'Radiology';
END
GO

PRINT 'Enterprise features added successfully!';
GO


-- ============================================================================
-- PATIENT SHARE TABLES (OHIF Viewer Sharing)
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PatientShares')
BEGIN
    CREATE TABLE PatientShares (
        ShareID INT PRIMARY KEY IDENTITY(1,1),
        StudyInstanceUID NVARCHAR(200) NOT NULL,
        ShareToken NVARCHAR(100) NOT NULL UNIQUE,
        PatientID INT NULL,
        PatientEmail NVARCHAR(200),
        ExpiresAt DATETIME2 NOT NULL,
        IsActive BIT NOT NULL DEFAULT 1,
        AllowDownload BIT NOT NULL DEFAULT 0,
        RequireAuthentication BIT NOT NULL DEFAULT 0,
        CustomMessage NVARCHAR(MAX),
        CreatedBy INT NOT NULL,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        RevokedAt DATETIME2 NULL,
        RevokeReason NVARCHAR(500),
        CONSTRAINT FK_PatientShares_Patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientId),
        CONSTRAINT FK_PatientShares_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId)
    );
    
    CREATE INDEX IX_PatientShares_ShareToken ON PatientShares(ShareToken);
    CREATE INDEX IX_PatientShares_StudyUID ON PatientShares(StudyInstanceUID);
    CREATE INDEX IX_PatientShares_Active ON PatientShares(IsActive, ExpiresAt);
END
GO

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'PatientShareAccesses')
BEGIN
    CREATE TABLE PatientShareAccesses (
        AccessID INT PRIMARY KEY IDENTITY(1,1),
        ShareID INT NOT NULL,
        AccessedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        IPAddress NVARCHAR(50),
        UserAgent NVARCHAR(500),
        CONSTRAINT FK_PatientShareAccesses_Share FOREIGN KEY (ShareID) REFERENCES PatientShares(ShareID) ON DELETE CASCADE
    );
    
    CREATE INDEX IX_PatientShareAccesses_ShareID ON PatientShareAccesses(ShareID, AccessedAt);
END
GO

PRINT 'Patient share tables created successfully!';
GO
