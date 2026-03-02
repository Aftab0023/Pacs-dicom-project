USE PACSDB;
GO

-- Update admin password with correct BCrypt hash for "admin123"
UPDATE Users 
SET PasswordHash = '$2a$11$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vYGCYQC/ohDgXQvQvfKBZu'
WHERE Email = 'admin@pacs.local';

-- Update radiologist password with correct BCrypt hash for "admin123"
UPDATE Users 
SET PasswordHash = '$2a$11$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vYGCYQC/ohDgXQvQvfKBZu'
WHERE Email = 'radiologist@pacs.local';

-- Verify update
SELECT UserId, Username, Email, Role, 
       LEFT(PasswordHash, 20) + '...' as PasswordHashPreview,
       IsActive, CreatedAt
FROM Users;
GO

PRINT 'Passwords updated successfully!';
GO
