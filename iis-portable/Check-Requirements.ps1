# ================================================================
#  Check-Requirements.ps1
#  Run this BEFORE deployment to verify everything is ready.
#  Compatible: Windows 10, Windows Server 2016/2019/2022
#
#  USAGE: Right-click → Run with PowerShell
# ================================================================

Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

$pass  = 0
$fail  = 0
$warn  = 0

function OK   ($msg) { Write-Host "  [PASS] $msg" -ForegroundColor Green;  $script:pass++ }
function FAIL ($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red;    $script:fail++ }
function WARN ($msg) { Write-Host "  [WARN] $msg" -ForegroundColor Yellow; $script:warn++ }
function HEAD ($msg) { Write-Host ""; Write-Host "  $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "     PACS Pre-Deployment Requirements Check" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan

# ================================================================
HEAD "1. OPERATING SYSTEM"
# ================================================================
$os = Get-WmiObject -Class Win32_OperatingSystem
$osName    = $os.Caption
$osBuild   = [System.Environment]::OSVersion.Version.Build
$osArch    = $os.OSArchitecture

Write-Host "     $osName ($osArch) — Build $osBuild" -ForegroundColor Gray

if ($osBuild -ge 14393) {
    OK "OS supported (Windows 10 / Server 2016 or newer)"
} else {
    FAIL "OS too old. Minimum: Windows 10 / Server 2016 (Build 14393)"
}

# ================================================================
HEAD "2. ORTHANC PORTABLE (E:\OrthancPortable)"
# ================================================================
$OrthancBase = "E:\OrthancPortable"
$OrthancExe  = "$OrthancBase\OrthancServer\Orthanc.exe"
$PluginsDir  = "$OrthancBase\OrthancServer\Plugins"

if (Test-Path $OrthancExe) {
    OK "Orthanc.exe found: $OrthancExe"
} else {
    FAIL "Orthanc.exe NOT found at: $OrthancExe"
    Write-Host "       Copy OrthancPortable to E:\ first" -ForegroundColor DarkGray
}

if (Test-Path $PluginsDir) {
    $dlls = Get-ChildItem "$PluginsDir\*.dll" -ErrorAction SilentlyContinue
    if ($dlls.Count -gt 0) {
        OK "Plugins folder found ($($dlls.Count) plugins)"
        $dlls | ForEach-Object { Write-Host "       - $($_.Name)" -ForegroundColor DarkGray }
    } else {
        WARN "Plugins folder exists but no .dll files found"
    }
} else {
    FAIL "Plugins folder NOT found: $PluginsDir"
}

# Check E:\ drive has enough space
$drive = Get-PSDrive E -ErrorAction SilentlyContinue
if ($drive) {
    $freeGB = [math]::Round($drive.Free / 1GB, 1)
    if ($freeGB -ge 10) {
        OK "E:\ drive free space: ${freeGB} GB"
    } else {
        WARN "E:\ drive low on space: ${freeGB} GB free (recommend 10+ GB for DICOM storage)"
    }
} else {
    FAIL "E:\ drive not found — plug in or map the drive"
}

# ================================================================
HEAD "3. .NET RUNTIME"
# ================================================================
$dotnet = Get-Command dotnet -ErrorAction SilentlyContinue
if ($dotnet) {
    $ver = & dotnet --version 2>$null
    if ($ver -match "^8\.") {
        OK ".NET 8 found: $ver"
    } elseif ($ver) {
        WARN ".NET found but version is $ver — need .NET 8"
        Write-Host "       Download: https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -ForegroundColor DarkGray
    }
} else {
    FAIL ".NET not found — install .NET 8 Hosting Bundle"
    Write-Host "       Download: https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -ForegroundColor DarkGray
}

# Check ASP.NET Core Module (ANCM) for IIS
$ancm = Get-Item "C:\Windows\System32\inetsrv\aspnetcorev2.dll" -ErrorAction SilentlyContinue
if ($ancm) {
    OK "ASP.NET Core Module (ANCM) installed"
} else {
    FAIL "ASP.NET Core Module NOT found — install .NET 8 Hosting Bundle (not just runtime)"
    Write-Host "       Download: https://dotnet.microsoft.com/en-us/download/dotnet/8.0" -ForegroundColor DarkGray
}

# ================================================================
HEAD "4. IIS"
# ================================================================
$iis = Get-Service W3SVC -ErrorAction SilentlyContinue
if ($iis) {
    if ($iis.Status -eq "Running") {
        OK "IIS is installed and running"
    } else {
        WARN "IIS is installed but not running (Status: $($iis.Status))"
    }
} else {
    FAIL "IIS not installed — enable via: Windows Features → Internet Information Services"
}

# URL Rewrite Module
$rewrite = Get-Item "C:\Windows\System32\inetsrv\rewrite.dll" -ErrorAction SilentlyContinue
if ($rewrite) {
    OK "IIS URL Rewrite Module installed"
} else {
    FAIL "IIS URL Rewrite Module NOT found"
    Write-Host "       Download: https://www.iis.net/downloads/microsoft/url-rewrite" -ForegroundColor DarkGray
}

# WebAdministration module
$webAdmin = Get-Module -ListAvailable -Name WebAdministration -ErrorAction SilentlyContinue
if ($webAdmin) {
    OK "IIS WebAdministration PowerShell module available"
} else {
    WARN "IIS WebAdministration module not found — IIS Management Tools may not be installed"
}

# ================================================================
HEAD "5. SQL SERVER"
# ================================================================
$sqlcmd = Get-Command sqlcmd -ErrorAction SilentlyContinue
if ($sqlcmd) {
    OK "sqlcmd found: $($sqlcmd.Source)"

    # Test connection on port 1434
    $result = & sqlcmd -S "localhost,1434" -U sa -P "Aftab@3234" -C -Q "SELECT @@VERSION" -t 5 2>&1
    if ($LASTEXITCODE -eq 0) {
        OK "SQL Server connection OK (localhost,1434)"

        # Check PACSDB exists
        $dbCheck = & sqlcmd -S "localhost,1434" -U sa -P "Aftab@3234" -C -Q "SELECT state_desc FROM sys.databases WHERE name='PACSDB'" -t 5 2>&1
        if ($dbCheck -match "ONLINE") {
            OK "PACSDB database exists and is ONLINE"
        } else {
            WARN "PACSDB not found — restore from backup before deploying"
        }
    } else {
        FAIL "Cannot connect to SQL Server on localhost,1434"
        Write-Host "       Check SQL Server is running and port 1434 is open" -ForegroundColor DarkGray
    }
} else {
    WARN "sqlcmd not found — cannot verify SQL Server connection"
    Write-Host "       Install SQL Server command line tools to enable this check" -ForegroundColor DarkGray
}

# ================================================================
HEAD "6. NODE.JS (for frontend build)"
# ================================================================
$node = Get-Command node -ErrorAction SilentlyContinue
if ($node) {
    $nodeVer = & node --version 2>$null
    $major   = [int]($nodeVer -replace "v(\d+)\..*", '$1')
    if ($major -ge 16) {
        OK "Node.js found: $nodeVer"
    } else {
        WARN "Node.js $nodeVer is old — recommend v18 or newer"
    }
} else {
    WARN "Node.js not found — needed only if building frontend on this machine"
    Write-Host "       Download: https://nodejs.org" -ForegroundColor DarkGray
}

$npm = Get-Command npm -ErrorAction SilentlyContinue
if ($npm) {
    $npmVer = & npm --version 2>$null
    OK "npm found: v$npmVer"
} else {
    WARN "npm not found"
}

# ================================================================
HEAD "7. FIREWALL PORTS"
# ================================================================
$ports = @(
    @{ Port=80;   Name="HTTP (Frontend)" },
    @{ Port=5000; Name="PACS API" },
    @{ Port=8042; Name="Orthanc HTTP" },
    @{ Port=4242; Name="Orthanc DICOM" },
    @{ Port=1434; Name="SQL Server" }
)

foreach ($p in $ports) {
    $rule = Get-NetFirewallRule -ErrorAction SilentlyContinue |
            Where-Object { $_.Enabled -eq "True" -and $_.Direction -eq "Inbound" } |
            Get-NetFirewallPortFilter -ErrorAction SilentlyContinue |
            Where-Object { $_.LocalPort -eq $p.Port }
    if ($rule) {
        OK "Port $($p.Port) open — $($p.Name)"
    } else {
        WARN "Port $($p.Port) not in firewall rules — $($p.Name) (may still work if firewall is off)"
    }
}

# ================================================================
HEAD "8. PORTS IN USE (conflicts)"
# ================================================================
$checkPorts = @(80, 5000, 8042, 4242)
foreach ($p in $checkPorts) {
    $conn = Get-NetTCPConnection -LocalPort $p -State Listen -ErrorAction SilentlyContinue
    if ($conn) {
        $proc = Get-Process -Id $conn.OwningProcess -ErrorAction SilentlyContinue
        WARN "Port $p already in use by: $($proc.Name) (PID $($conn.OwningProcess))"
    } else {
        OK "Port $p is free"
    }
}

# ================================================================
HEAD "9. DISK SPACE (C:\)"
# ================================================================
$cDrive = Get-PSDrive C -ErrorAction SilentlyContinue
if ($cDrive) {
    $freeGB = [math]::Round($cDrive.Free / 1GB, 1)
    if ($freeGB -ge 5) {
        OK "C:\ free space: ${freeGB} GB"
    } else {
        WARN "C:\ low on space: ${freeGB} GB (need at least 5 GB for IIS deployment)"
    }
}

# ================================================================
#  SUMMARY
# ================================================================
Write-Host ""
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "     SUMMARY" -ForegroundColor Cyan
Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host "  PASSED : $pass" -ForegroundColor Green
Write-Host "  WARNED : $warn" -ForegroundColor Yellow
Write-Host "  FAILED : $fail" -ForegroundColor $(if ($fail -gt 0) { "Red" } else { "Gray" })
Write-Host "  ------------------------------------------------" -ForegroundColor Cyan

if ($fail -eq 0 -and $warn -eq 0) {
    Write-Host "  All checks passed. Ready to deploy!" -ForegroundColor Green
} elseif ($fail -eq 0) {
    Write-Host "  No critical failures. Review warnings before deploying." -ForegroundColor Yellow
} else {
    Write-Host "  $fail critical issue(s) found. Fix them before deploying." -ForegroundColor Red
}

Write-Host "  ================================================" -ForegroundColor Cyan
Write-Host ""
Read-Host "Press Enter to exit"
