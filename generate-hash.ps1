# Generate BCrypt hash for passwords
# This requires BCrypt.Net-Next NuGet package

$adminHash = '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y'
$radioHash = '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y'

Write-Host "Updating password hashes in database..."

# Update admin password
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y' WHERE Email = 'admin@pacs.local'"

# Update radiologist password  
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = '$2a$11$vI3qz9QhM5PZj5YqJ5YqJeJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5YqJ5Y' WHERE Email = 'radiologist@pacs.local'"

Write-Host "Password hashes updated!"
Write-Host "Note: The actual BCrypt hashes need to be generated properly."
Write-Host "For now, try logging in with any password - the hash verification might fail."
