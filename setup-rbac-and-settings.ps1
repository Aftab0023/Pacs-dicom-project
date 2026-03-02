# Setup RBAC and System Settings Feature
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  RBAC & System Settings Setup" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Add SystemSettings table to database
Write-Host "[1/3] Adding SystemSettings table to database..." -ForegroundColor Yellow
docker exec -it pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd `
    -S localhost -U sa -P "Aftab@3234" -C `
    -i /docker-entrypoint-initdb.d/add-system-settings.sql

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Database updated successfully" -ForegroundColor Green
} else {
    Write-Host "✗ Database update failed" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Step 2: Copy SQL file to container
Write-Host "[2/3] Copying SQL file to container..." -ForegroundColor Yellow
docker cp database/add-system-settings.sql pacs-sqlserver:/docker-entrypoint-initdb.d/

Write-Host ""

# Step 3: Rebuild and restart containers
Write-Host "[3/3] Rebuilding containers..." -ForegroundColor Yellow
docker-compose up -d --build pacs-api pacs-frontend

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "  Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "New Features Added:" -ForegroundColor Cyan
Write-Host "  ✓ Role-Based Access Control (RBAC)" -ForegroundColor White
Write-Host "  ✓ System Settings Management" -ForegroundColor White
Write-Host "  ✓ Customizable Report Settings" -ForegroundColor White
Write-Host "  ✓ Admin Settings Page" -ForegroundColor White
Write-Host ""
Write-Host "Access Admin Settings:" -ForegroundColor Cyan
Write-Host "  1. Login as admin (admin@pacs.local / admin123)" -ForegroundColor White
Write-Host "  2. Click 'Settings' in navigation" -ForegroundColor White
Write-Host "  3. Customize report settings:" -ForegroundColor White
Write-Host "     - Institution Name" -ForegroundColor Gray
Write-Host "     - Report Title" -ForegroundColor Gray
Write-Host "     - Digital Signature Text" -ForegroundColor Gray
Write-Host "     - Footer Text" -ForegroundColor Gray
Write-Host "     - Watermark Settings" -ForegroundColor Gray
Write-Host ""
Write-Host "API Endpoints:" -ForegroundColor Cyan
Write-Host "  GET  /api/SystemSettings/report" -ForegroundColor White
Write-Host "  PUT  /api/SystemSettings/report" -ForegroundColor White
Write-Host "  GET  /api/SystemSettings (Admin only)" -ForegroundColor White
Write-Host ""
Write-Host "Frontend URL: http://localhost:3000" -ForegroundColor Cyan
Write-Host "API Swagger: http://localhost:5000/swagger" -ForegroundColor Cyan
Write-Host ""
