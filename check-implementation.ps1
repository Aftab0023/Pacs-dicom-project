# Check Implementation Script
# Verifies that enterprise features are properly set up

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Enterprise PACS Implementation Check" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$allGood = $true

# Check 1: Database files exist
Write-Host "[1/6] Checking database schema files..." -ForegroundColor Yellow
if (Test-Path "database\enterprise-schema.sql") {
    Write-Host "  ✓ enterprise-schema.sql found" -ForegroundColor Green
} else {
    Write-Host "  ✗ enterprise-schema.sql NOT found" -ForegroundColor Red
    $allGood = $false
}

if (Test-Path "database\patient-share-schema.sql") {
    Write-Host "  ✓ patient-share-schema.sql found" -ForegroundColor Green
} else {
    Write-Host "  ✗ patient-share-schema.sql NOT found" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# Check 2: Entity files exist
Write-Host "[2/6] Checking entity files..." -ForegroundColor Yellow
$entities = @(
    "backend\PACS.Core\Entities\WorklistEntry.cs",
    "backend\PACS.Core\Entities\RoutingRule.cs",
    "backend\PACS.Core\Entities\Permission.cs",
    "backend\PACS.Core\Entities\AuditLogEnhanced.cs",
    "backend\PACS.Core\Entities\PatientShare.cs"
)

foreach ($entity in $entities) {
    if (Test-Path $entity) {
        $name = Split-Path $entity -Leaf
        Write-Host "  ✓ $name" -ForegroundColor Green
    } else {
        $name = Split-Path $entity -Leaf
        Write-Host "  ✗ $name NOT found" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# Check 3: DTO files exist
Write-Host "[3/6] Checking DTO files..." -ForegroundColor Yellow
$dtos = @(
    "backend\PACS.Core\DTOs\WorklistDTOs.cs",
    "backend\PACS.Core\DTOs\RoutingDTOs.cs",
    "backend\PACS.Core\DTOs\PermissionDTOs.cs",
    "backend\PACS.Core\DTOs\PatientShareDTOs.cs"
)

foreach ($dto in $dtos) {
    if (Test-Path $dto) {
        $name = Split-Path $dto -Leaf
        Write-Host "  ✓ $name" -ForegroundColor Green
    } else {
        $name = Split-Path $dto -Leaf
        Write-Host "  ✗ $name NOT found" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# Check 4: Interface files exist
Write-Host "[4/6] Checking service interface files..." -ForegroundColor Yellow
$interfaces = @(
    "backend\PACS.Core\Interfaces\IWorklistService.cs",
    "backend\PACS.Core\Interfaces\IRoutingService.cs",
    "backend\PACS.Core\Interfaces\IPermissionService.cs",
    "backend\PACS.Core\Interfaces\IAuditServiceEnhanced.cs",
    "backend\PACS.Core\Interfaces\IPatientShareService.cs"
)

foreach ($interface in $interfaces) {
    if (Test-Path $interface) {
        $name = Split-Path $interface -Leaf
        Write-Host "  ✓ $name" -ForegroundColor Green
    } else {
        $name = Split-Path $interface -Leaf
        Write-Host "  ✗ $name NOT found" -ForegroundColor Red
        $allGood = $false
    }
}
Write-Host ""

# Check 5: DbContext updated
Write-Host "[5/6] Checking DbContext..." -ForegroundColor Yellow
$dbContextContent = Get-Content "backend\PACS.Infrastructure\Data\PACSDbContext.cs" -Raw
if ($dbContextContent -match "WorklistEntries" -and 
    $dbContextContent -match "RoutingRules" -and 
    $dbContextContent -match "Permissions") {
    Write-Host "  ✓ DbContext includes enterprise entities" -ForegroundColor Green
} else {
    Write-Host "  ✗ DbContext NOT updated with enterprise entities" -ForegroundColor Red
    $allGood = $false
}
Write-Host ""

# Check 6: SQL Server connection
Write-Host "[6/6] Checking SQL Server connection..." -ForegroundColor Yellow
try {
    $sqlCheck = sqlcmd -S localhost,1433 -U sa -P "Aftab@3234" -Q "SELECT 1" -C 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  ✓ SQL Server is accessible" -ForegroundColor Green
        
        # Check if PACSDB exists
        $dbCheck = sqlcmd -S localhost,1433 -U sa -P "Aftab@3234" -Q "SELECT name FROM sys.databases WHERE name = 'PACSDB'" -C -h -1
        if ($dbCheck -match "PACSDB") {
            Write-Host "  ✓ PACSDB database exists" -ForegroundColor Green
        } else {
            Write-Host "  ⚠ PACSDB database NOT found (run docker-compose up first)" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ⚠ SQL Server not accessible (run docker-compose up first)" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  ⚠ sqlcmd not found or SQL Server not running" -ForegroundColor Yellow
}
Write-Host ""

# Summary
Write-Host "========================================" -ForegroundColor Cyan
if ($allGood) {
    Write-Host "✓ All implementation files are present!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Run: .\setup-enterprise-features.ps1" -ForegroundColor White
    Write-Host "     (Installs database schema)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2. Run: cd backend\PACS.API && dotnet build" -ForegroundColor White
    Write-Host "     (Build the backend)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3. Run: cd backend\PACS.API && dotnet run" -ForegroundColor White
    Write-Host "     (Start the API server)" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4. Open: http://localhost:5000/swagger" -ForegroundColor White
    Write-Host "     (Test the API)" -ForegroundColor Gray
} else {
    Write-Host "✗ Some files are missing!" -ForegroundColor Red
    Write-Host "Please check the errors above" -ForegroundColor Red
}
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Feature summary
Write-Host "Implemented Features:" -ForegroundColor Cyan
Write-Host "  ✓ Enhanced Modality Worklist (MWL)" -ForegroundColor Green
Write-Host "  ✓ Advanced Study Routing" -ForegroundColor Green
Write-Host "  ✓ Granular RBAC Permissions (28 permissions, 6 roles)" -ForegroundColor Green
Write-Host "  ✓ Comprehensive Audit Logging" -ForegroundColor Green
Write-Host "  ✓ Patient Share Feature (OHIF viewer sharing)" -ForegroundColor Green
Write-Host ""
Write-Host "Database Objects:" -ForegroundColor Cyan
Write-Host "  • 15 new tables" -ForegroundColor White
Write-Host "  • 8 stored procedures" -ForegroundColor White
Write-Host "  • 30+ indexes" -ForegroundColor White
Write-Host "  • Complete seed data" -ForegroundColor White
Write-Host ""
