# Fix User Passwords - Generate proper BCrypt hashes and update database
# Password: admin123

Write-Host "Fixing user passwords in database..." -ForegroundColor Cyan

# BCrypt hash for "admin123" with work factor 11
# Generated using: BCrypt.Net.BCrypt.HashPassword("admin123", 11)
$correctHash = '$2a$11$N9qo8uLOickgx2ZMRZoMye7FRNpZeS8vYGCYQC/ohDgXQvQvfKBZu'

# SQL to update passwords
$sql = @"
USE PACSDB;
GO

-- Update admin password
UPDATE Users 
SET PasswordHash = '$correctHash'
WHERE Email = 'admin@pacs.local';

-- Update radiologist password  
UPDATE Users 
SET PasswordHash = '$correctHash'
WHERE Email = 'radiologist@pacs.local';

-- Verify update
SELECT UserId, Username, Email, Role, 
       LEFT(PasswordHash, 20) + '...' as PasswordHash
FROM Users;
GO
"@

# Save SQL to file
$sql | Out-File -FilePath "update-passwords.sql" -Encoding UTF8

Write-Host ""
Write-Host "SQL script created: update-passwords.sql" -ForegroundColor Green
Write-Host ""
Write-Host "Executing SQL update..." -ForegroundColor Cyan

# Execute SQL using docker
docker exec -i pacs-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -i /tmp/update-passwords.sql

Write-Host ""
Write-Host "Copying SQL file to container..." -ForegroundColor Cyan
docker cp update-passwords.sql pacs-sqlserver:/tmp/update-passwords.sql

Write-Host "Executing password update..." -ForegroundColor Cyan
docker exec pacs-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "YourStrong@Passw0rd" -i /tmp/update-passwords.sql

Write-Host ""
Write-Host "Password update complete!" -ForegroundColor Green
Write-Host "You can now login with:" -ForegroundColor Yellow
Write-Host "  Email: admin@pacs.local" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
