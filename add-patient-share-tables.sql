USE PACSDB;
GO

-- Create PatientShares table
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
    
    PRINT 'PatientShares table created successfully!';
END
ELSE
BEGIN
    PRINT 'PatientShares table already exists.';
END
GO

-- Create PatientShareAccesses table
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
    
    PRINT 'PatientShareAccesses table created successfully!';
END
ELSE
BEGIN
    PRINT 'PatientShareAccesses table already exists.';
END
GO

-- Verify tables
SELECT 'PatientShares' as TableName, COUNT(*) as RecordCount FROM PatientShares
UNION ALL
SELECT 'PatientShareAccesses', COUNT(*) FROM PatientShareAccesses;
GO

PRINT 'Patient share tables setup complete!';
GO
