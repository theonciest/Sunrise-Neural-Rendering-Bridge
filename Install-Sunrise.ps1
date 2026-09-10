
$ErrorActionPreference = "Stop"

try {
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " FSR3-DLSS5-FEEDER - PROJECT SUNRISE INSTALLER" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$PayloadRoot = Join-Path $PackageRoot "payload"

if (-not (Test-Path $PayloadRoot)) {
    throw "Release payload folder is missing: $PayloadRoot"
}

# ------------------------------------------------------------
# Locate Sunrise
# ------------------------------------------------------------

$Candidates = @(
    "D:\ProjectSunrise",
    "C:\ProjectSunrise",
    "G:\ProjectSunrise"
)

$Sunrise = $null

foreach ($Candidate in $Candidates) {
    if (Test-Path (Join-Path $Candidate "destiny2.exe")) {
        $Sunrise = $Candidate
        break
    }
}

if (-not $Sunrise) {
    Write-Host "Project Sunrise was not found automatically." -ForegroundColor Yellow
    Write-Host ""
    $Sunrise = Read-Host "Enter your Project Sunrise folder"

    if ([string]::IsNullOrWhiteSpace($Sunrise)) {
        throw "No Project Sunrise folder was supplied."
    }

    $Sunrise = $Sunrise.Trim('"')
}

$GameExe = Join-Path $Sunrise "destiny2.exe"

if (-not (Test-Path $GameExe)) {
    throw "destiny2.exe was not found in: $Sunrise"
}

Write-Host "[OK] Project Sunrise found" -ForegroundColor Green
Write-Host "     $Sunrise"

# ------------------------------------------------------------
# Basic Sunrise validation
# ------------------------------------------------------------

$SunriseBin = Join-Path $Sunrise "bin\x64"

if (-not (Test-Path $SunriseBin)) {
    throw "This does not appear to be a valid Project Sunrise installation. Missing bin\x64."
}

Write-Host "[OK] Sunrise structure detected" -ForegroundColor Green

# ReShade may be named differently depending on setup.
$ReShadeCandidates = @(
    (Join-Path $Sunrise "ReShade64.dll"),
    (Join-Path $Sunrise "dxgi.dll"),
    (Join-Path $Sunrise "d3d11.dll")
)

$ReShadeFound = $false

foreach ($Candidate in $ReShadeCandidates) {
    if (Test-Path $Candidate) {
        $ReShadeFound = $true
        break
    }
}

if ($ReShadeFound) {
    Write-Host "[OK] ReShade installation detected" -ForegroundColor Green
}
else {
    Write-Host "[WARN] ReShade was not detected." -ForegroundColor Yellow
    Write-Host "       The feeder requires a compatible ReShade addon setup."
}

# ------------------------------------------------------------
# Prevent install while game is running
# ------------------------------------------------------------

$Running = Get-Process destiny2 -ErrorAction SilentlyContinue

if ($Running) {
    throw "Destiny 2 is currently running. Close Project Sunrise before installing."
}

# ------------------------------------------------------------
# Load payload manifest
# ------------------------------------------------------------

$ManifestPath = Join-Path $PayloadRoot "payload-manifest.json"

if (-not (Test-Path $ManifestPath)) {
    throw "payload-manifest.json is missing from the release."
}

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

if (-not $Manifest.files) {
    throw "Release payload manifest contains no files."
}

# Validate ALL source files before touching Sunrise.
foreach ($Entry in $Manifest.files) {
    $Source = Join-Path $PayloadRoot $Entry.source

    if (-not (Test-Path $Source)) {
        throw "Release payload is incomplete. Missing: $($Entry.source)"
    }
}

# ------------------------------------------------------------
# Backup
# ------------------------------------------------------------

$BackupRoot = Join-Path $Sunrise "_FSR3_DLSS5_BACKUP"
New-Item -ItemType Directory -Force -Path $BackupRoot | Out-Null

$InstallRecords = @()

foreach ($Entry in $Manifest.files) {
    $Source = Join-Path $PayloadRoot $Entry.source
    $Destination = Join-Path $Sunrise $Entry.destination

    $DestinationDir = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null

    $BackupRelative = $Entry.destination + ".bak"
    $BackupPath = Join-Path $BackupRoot $BackupRelative

    $BackupCreated = $false

    if (Test-Path $Destination) {
        $BackupDir = Split-Path -Parent $BackupPath
        New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null
        Copy-Item $Destination $BackupPath -Force
        $BackupCreated = $true
    }

    Copy-Item $Source $Destination -Force

    $SourceHash = (Get-FileHash $Source -Algorithm SHA256).Hash
    $DestHash = (Get-FileHash $Destination -Algorithm SHA256).Hash

    if ($SourceHash -ne $DestHash) {
        throw "Verification failed after installing: $($Entry.destination)"
    }

    $InstallRecords += [pscustomobject]@{
        destination = $Entry.destination
        backup      = $BackupRelative
        hadBackup   = $BackupCreated
        sha256      = $DestHash
    }

    Write-Host "[OK] Installed $($Entry.destination)" -ForegroundColor Green
}

# ------------------------------------------------------------
# Save uninstall manifest
# ------------------------------------------------------------

$InstalledManifest = Join-Path $BackupRoot "installed-manifest.json"

[pscustomobject]@{
    installedAt = (Get-Date).ToString("o")
    sunrisePath = $Sunrise
    files       = $InstallRecords
} |
    ConvertTo-Json -Depth 6 |
    Set-Content -Path $InstalledManifest -Encoding UTF8

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host " INSTALLATION COMPLETE" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Project Sunrise:"
Write-Host "  $Sunrise"
Write-Host ""
Write-Host "Launch Project Sunrise normally."
Write-Host ""
Write-Host "If something fails, check:"
Write-Host "  $Sunrise\host64\logs\status.log"
Write-Host ""

}
catch {
Write-Host ""
Write-Host "====================================================" -ForegroundColor Red
Write-Host " INSTALLATION FAILED" -ForegroundColor Red
Write-Host "====================================================" -ForegroundColor Red
Write-Host ""
Write-Host $_.Exception.Message -ForegroundColor Red
Write-Host ""
exit 1
}
