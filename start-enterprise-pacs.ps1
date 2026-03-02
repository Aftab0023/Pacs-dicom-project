Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Starting Enterprise PACS System" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Stopping existing containers..." -ForegroundColor Yellow
docker-compose down
Write-Host "Done" -ForegroundColor Green
Write-Host ""

Write-Host "Starting Docker containers..." -ForegroundColor Yellow
docker-compose up -d
Write-Host "Done" -ForegroundColor Green
Write-Host ""

Write-Host "Waiting for services (30 seconds)..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

Write-Host ""
& ".\init-enterprise-db.ps1"

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Service Status" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
docker-compose ps

Write-Host ""
Write-Host "Access URLs:" -ForegroundColor Cyan
Write-Host "  Frontend:    http://localhost:3000" -ForegroundColor Green
Write-Host "  API:         http://localhost:5000/swagger" -ForegroundColor Green
Write-Host "  Orthanc:     http://localhost:8042" -ForegroundColor Green
Write-Host ""
Write-Host "Credentials:" -ForegroundColor Yellow
Write-Host "  admin@pacs.local / Admin123!" -ForegroundColor White
Write-Host ""
