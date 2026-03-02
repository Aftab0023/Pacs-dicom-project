Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Enterprise Database Setup" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Waiting for SQL Server..." -ForegroundColor Yellow
Start-Sleep -Seconds 10

Write-Host "Checking database..." -ForegroundColor Yellow
$checkDb = docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -Q "SELECT name FROM sys.databases WHERE name = 'PACSDB'" -h -1

if ($checkDb -notmatch "PACSDB") {
    Write-Host "Creating PACSDB..." -ForegroundColor Yellow
    docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -Q "CREATE DATABASE PACSDB"
    Write-Host "Database created" -ForegroundColor Green
}
else {
    Write-Host "PACSDB exists" -ForegroundColor Green
}

Write-Host ""
Write-Host "Running init script..." -ForegroundColor Yellow
Get-Content "database/init.sql" | docker exec -i pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -d PACSDB

Write-Host ""
Write-Host "Enterprise Features Added:" -ForegroundColor Cyan
Write-Host "  - Modality Worklist" -ForegroundColor Green
Write-Host "  - Study Routing" -ForegroundColor Green
Write-Host "  - RBAC Permissions (28)" -ForegroundColor Green
Write-Host "  - Enhanced Audit Logging" -ForegroundColor Green
Write-Host "  - 6 Roles" -ForegroundColor Green
Write-Host "  - 4 Departments" -ForegroundColor Green
Write-Host ""
Write-Host "Setup Complete!" -ForegroundColor Green
