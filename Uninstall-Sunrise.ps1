
$ErrorActionPreference = "Stop"

try {
Write-Host ""
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host " FSR3-DLSS5-FEEDER - PROJECT SUNRISE UNINSTALLER" -ForegroundColor Cyan
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

$Candidates = @(
    "D:\ProjectSunrise",
    "C:\ProjectSunrise",
    "G:\ProjectSunrise"
)

$Sunrise = $null

foreach ($Candidate in $Candidates) {
    if (Test-Path (Join-Path $Candidate "_FSR3_DLSS5_BACKUP\installed-manifest.json")) {
        $Sunrise = $Candidate
        break
    }
}

if (-not $Sunrise) {
    $Sunrise = Read-Host "Enter your Project Sunrise folder"

    if ([string]::IsNullOrWhiteSpace($Sunrise)) {
        throw "No Project Sunrise folder supplied."
    }

    $Sunrise = $Sunrise.Trim('"')
}

if (Get-Process destiny2 -ErrorAction SilentlyContinue) {
    throw "Destiny 2 is currently running. Close Project Sunrise before uninstalling."
}

$BackupRoot = Join-Path $Sunrise "_FSR3_DLSS5_BACKUP"
$ManifestPath = Join-Path $BackupRoot "installed-manifest.json"

if (-not (Test-Path $ManifestPath)) {
    throw "No FSR3-DLSS5-Feeder installation manifest was found."
}

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

foreach ($Entry in $Manifest.files) {
    $Destination = Join-Path $Sunrise $Entry.destination
    $Backup = Join-Path $BackupRoot $Entry.backup

    if ($Entry.hadBackup -and (Test-Path $Backup)) {
        $DestinationDir = Split-Path -Parent $Destination
        New-Item -ItemType Directory -Force -Path $DestinationDir | Out-Null

        Copy-Item $Backup $Destination -Force

        Write-Host "[OK] Restored $($Entry.destination)" -ForegroundColor Green
    }
    else {
        if (Test-Path $Destination) {
            Remove-Item $Destination -Force
            Write-Host "[OK] Removed $($Entry.destination)" -ForegroundColor Green
        }
    }
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host " UNINSTALL COMPLETE" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Original files were restored where backups existed."

}
catch {
Write-Host ""
Write-Host "====================================================" -ForegroundColor Red
Write-Host " UNINSTALL FAILED" -ForegroundColor Red
Write-Host "====================================================" -ForegroundColor Red
Write-Host ""
Write-Host $_.Exception.Message -ForegroundColor Red
Write-Host ""
exit 1
}
