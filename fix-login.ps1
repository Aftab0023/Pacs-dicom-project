# Fix Login - Set passwords to plain text (works with AuthService fallback)
# This is a quick fix for development. For production, use proper BCrypt hashes.

Write-Host "Fixing login passwords..." -ForegroundColor Cyan
Write-Host ""

# Copy SQL script to container
docker cp set-plain-passwords.sql pacs-sqlserver:/tmp/set-plain-passwords.sql

# Execute SQL
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -i /tmp/set-plain-passwords.sql

Write-Host ""
Write-Host "✓ Login fixed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "You can now login at: http://localhost:3000" -ForegroundColor Yellow
Write-Host "  Email: admin@pacs.local" -ForegroundColor White
Write-Host "  Password: admin123" -ForegroundColor White
Write-Host ""
Write-Host "Note: Using plain text passwords for development." -ForegroundColor Gray
Write-Host "AuthService has fallback support for plain text." -ForegroundColor Gray
