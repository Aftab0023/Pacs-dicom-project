USE PACSDB;
GO

-- Temporarily set plain text passwords for testing
-- This will work because AuthService has fallback to plain text
UPDATE Users 
SET PasswordHash = 'admin123'
WHERE Email IN ('admin@pacs.local', 'radiologist@pacs.local');

-- Verify update
SELECT UserId, Username, Email, Role, PasswordHash, IsActive
FROM Users;
GO

PRINT 'Passwords set to plain text for testing!';
PRINT 'Login with: admin@pacs.local / admin123';
GO
