# Fix user passwords - Set to plain text for development
# Password for both users: admin123
# WARNING: Plain text passwords are NOT secure - only for development!

Write-Host "Updating user passwords in database..."
Write-Host "Setting plain text passwords (development only)..."

docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = 'admin123' WHERE Email = 'admin@pacs.local'"

docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = 'admin123' WHERE Email = 'radiologist@pacs.local'"

Write-Host ""
Write-Host "✓ Passwords updated successfully!"
Write-Host ""
Write-Host "Login credentials:"
Write-Host "  Email: admin@pacs.local"
Write-Host "  Password: admin123"
Write-Host ""
Write-Host "  Email: radiologist@pacs.local"
Write-Host "  Password: admin123"
Write-Host ""
Write-Host "⚠️  WARNING: Using plain text passwords for development only!"
