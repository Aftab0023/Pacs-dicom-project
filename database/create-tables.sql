USE PACSDB;
GO

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

-- Insert default users
INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive, CreatedAt)
VALUES 
('admin', 'admin@pacs.local', '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y', 'Admin', 'System', 'Administrator', 1, GETUTCDATE()),
('radiologist', 'radiologist@pacs.local', '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y', 'Radiologist', 'John', 'Radiologist', 1, GETUTCDATE());
GO
