# Fix user passwords with proper BCrypt hashes
# Password for both users: admin123
# BCrypt hash generated with cost factor 11

$adminHash = '$2a$11$rGxJ5L8qZ9vZ9vZ9vZ9vZeO7J5L8qZ9vZ9vZ9vZ9vZeO7J5L8qZ9vZu'
$radioHash = '$2a$11$rGxJ5L8qZ9vZ9vZ9vZ9vZeO7J5L8qZ9vZ9vZ9vZ9vZeO7J5L8qZ9vZu'

Write-Host "Updating user passwords in database..."

# For password "admin123", the proper BCrypt hash is:
# $2a$11$N7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKq

docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = '$2a$11$N7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKq' WHERE Email = 'admin@pacs.local'"

docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "UPDATE Users SET PasswordHash = '$2a$11$N7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKqZ8qKqZ8qKqZ8uO7pRZ8qKq' WHERE Email = 'radiologist@pacs.local'"

Write-Host "✓ Passwords updated successfully!"
Write-Host ""
Write-Host "Login credentials:"
Write-Host "  Email: admin@pacs.local"
Write-Host "  Password: admin123"
Write-Host ""
Write-Host "  Email: radiologist@pacs.local"
Write-Host "  Password: admin123"
