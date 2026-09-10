$ErrorActionPreference = "Stop"

try {
    $Repo = Split-Path -Parent $PSScriptRoot

    $Version = "0.1.0"
    $PackageName = "FSR3-DLSS5-Feeder-Sunrise-v$Version"

    $ReleaseRoot = Join-Path $Repo "release"
    $Payload = Join-Path $ReleaseRoot "payload"
    $StageRoot = Join-Path $ReleaseRoot "stage"
    $Stage = Join-Path $StageRoot $PackageName
    $Zip = Join-Path $ReleaseRoot "$PackageName.zip"

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host " FSR3-DLSS5-FEEDER - SUNRISE RELEASE BUILDER" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""

    # ------------------------------------------------------------
    # Exact Project Sunrise release components
    # ------------------------------------------------------------

    $Files = @(
        [pscustomobject]@{
            Source      = "build\dlss5-feed.addon64"
            PayloadPath = "dlss5-feed.addon64"
            Destination = "dlss5-feed.addon64"
        },
        [pscustomobject]@{
            Source      = "host\dlss5-feed-host64.exe"
            PayloadPath = "host64\dlss5-feed-host64.exe"
            Destination = "host64\dlss5-feed-host64.exe"
        }
    )

    # Validate EVERYTHING before modifying release output.
    foreach ($Item in $Files) {
        $SourcePath = Join-Path $Repo $Item.Source

        if (-not (Test-Path $SourcePath)) {
            throw "Required build output missing: $($Item.Source)"
        }
    }

    $RequiredTopLevel = @(
        "Install-Sunrise.bat",
        "Install-Sunrise.ps1",
        "Uninstall-Sunrise.bat",
        "Uninstall-Sunrise.ps1",
        "README.md",
        "THIRD-PARTY-NOTICES.md",
        "LICENSE"
    )

    foreach ($Name in $RequiredTopLevel) {
        if (-not (Test-Path (Join-Path $Repo $Name))) {
            throw "Required release file missing: $Name"
        }
    }

    # ------------------------------------------------------------
    # Rebuild payload
    # ------------------------------------------------------------

    if (Test-Path $Payload) {
        Remove-Item $Payload -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $Payload | Out-Null

    $ManifestEntries = @()

    foreach ($Item in $Files) {
        $SourcePath = Join-Path $Repo $Item.Source
        $PayloadPath = Join-Path $Payload $Item.PayloadPath
        $PayloadDir = Split-Path -Parent $PayloadPath

        New-Item -ItemType Directory -Force -Path $PayloadDir | Out-Null
        Copy-Item $SourcePath $PayloadPath -Force

        $Hash = (Get-FileHash $PayloadPath -Algorithm SHA256).Hash

        $ManifestEntries += [pscustomobject]@{
            source      = $Item.PayloadPath
            destination = $Item.Destination
            sha256      = $Hash
        }

        Write-Host "[OK] $($Item.Source)" -ForegroundColor Green
        Write-Host "     -> Sunrise\$($Item.Destination)"
    }

    $Manifest = [pscustomobject]@{
        formatVersion = 1
        version       = $Version
        generatedAt   = (Get-Date).ToString("o")
        files         = $ManifestEntries
    }

    $Manifest |
        ConvertTo-Json -Depth 8 |
        Set-Content (Join-Path $Payload "payload-manifest.json") -Encoding UTF8

    Write-Host ""
    Write-Host "[OK] Payload manifest created" -ForegroundColor Green

    # ------------------------------------------------------------
    # Build clean release folder
    # ------------------------------------------------------------

    if (Test-Path $Stage) {
        Remove-Item $Stage -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $Stage | Out-Null

    foreach ($Name in $RequiredTopLevel) {
        Copy-Item (Join-Path $Repo $Name) (Join-Path $Stage $Name) -Force
    }

    Copy-Item $Payload (Join-Path $Stage "payload") -Recurse -Force

    $LicenseDir = Join-Path $Stage "licenses"
    New-Item -ItemType Directory -Force -Path $LicenseDir | Out-Null

    Copy-Item `
        (Join-Path $Repo "LICENSE") `
        (Join-Path $LicenseDir "DLSS5-Feeder-MIT-LICENSE.txt") `
        -Force

    # ------------------------------------------------------------
    # Release information
    # ------------------------------------------------------------

    $Info = @"
FSR3-DLSS5-Feeder for Project Sunrise
Version: $Version

INSTALL:
    Double-click Install-Sunrise.bat

UNINSTALL:
    Double-click Uninstall-Sunrise.bat

The installer will attempt to locate Project Sunrise automatically.

Expected working layout:

    ProjectSunrise\
        dlss5-feed.addon64
        host64\
            dlss5-feed-host64.exe

The installer does not replace Project Sunrise itself.

FSR3 Frame Generation remains experimental.
Generated-frame presentation into the visible game presentation chain
is not yet implemented.

See README.md and THIRD-PARTY-NOTICES.md for details.
"@

    Set-Content `
        (Join-Path $Stage "README-FIRST.txt") `
        $Info `
        -Encoding UTF8

    # ------------------------------------------------------------
    # Verify staged payload
    # ------------------------------------------------------------

    foreach ($Entry in $ManifestEntries) {
        $Staged = Join-Path (Join-Path $Stage "payload") $Entry.source

        if (-not (Test-Path $Staged)) {
            throw "Staged payload verification failed: $($Entry.source)"
        }

        $Hash = (Get-FileHash $Staged -Algorithm SHA256).Hash

        if ($Hash -ne $Entry.sha256) {
            throw "Hash verification failed: $($Entry.source)"
        }
    }

    Write-Host "[OK] Staged payload verified" -ForegroundColor Green

    # ------------------------------------------------------------
    # ZIP
    # ------------------------------------------------------------

    if (Test-Path $Zip) {
        Remove-Item $Zip -Force
    }

    Compress-Archive `
        -Path (Join-Path $Stage "*") `
        -DestinationPath $Zip `
        -CompressionLevel Optimal

    if (-not (Test-Path $Zip)) {
        throw "ZIP creation failed."
    }

    $ZipHash = (Get-FileHash $Zip -Algorithm SHA256).Hash
    $ZipSize = (Get-Item $Zip).Length

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host " RELEASE READY" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""

    Write-Host "Package:"
    Write-Host "  $Zip" -ForegroundColor Cyan

    Write-Host ""
    Write-Host "Size:"
    Write-Host "  $ZipSize bytes"

    Write-Host ""
    Write-Host "SHA256:"
    Write-Host "  $ZipHash"

    Write-Host ""
    Write-Host "Sunrise files included:" -ForegroundColor Cyan

    foreach ($Entry in $ManifestEntries) {
        Write-Host "  $($Entry.destination)"
    }

    Write-Host ""
    Write-Host "NOT INCLUDED:" -ForegroundColor Yellow
    Write-Host "  dlss5-feed-hostclient.addon64"
    Write-Host "  Project Sunrise binaries"
    Write-Host "  ReShade binaries"
    Write-Host "  NVIDIA SDK/runtime files"
    Write-Host "  unrelated Vulkan development trees"
    Write-Host ""
}
catch {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host " RELEASE BUILD FAILED" -ForegroundColor Red
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
