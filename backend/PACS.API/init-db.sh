#!/bin/bash
set -e

echo "Waiting for SQL Server to be ready..."
sleep 20

echo "Creating database and tables..."
/opt/mssql-tools18/bin/sqlcmd -S sqlserver -U sa -P "YourStrong@Passw0rd" -C -Q "
IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PACSDB')
BEGIN
    CREATE DATABASE PACSDB;
END
"

echo "Database initialization complete!"
dotnet PACS.API.dll
