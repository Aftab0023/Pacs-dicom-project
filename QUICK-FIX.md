# Quick Fix for Login Issue

## Problem
The BCrypt password hashes in the database are not compatible with BCrypt.Net library.

## Solution

Run this command to set a simple password:

```powershell
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -d PACSDB -Q "DELETE FROM Users; INSERT INTO Users (Username, Email, PasswordHash, Role, FirstName, LastName, IsActive, CreatedAt) VALUES ('admin', 'admin@pacs.local', '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', 'Admin', 'System', 'Administrator', 1, GETUTCDATE())"
```

Then login with:
- Email: `admin@pacs.local`
- Password: `password`

## Alternative: Let EF Core Create Users

The best solution is to let Entity Framework create the users with proper BCrypt hashes.

1. Drop the PACSDB database
2. Let the API recreate it with EnsureCreated()
3. The seed data in DbContext will create users with correct hashes

```powershell
docker exec pacs-sqlserver /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "Aftab@3234" -C -Q "DROP DATABASE PACSDB"
docker restart pacs-api
```

Wait 10 seconds, then try logging in with:
- Email: `admin@pacs.local`  
- Password: `Admin123!`
