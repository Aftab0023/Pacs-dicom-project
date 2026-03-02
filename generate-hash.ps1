# Generate BCrypt hash for admin123 password
# This script generates the correct BCrypt hash

$password = "admin123"

# Using .NET BCrypt library
Add-Type -Path "C:\Program Files\dotnet\shared\Microsoft.NETCore.App\*\System.Security.Cryptography.dll" -ErrorAction SilentlyContinue

# Generate BCrypt hash with work factor 11
$hash = [BCrypt.Net.BCrypt]::HashPassword($password, 11)

Write-Host "Password: $password"
Write-Host "BCrypt Hash: $hash"
Write-Host ""
Write-Host "SQL Update Statement:"
Write-Host "UPDATE Users SET PasswordHash = '$hash' WHERE Email IN ('admin@pacs.local', 'radiologist@pacs.local');"
