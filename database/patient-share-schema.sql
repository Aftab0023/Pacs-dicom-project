-- Patient Share Feature Schema
-- Allows sharing OHIF viewer and images with patients

USE PACSDB;
GO

-- ============================================================================
-- PATIENT SHARE TABLES
-- ============================================================================

CREATE TABLE PatientShares (
    ShareID INT PRIMARY KEY IDENTITY(1,1),
    StudyInstanceUID NVARCHAR(100) NOT NULL,
    PatientID INT NOT NULL,
    ShareToken NVARCHAR(100) NOT NULL UNIQUE,
    ShareType NVARCHAR(20) NOT NULL DEFAULT 'VIEWER', -- VIEWER, IMAGES, REPORT, ALL
    IncludeReport BIT NOT NULL DEFAULT 0,
    AllowDownload BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    ExpiresAt DATETIME NOT NULL,
    CreatedBy INT NOT NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    AccessCount INT NOT NULL DEFAULT 0,
    LastAccessedAt DATETIME NULL,
    PatientEmail NVARCHAR(200) NULL,
    PatientPhone NVARCHAR(50) NULL,
    Notes NVARCHAR(MAX) NULL,
    CONSTRAINT FK_PatientShares_Patient FOREIGN KEY (PatientID) REFERENCES Patients(PatientId),
    CONSTRAINT FK_PatientShares_CreatedBy FOREIGN KEY (CreatedBy) REFERENCES Users(UserId),
    INDEX IX_ShareToken (ShareToken),
    INDEX IX_PatientID (PatientID),
    INDEX IX_StudyUID (StudyInstanceUID),
    INDEX IX_ExpiresAt (ExpiresAt, IsActive),
    INDEX IX_CreatedBy (CreatedBy)
);
GO

CREATE TABLE PatientShareAccessLogs (
    AccessID INT PRIMARY KEY IDENTITY(1,1),
    ShareID INT NOT NULL,
    AccessedAt DATETIME NOT NULL DEFAULT GETDATE(),
    IPAddress NVARCHAR(50) NULL,
    UserAgent NVARCHAR(500) NULL,
    Location NVARCHAR(200) NULL,
    Action NVARCHAR(50) NOT NULL, -- VIEW, DOWNLOAD, PRINT
    CONSTRAINT FK_ShareAccess_Share FOREIGN KEY (ShareID) REFERENCES PatientShares(ShareID) ON DELETE CASCADE,
    INDEX IX_ShareID (ShareID, AccessedAt),
    INDEX IX_AccessedAt (AccessedAt)
);
GO

-- ============================================================================
-- STORED PROCEDURES
-- ============================================================================

-- Generate unique share token
CREATE PROCEDURE sp_GenerateShareToken
AS
BEGIN
    DECLARE @token NVARCHAR(100);
    DECLARE @exists BIT = 1;
    
    WHILE @exists = 1
    BEGIN
        SET @token = CONVERT(NVARCHAR(100), NEWID());
        
        IF NOT EXISTS (SELECT 1 FROM PatientShares WHERE ShareToken = @token)
            SET @exists = 0;
    END
    
    SELECT @token AS ShareToken;
END;
GO

-- Get active shares for a patient
CREATE PROCEDURE sp_GetPatientActiveShares
    @PatientID INT
AS
BEGIN
    SELECT 
        ps.ShareID,
        ps.StudyInstanceUID,
        ps.PatientID,
        ps.ShareToken,
        ps.ShareType,
        ps.IncludeReport,
        ps.AllowDownload,
        ps.CreatedDate,
        ps.ExpiresAt,
        ps.IsActive,
        ps.AccessCount,
        ps.LastAccessedAt,
        ps.PatientEmail,
        ps.PatientPhone,
        p.FirstName + ' ' + p.LastName AS PatientName,
        u.FirstName + ' ' + u.LastName AS CreatedByName
    FROM PatientShares ps
    INNER JOIN Patients p ON ps.PatientID = p.PatientId
    INNER JOIN Users u ON ps.CreatedBy = u.UserId
    WHERE ps.PatientID = @PatientID
    AND ps.IsActive = 1
    AND ps.ExpiresAt > GETDATE()
    ORDER BY ps.CreatedDate DESC;
END;
GO

-- Validate share token
CREATE PROCEDURE sp_ValidateShareToken
    @ShareToken NVARCHAR(100)
AS
BEGIN
    SELECT 
        ps.ShareID,
        ps.StudyInstanceUID,
        ps.PatientID,
        ps.ShareType,
        ps.IncludeReport,
        ps.AllowDownload,
        ps.ExpiresAt,
        ps.IsActive,
        CASE 
            WHEN ps.IsActive = 0 THEN 'Share has been revoked'
            WHEN ps.ExpiresAt < GETDATE() THEN 'Share has expired'
            ELSE 'Valid'
        END AS ValidationStatus,
        p.FirstName + ' ' + p.LastName AS PatientName,
        s.StudyDate,
        s.Modality,
        s.Description AS StudyDescription
    FROM PatientShares ps
    INNER JOIN Patients p ON ps.PatientID = p.PatientId
    LEFT JOIN Studies s ON ps.StudyInstanceUID = s.StudyInstanceUID
    WHERE ps.ShareToken = @ShareToken;
END;
GO

-- Log share access
CREATE PROCEDURE sp_LogShareAccess
    @ShareID INT,
    @IPAddress NVARCHAR(50) = NULL,
    @UserAgent NVARCHAR(500) = NULL,
    @Location NVARCHAR(200) = NULL,
    @Action NVARCHAR(50) = 'VIEW'
AS
BEGIN
    -- Insert access log
    INSERT INTO PatientShareAccessLogs (ShareID, IPAddress, UserAgent, Location, Action)
    VALUES (@ShareID, @IPAddress, @UserAgent, @Location, @Action);
    
    -- Update share access count and last accessed time
    UPDATE PatientShares
    SET AccessCount = AccessCount + 1,
        LastAccessedAt = GETDATE()
    WHERE ShareID = @ShareID;
END;
GO

-- Deactivate expired shares
CREATE PROCEDURE sp_DeactivateExpiredShares
AS
BEGIN
    UPDATE PatientShares
    SET IsActive = 0
    WHERE IsActive = 1
    AND ExpiresAt < GETDATE();
    
    SELECT @@ROWCOUNT AS DeactivatedCount;
END;
GO

-- Get share statistics
CREATE PROCEDURE sp_GetShareStatistics
    @UserID INT = NULL
AS
BEGIN
    SELECT 
        COUNT(*) AS TotalShares,
        SUM(CASE WHEN IsActive = 1 AND ExpiresAt > GETDATE() THEN 1 ELSE 0 END) AS ActiveShares,
        SUM(CASE WHEN ExpiresAt < GETDATE() THEN 1 ELSE 0 END) AS ExpiredShares,
        SUM(AccessCount) AS TotalAccesses,
        AVG(CAST(AccessCount AS FLOAT)) AS AvgAccessesPerShare
    FROM PatientShares
    WHERE (@UserID IS NULL OR CreatedBy = @UserID);
END;
GO

PRINT 'Patient Share schema created successfully!';
GO
