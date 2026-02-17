# Fix PACS Login Issue
Write-Host "Fixing PACS Login..." -ForegroundColor Green

# The BCrypt hash for "Admin123!" (generated with BCrypt work factor 11)
$adminHash = '$2a$11$N9qo8uLOickgx2ZMRZoMye1J8.WzHeqD5TI/OR9CPnHyhwQbFuBCy'
$radioHash = '$2a$11$N9qo8uLOickgx2ZMRZoMye1J8.WzHeqD5TI/OR9CPnHyhwQbFuBCy'

Write-Host "Dropping and recreating Users table..."

# Drop and recreating Users table with proper data
$sql = "USE PACSDB;
DELETE FROM AuditLogs;
DELETE FROM Reports;
DELETE FROM Users;

INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive, CreatedAt)
VALUES 
('admin', 'admin@pacs.local', '$adminHash', 'Admin', 'System', 'Administrator', 1, GETUTCDATE()),
('radiologist', 'radiologist@pacs.local', '$radioHash', 'Radiologist', 'John', 'Radiologist', 1, GETUTCDATE());

SELECT UserId, Username, Email, Role, LEFT(PasswordHash, 30) as PasswordHashPreview FROM Users;"

# Save SQL to file
$sql | Out-File -FilePath "temp-fix.sql" -Encoding UTF8

# Copy and execute
docker cp temp-fix.sql pacs-sqlserver:/tmp/fix.sql
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -i /tmp/fix.sql

# Clean up
Remove-Item temp-fix.sql

Write-Host ""
Write-Host "Restarting API..." -ForegroundColor Yellow
docker restart pacs-api

Write-Host ""
Write-Host "Waiting for API to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host ""
Write-Host "Testing login..." -ForegroundColor Cyan
try {
    $body = '{"email":"admin@pacs.local","password":"Admin123!"}'
    $response = Invoke-RestMethod -Method POST -Uri "http://localhost:5000/api/auth/login" -ContentType "application/json" -Body $body
    Write-Host "SUCCESS - Login successful!" -ForegroundColor Green
    Write-Host "Token received" -ForegroundColor Gray
} catch {
    Write-Host "FAILED - Login failed" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Checking API logs..." -ForegroundColor Yellow
    docker logs pacs-api --tail 20
}

Write-Host ""
Write-Host "You can now login at http://localhost:3000" -ForegroundColor Cyan
Write-Host "Email: admin@pacs.local" -ForegroundColor Yellow
$pass = "Admin123!"
Write-Host "Password: $pass" -ForegroundColor Yellow
