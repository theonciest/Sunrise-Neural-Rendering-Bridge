param(
    [string]$ProjectRoot = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Pass([string]$t) { Write-Host "[PASS] $t" -ForegroundColor Green }
function Info([string]$t) { Write-Host "[....] $t" -ForegroundColor Gray }

try {
    Write-Host ''
    Write-Host '============================================================' -ForegroundColor Cyan
    Write-Host ' STAR LIFTER — PROJECT SUNRISE INSTALLER' -ForegroundColor Cyan
    Write-Host '============================================================' -ForegroundColor Cyan

    $PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
    $PayloadRoot = Join-Path $PackageRoot 'payload'
    $ManifestPath = Join-Path $PayloadRoot 'payload-manifest.json'

    if (!(Test-Path -LiteralPath $ManifestPath)) { throw "Release payload manifest is missing: $ManifestPath" }

    $Sunrise = $null
    if ($ProjectRoot) {
        $candidate = $ProjectRoot.Trim('"')
        if (Test-Path -LiteralPath (Join-Path $candidate 'destiny2.exe')) { $Sunrise = (Resolve-Path -LiteralPath $candidate).Path }
    }
    if (!$Sunrise -and (Test-Path -LiteralPath (Join-Path $PackageRoot 'destiny2.exe'))) { $Sunrise = $PackageRoot }
    if (!$Sunrise) {
        foreach ($candidate in @('D:\ProjectSunriseNPCTest','D:\ProjectSunrise','C:\ProjectSunrise','G:\ProjectSunrise')) {
            if (Test-Path -LiteralPath (Join-Path $candidate 'destiny2.exe')) { $Sunrise = $candidate; break }
        }
    }
    if (!$Sunrise) { $Sunrise = (Read-Host 'Enter your Project Sunrise folder').Trim('"') }
    if (!(Test-Path -LiteralPath (Join-Path $Sunrise 'destiny2.exe'))) { throw "destiny2.exe was not found in: $Sunrise" }
    if (!(Test-Path -LiteralPath (Join-Path $Sunrise 'bin\x64'))) { throw 'This does not look like Project Sunrise: bin\x64 is missing.' }
    if (Get-Process destiny2 -ErrorAction SilentlyContinue) { throw 'Close Project Sunrise before installing.' }
    Pass "Project Sunrise: $Sunrise"

    $ProtectedSteam = Join-Path $Sunrise 'bin\x64\steam_api64.dll'
    $ProtectedSteamHash = if (Test-Path -LiteralPath $ProtectedSteam) { (Get-FileHash -LiteralPath $ProtectedSteam -Algorithm SHA256).Hash } else { '' }

    $Manifest = Get-Content -LiteralPath $ManifestPath -Raw | ConvertFrom-Json
    if (!$Manifest.files) { throw 'payload-manifest.json contains no files.' }
    foreach ($entry in $Manifest.files) {
        $source = Join-Path $PayloadRoot $entry.source
        if (!(Test-Path -LiteralPath $source -PathType Leaf)) { throw "Release ZIP is incomplete. Missing payload file: $($entry.source)" }
        $hash = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash
        if ($entry.sha256 -and $hash -ne $entry.sha256) { throw "Payload hash mismatch before install: $($entry.source)" }
    }
    Pass "Validated $(@($Manifest.files).Count) packaged runtime files."

    $UserRuntime = Join-Path $PackageRoot 'USER-RUNTIME\NVIDIA'
    $UserDlss = Join-Path $UserRuntime 'nvngx_dlss.dll'
    $UserNr   = Join-Path $UserRuntime 'nvngx_dlssnr.dll'
    if (!(Test-Path -LiteralPath $UserDlss) -or !(Test-Path -LiteralPath $UserNr)) {
        throw "NVIDIA runtime missing. Put legitimate nvngx_dlss.dll and nvngx_dlssnr.dll in:`n$UserRuntime`nThen run Install-Sunrise.bat again."
    }
    Pass 'User-supplied NVIDIA DLSS runtime found.'

    $Temp = Join-Path $env:TEMP ('STAR-LIFTER-INSTALL-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $Temp -Force | Out-Null

    try {
        $RenoZip = Join-Path $Temp 'renodx.zip'
        $RenoDir = Join-Path $Temp 'renodx'
        $RenoUrl = 'https://github.com/RankFTW/rhi-repo/releases/download/renodx-dlss5-4.60/renodx-dlss5_4.60.zip'
        Invoke-WebRequest -UseBasicParsing -Uri $RenoUrl -OutFile $RenoZip
        $RenoHash = (Get-FileHash -LiteralPath $RenoZip -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($RenoHash -ne 'ad30994ba898f3eed5a4c7953927db9759c680a71bc9d9855cac93e9ccc1e3c6') {
            throw "Pinned RenoDX 4.60 archive hash mismatch: $RenoHash"
        }
        Expand-Archive -LiteralPath $RenoZip -DestinationPath $RenoDir -Force
        $RenoAddon = Get-ChildItem -LiteralPath $RenoDir -Recurse -File -Filter 'renodx-dlss5.addon64' | Select-Object -First 1
        if (!$RenoAddon) { throw 'Pinned RenoDX archive did not contain renodx-dlss5.addon64.' }
        $RenoAddonHash = (Get-FileHash -LiteralPath $RenoAddon.FullName -Algorithm SHA256).Hash
        Pass 'Prepared pinned public RenoDX DLSS5 4.60 archive.'
        Info "Resolved RenoDX add-on SHA256: $RenoAddonHash"$LumZip = Join-Path $Temp 'lumenite.zip'
        $LumDir = Join-Path $Temp 'lumenite'
        $LumCommit = 'f8cbbb4eccfcb7adf0d74bb358ba349272e3c1e9'
        Invoke-WebRequest -UseBasicParsing -Uri "https://github.com/umar-afzaal/LumeniteFX/archive/$LumCommit.zip" -OutFile $LumZip
        Expand-Archive -LiteralPath $LumZip -DestinationPath $LumDir -Force
        $LumRoot = Get-ChildItem -LiteralPath $LumDir -Directory | Select-Object -First 1
        if (!$LumRoot -or !(Test-Path -LiteralPath (Join-Path $LumRoot.FullName 'Shaders\lumenite_Kernel.fx'))) { throw 'Pinned LumeniteFX archive is incomplete.' }
        Pass "Prepared pinned LumeniteFX commit $LumCommit."

        $BackupRoot = Join-Path $Sunrise ('_STAR_LIFTER_BACKUP\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
        New-Item -ItemType Directory -Path $BackupRoot -Force | Out-Null
        $records = @()
        foreach ($entry in $Manifest.files) {
            $dest = Join-Path $Sunrise $entry.destination
            $had = Test-Path -LiteralPath $dest
            if ($had) {
                $bak = Join-Path $BackupRoot $entry.destination
                New-Item -ItemType Directory -Path (Split-Path -Parent $bak) -Force | Out-Null
                Copy-Item -LiteralPath $dest -Destination $bak -Force
            }
            $records += [pscustomobject]@{ destination=$entry.destination; hadBackup=$had }
        }

        foreach ($entry in $Manifest.files) {
            $source = Join-Path $PayloadRoot $entry.source
            $dest = Join-Path $Sunrise $entry.destination
            New-Item -ItemType Directory -Path (Split-Path -Parent $dest) -Force | Out-Null
            Copy-Item -LiteralPath $source -Destination $dest -Force
            if ((Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $dest -Algorithm SHA256).Hash) { throw "Verification failed after copying: $($entry.destination)" }
        }

        $ShaderRoot = Join-Path $Sunrise 'reshade-shaders\Shaders'
        $TextureRoot = Join-Path $Sunrise 'reshade-shaders\Textures'
        New-Item -ItemType Directory -Path (Join-Path $ShaderRoot 'LumeniteFX') -Force | Out-Null
        Copy-Item -Path (Join-Path $LumRoot.FullName 'Shaders\*') -Destination (Join-Path $ShaderRoot 'LumeniteFX') -Recurse -Force
        if (Test-Path -LiteralPath (Join-Path $LumRoot.FullName 'Textures')) {
            New-Item -ItemType Directory -Path (Join-Path $TextureRoot 'LumeniteFX') -Force | Out-Null
            Copy-Item -Path (Join-Path $LumRoot.FullName 'Textures\*') -Destination (Join-Path $TextureRoot 'LumeniteFX') -Recurse -Force
        }

        $Host64 = Join-Path $Sunrise 'host64'
        Copy-Item -LiteralPath $RenoAddon.FullName -Destination (Join-Path $Host64 'renodx-dlss5.addon64') -Force
        Copy-Item -LiteralPath $UserDlss -Destination (Join-Path $Host64 'nvngx_dlss.dll') -Force
        Copy-Item -LiteralPath $UserNr   -Destination (Join-Path $Host64 'nvngx_dlssnr.dll') -Force

        & (Join-Path $Sunrise 'CONFIGURE-STAR-LIFTER.ps1') -ProjectRoot $Sunrise
        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) { throw "CONFIGURE-STAR-LIFTER.ps1 failed: $LASTEXITCODE" }

        $RequiredInstalled = @(
            'ReShade64.dll','dlss5-feed.addon64','dlss5-feed.cfg','SUNRISE-NRB.bat',
            'SunriseNRB\SunriseNRB.dll','SunriseNRB\SunriseNRB-Launcher.exe',
            'host64\dlss5-feed-host64.exe','host64\dxgi.dll','host64\ReShade.ini',
            'host64\renodx-dlss5.addon64','host64\nvngx_dlss.dll','host64\nvngx_dlssnr.dll',
            'reshade-shaders\Shaders\DLSS5_Feed.fx',
            'reshade-shaders\Shaders\KageBlink - HDR LOG Sliders.fx',
            'reshade-shaders\Shaders\KageBlink - SideBySide.fx',
            'reshade-shaders\Shaders\LumeniteFX\lumenite_Kernel.fx'
        )
        foreach ($rel in $RequiredInstalled) {
            if (!(Test-Path -LiteralPath (Join-Path $Sunrise $rel))) { throw "Post-install assertion failed: $rel" }
        }
        $InstalledRenoHash = (Get-FileHash -LiteralPath (Join-Path $Host64 'renodx-dlss5.addon64') -Algorithm SHA256).Hash
        if ($InstalledRenoHash -ne $RenoAddonHash) {
            throw 'Installed RenoDX add-on hash changed during copy.'
        }
        Pass "Installed RenoDX add-on SHA256: $InstalledRenoHash"if ($ProtectedSteamHash) {
            $afterSteam = (Get-FileHash -LiteralPath $ProtectedSteam -Algorithm SHA256).Hash
            if ($afterSteam -ne $ProtectedSteamHash) { throw 'PROTECTED steam_api64.dll changed during install. Stop and restore your Sunrise install.' }
        }

        [pscustomobject]@{
            installedAt=(Get-Date).ToString('o')
            sunrisePath=$Sunrise
            renodxArchiveSha256=$RenoHash
            renodxAddonSha256=$InstalledRenoHash
            files=$records
        } | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $BackupRoot 'installed-manifest.json') -Encoding UTF8Write-Host ''
        Write-Host '============================================================' -ForegroundColor Green
        Write-Host ' STAR LIFTER INSTALLATION COMPLETE' -ForegroundColor Green
        Write-Host '============================================================' -ForegroundColor Green
        Write-Host "Launch with: $Sunrise\SUNRISE-NRB.bat" -ForegroundColor Cyan
        Write-Host 'F4 panel | F5 Neural Rendering | F6 screenshots | F7 split | F8 HDR bypass'
    }
    finally {
        if (Test-Path -LiteralPath $Temp) { Remove-Item -LiteralPath $Temp -Recurse -Force -ErrorAction SilentlyContinue }
    }
}
catch {
    Write-Host ''
    Write-Host 'INSTALLATION FAILED' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
