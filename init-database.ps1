# Initialize PACS Database
Write-Host "Initializing PACS Database..." -ForegroundColor Green

# Wait for SQL Server to be ready
Write-Host "Waiting for SQL Server to be ready..."
Start-Sleep -Seconds 5

# Create database
Write-Host "Creating PACSDB database..."
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -Q "IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PACSDB') CREATE DATABASE PACSDB"

# Copy SQL script
Write-Host "Copying initialization script..."
docker cp database/create-tables.sql pacs-sqlserver:/tmp/create-tables.sql

# Execute SQL script
Write-Host "Creating tables and seeding data..."
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -i /tmp/create-tables.sql

# Restart API
Write-Host "Restarting API..."
docker restart pacs-api

Write-Host "Database initialization complete!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now login at http://localhost:3000 with:" -ForegroundColor Cyan
Write-Host "  Email: admin@pacs.local" -ForegroundColor Yellow
Write-Host "  Password: Admin123!" -ForegroundColor Yellow
