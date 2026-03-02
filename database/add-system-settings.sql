USE PACSDB;
GO

-- Create SystemSettings table for admin-configurable settings
IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'SystemSettings')
BEGIN
    CREATE TABLE SystemSettings (
        SettingID INT PRIMARY KEY IDENTITY(1,1),
        SettingKey NVARCHAR(100) NOT NULL UNIQUE,
        SettingValue NVARCHAR(MAX) NULL,
        SettingType NVARCHAR(50) NOT NULL, -- 'String', 'Number', 'Boolean', 'JSON'
        Category NVARCHAR(50) NOT NULL, -- 'Report', 'System', 'Email', etc.
        Description NVARCHAR(500) NULL,
        IsEditable BIT NOT NULL DEFAULT 1,
        CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
        UpdatedBy INT NULL,
        FOREIGN KEY (UpdatedBy) REFERENCES Users(UserId)
    );
    PRINT 'SystemSettings table created successfully';
END
GO

-- Insert default report settings
IF NOT EXISTS (SELECT * FROM SystemSettings WHERE SettingKey = 'Report.InstitutionName')
BEGIN
    INSERT INTO SystemSettings (SettingKey, SettingValue, SettingType, Category, Description, IsEditable)
    VALUES 
    ('Report.InstitutionName', 'Life Relief Medical PACS', 'String', 'Report', 'Institution name displayed on reports', 1),
    ('Report.ReportTitle', 'Radiology Report', 'String', 'Report', 'Default report title', 1),
    ('Report.DepartmentName', 'Department of Radiology', 'String', 'Report', 'Department name on reports', 1),
    ('Report.InstitutionAddress', '123 Medical Center Drive, Healthcare City', 'String', 'Report', 'Institution address', 1),
    ('Report.InstitutionPhone', '+1 (555) 123-4567', 'String', 'Report', 'Institution phone number', 1),
    ('Report.InstitutionEmail', 'radiology@liferelief.medical', 'String', 'Report', 'Institution email', 1),
    ('Report.LogoUrl', '', 'String', 'Report', 'URL or path to institution logo', 1),
    ('Report.FooterText', 'This report is confidential and intended for medical professionals only.', 'String', 'Report', 'Footer text on reports', 1),
    ('Report.DigitalSignatureText', 'Electronically signed by', 'String', 'Report', 'Digital signature prefix text', 1),
    ('Report.ShowWatermark', 'false', 'Boolean', 'Report', 'Show watermark on reports', 1),
    ('Report.WatermarkText', 'CONFIDENTIAL', 'String', 'Report', 'Watermark text', 1),
    ('System.AllowGuestAccess', 'false', 'Boolean', 'System', 'Allow guest users to view shared studies', 1),
    ('System.SessionTimeout', '30', 'Number', 'System', 'Session timeout in minutes', 1),
    ('System.MaxUploadSize', '100', 'Number', 'System', 'Maximum upload size in MB', 1);
    
    PRINT 'Default system settings inserted successfully';
END
GO

-- Create index for faster lookups
CREATE NONCLUSTERED INDEX IX_SystemSettings_Category 
ON SystemSettings(Category) 
WHERE IsEditable = 1;
GO

-- View current settings
SELECT 
    SettingKey,
    SettingValue,
    Category,
    Description,
    IsEditable
FROM SystemSettings
ORDER BY Category, SettingKey;
GO

PRINT 'System settings configuration complete!';
GO
