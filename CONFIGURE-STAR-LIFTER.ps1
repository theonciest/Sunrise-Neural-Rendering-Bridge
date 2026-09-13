param(
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Pass([string]$Text) { Write-Host "[PASS] $Text" -ForegroundColor Green }
function Write-Info([string]$Text) { Write-Host "[....] $Text" -ForegroundColor Gray }

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$ReShadeIni = Join-Path $ProjectRoot 'ReShade.ini'
$ShaderDir  = Join-Path $ProjectRoot 'reshade-shaders\Shaders'
$SideBySide = Join-Path $ShaderDir 'KageBlink - SideBySide.fx'
$HdrShader  = Join-Path $ShaderDir 'KageBlink - HDR LOG Sliders.fx'

if (-not (Test-Path -LiteralPath $ReShadeIni -PathType Leaf)) {
    throw "ReShade.ini was not found at: $ReShadeIni`nInstall ReShade 6.8.0 with Add-on Support first, then run this configurator."
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backup = "$ReShadeIni.BEFORE-STAR-LIFTER-$stamp"
Copy-Item -LiteralPath $ReShadeIni -Destination $backup -Force
Write-Pass "Backed up ReShade.ini -> $backup"

function Set-IniValue {
    param(
        [Parameter(Mandatory)] [string]$Text,
        [Parameter(Mandatory)] [string]$Section,
        [Parameter(Mandatory)] [string]$Key,
        [Parameter(Mandatory)] [string]$Value
    )

    $sectionPattern = '(?ms)^\[' + [regex]::Escape($Section) + '\]\s*\r?\n(?<body>.*?)(?=^\[|\z)'
    $sectionMatch = [regex]::Match($Text, $sectionPattern)

    if (-not $sectionMatch.Success) {
        if ($Text.Length -gt 0 -and -not $Text.EndsWith("`n")) { $Text += "`r`n" }
        return $Text + "`r`n[$Section]`r`n$Key=$Value`r`n"
    }

    $body = $sectionMatch.Groups['body'].Value
    $keyPattern = '(?m)^' + [regex]::Escape($Key) + '\s*=.*$'
    if ([regex]::IsMatch($body, $keyPattern)) {
        $body = [regex]::Replace($body, $keyPattern, "$Key=$Value", 1)
    } else {
        $body = "$Key=$Value`r`n" + $body
    }

    return $Text.Substring(0, $sectionMatch.Groups['body'].Index) + $body + $Text.Substring($sectionMatch.Groups['body'].Index + $sectionMatch.Groups['body'].Length)
}

$iniText = [IO.File]::ReadAllText($ReShadeIni)

# ReShade 6.8 input mode 2 blocks all game mouse/keyboard input while the overlay is open.
$iniText = Set-IniValue $iniText 'INPUT' 'InputProcessing' '2'

# Ctrl + Shift + O = ReShade overlay.
$iniText = Set-IniValue $iniText 'INPUT' 'KeyOverlay' '79,1,1,0'

# F6 = screenshot. SaveBeforeShot=1 makes the same key create Before + After images.
# F5 is reserved for Star Lifter's game-side DLSS Neural Rendering toggle.
$iniText = Set-IniValue $iniText 'INPUT' 'KeyScreenshot' '117,0,0,0'
$iniText = Set-IniValue $iniText 'SCREENSHOT' 'SaveBeforeShot' '1'

# Free the old F6 global effect-chain binding so it cannot collide with screenshots.
$iniText = Set-IniValue $iniText 'INPUT' 'KeyEffects' '0,0,0,0'

$iniText = Set-IniValue $iniText 'OVERLAY' 'ShowScreenshotMessage' '1'

[IO.File]::WriteAllText($ReShadeIni, $iniText, (New-Object Text.UTF8Encoding($false)))
Write-Pass 'ReShade input + comparison hotkeys configured.'
Write-Host '       Ctrl + Shift + O = ReShade overlay'
Write-Host '       F4               = DLSS 5 feeder panel (feeder-owned)'
Write-Host '       F5               = Toggle DLSS Neural Rendering (feeder-owned)'
Write-Host '       F6               = Before + After screenshot pair'
Write-Host '       F7               = Toggle Star Lifter side-by-side (shader-owned)'
Write-Host '       F8               = Toggle KageBlink HDR grading (shader-owned)'

if (Test-Path -LiteralPath $SideBySide) { Write-Pass "Comparison shader present: $SideBySide" }
else { Write-Warning "Missing comparison shader: $SideBySide" }
if (Test-Path -LiteralPath $HdrShader) { Write-Pass "HDR grading shader present: $HdrShader" }
else { Write-Warning "Missing HDR grading shader: $HdrShader" }

# Reorder comparison techniques in the active preset when ReShade.ini points at one.
$generalMatch = [regex]::Match($iniText, '(?ms)^\[GENERAL\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
$presetPath = $null
if ($generalMatch.Success) {
    $m = [regex]::Match($generalMatch.Groups['body'].Value, '(?m)^PresetPath\s*=\s*(.+?)\s*$')
    if ($m.Success -and $m.Groups[1].Value.Trim()) {
        $presetRaw = $m.Groups[1].Value.Trim().Trim('"')
        if ([IO.Path]::IsPathRooted($presetRaw)) { $presetPath = $presetRaw }
        else { $presetPath = Join-Path $ProjectRoot $presetRaw }
    }
}

if ($presetPath -and (Test-Path -LiteralPath $presetPath -PathType Leaf)) {
    $presetBackup = "$presetPath.BEFORE-STAR-LIFTER-$stamp"
    Copy-Item -LiteralPath $presetPath -Destination $presetBackup -Force
    $preset = [IO.File]::ReadAllText($presetPath)

    $capture = 'DLSSCompare_Capture@KageBlink - SideBySide.fx'
    $output  = 'DLSSCompare_Output@KageBlink - SideBySide.fx'

    foreach ($key in @('Techniques','TechniqueSorting')) {
        $pattern = '(?m)^' + $key + '=(.*)$'
        $match = [regex]::Match($preset, $pattern)
        if (-not $match.Success) { continue }

        $items = @($match.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
        $items = @($items | Where-Object {
            $_ -notmatch '^DLSSCompare_Capture@' -and $_ -notmatch '^DLSSCompare_Output@'
        })

        $ordered = @($capture) + $items + @($output)
        $line = $key + '=' + ($ordered -join ',')
        $preset = [regex]::Replace($preset, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($x) $line }, 1)
    }

    [IO.File]::WriteAllText($presetPath, $preset, (New-Object Text.UTF8Encoding($false)))
    Write-Pass "Preset ordering fixed: $presetPath"
    Write-Host '       DLSSCompare_Capture = FIRST / TOP'
    Write-Host '       DLSSCompare_Output  = LAST / BOTTOM'
} else {
    Write-Info 'No active preset file was resolved automatically.'
    Write-Host '       In ReShade, keep DLSSCompare_Capture at the very top and DLSSCompare_Output at the very bottom.'
}

Write-Host ''
Write-Host 'STAR 💫 LIFTER ReShade configuration complete.' -ForegroundColor Cyan
Write-Host 'Restart Project Sunrise / ReShade once so the new input settings are guaranteed to load.'
