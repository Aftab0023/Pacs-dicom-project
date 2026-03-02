#!/bin/bash
# Wait for SQL Server to be ready
echo "Waiting for SQL Server to be ready..."
sleep 30

# Run the initialization script
echo "Running database initialization..."
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -d master -Q "IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = 'PACSDB') CREATE DATABASE PACSDB"
/opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P Aftab@3234 -C -d PACSDB -i /docker-entrypoint-initdb.d/init.sql

echo "Database initialization completed!"
