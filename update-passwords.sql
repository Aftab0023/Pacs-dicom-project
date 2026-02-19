USE PACSDB;
GO

-- Update admin password (password: "password")
UPDATE Users 
SET PasswordHash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE Email = 'admin@pacs.local';

-- Update radiologist password (password: "password")
UPDATE Users 
SET PasswordHash = '$2a$10$N9qo8uLOickgx2ZMRZoMyeIjZAgcfl7p92ldGxad68LJZdL17lhWy'
WHERE Email = 'radiologist@pacs.local';

SELECT Email, LEN(PasswordHash) as HashLength FROM Users;
GO
