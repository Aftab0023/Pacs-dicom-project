# Enterprise PACS Setup Script
# This script sets up the enterprise features

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enterprise PACS Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Check if SQL Server is running
Write-Host "Checking SQL Server connection..." -ForegroundColor Yellow
$sqlCheck = sqlcmd -S localhost,1433 -U sa -P "Aftab@3234" -Q "SELECT 1" -C 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERROR: Cannot connect to SQL Server!" -ForegroundColor Red
    Write-Host "Please ensure SQL Server is running on localhost:1433" -ForegroundColor Red
    Write-Host "Password: Aftab@3234" -ForegroundColor Red
    exit 1
}
Write-Host "✓ SQL Server connection successful" -ForegroundColor Green
Write-Host ""

# Check if PACSDB exists
Write-Host "Checking if PACSDB exists..." -ForegroundColor Yellow
$dbCheck = sqlcmd -S localhost,1433 -U sa -P "Aftab@3234" -Q "SELECT name FROM sys.databases WHERE name = 'PACSDB'" -C -h -1
if ($dbCheck -match "PACSDB") {
    Write-Host "✓ PACSDB database found" -ForegroundColor Green
} else {
    Write-Host "ERROR: PACSDB database not found!" -ForegroundColor Red
    Write-Host "Please create the database first or run docker-compose up" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Run enterprise schema
Write-Host "Installing enterprise schema..." -ForegroundColor Yellow
Write-Host "This will add:" -ForegroundColor White
Write-Host "  - Modality Worklist tables" -ForegroundColor White
Write-Host "  - Study Routing tables" -ForegroundColor White
Write-Host "  - RBAC Permission tables" -ForegroundColor White
Write-Host "  - Enhanced Audit Logging" -ForegroundColor White
Write-Host ""

$confirm = Read-Host "Continue? (Y/N)"
if ($confirm -ne "Y" -and $confirm -ne "y") {
    Write-Host "Setup cancelled" -ForegroundColor Yellow
    exit 0
}

Write-Host ""
Write-Host "Executing enterprise-schema.sql..." -ForegroundColor Yellow
$result = sqlcmd -S localhost,1433 -U sa -P "Aftab@3234" -d PACSDB -i "database\enterprise-schema.sql" -C 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Enterprise schema installed successfully!" -ForegroundColor Green
} else {
    Write-Host "ERROR: Failed to install enterprise schema" -ForegroundColor Red
    Write-Host $result -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Enterprise features installed:" -ForegroundColor White
Write-Host "  ✓ 13 new tables created" -ForegroundColor Green
Write-Host "  ✓ 28 permissions defined" -ForegroundColor Green
Write-Host "  ✓ 6 roles configured" -ForegroundColor Green
Write-Host "  ✓ 4 departments created" -ForegroundColor Green
Write-Host "  ✓ Stored procedures added" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Build and run the backend: cd backend\PACS.API && dotnet run" -ForegroundColor White
Write-Host "  2. Check Swagger UI: http://localhost:5000/swagger" -ForegroundColor White
Write-Host "  3. Test new endpoints (worklist, routing, permissions)" -ForegroundColor White
Write-Host ""
Write-Host "Default credentials:" -ForegroundColor Yellow
Write-Host "  Admin: admin@pacs.local / Admin123!" -ForegroundColor White
Write-Host "  Radiologist: radiologist@pacs.local / Radio123!" -ForegroundColor White
Write-Host ""
