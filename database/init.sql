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
IF NOT EXISTS (SELECT * FROM Users WHERE Email = 'admin@pacs.local')
BEGIN
    INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive, CreatedAt)
    VALUES 
    ('admin', 'admin@pacs.local', '$2a$11$8vJ5YqJ5YqJ5YqJ5YqJ5YeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y', 'Admin', 'System', 'Administrator', 1, GETUTCDATE()),
    ('radiologist', 'radiologist@pacs.local', '$2a$11$8vJ5YqJ5YqJ5YqJ5YqJ5YeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y', 'Radiologist', 'John', 'Radiologist', 1, GETUTCDATE());
END
GO

PRINT 'Database initialization completed successfully!';
GO
