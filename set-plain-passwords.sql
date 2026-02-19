USE PACSDB;
GO

-- Set plain text passwords (ONLY FOR DEVELOPMENT)
UPDATE Users 
SET PasswordHash = 'admin123'
WHERE Email = 'admin@pacs.local';

UPDATE Users 
SET PasswordHash = 'admin123'
WHERE Email = 'radiologist@pacs.local';

SELECT Email, PasswordHash FROM Users;
GO
