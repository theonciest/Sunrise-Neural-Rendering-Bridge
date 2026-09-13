param(
    [string]$ProjectRoot = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Pass([string]$Text) { Write-Host "[PASS] $Text" -ForegroundColor Green }
function Info([string]$Text) { Write-Host "[....] $Text" -ForegroundColor Gray }

$ProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$ReShadeIni = Join-Path $ProjectRoot 'ReShade.ini'
$PresetPath = Join-Path $ProjectRoot 'ReShadePreset.ini'
$ShaderDir  = Join-Path $ProjectRoot 'reshade-shaders\Shaders'

if (!(Test-Path -LiteralPath $ReShadeIni -PathType Leaf)) {
    throw "ReShade.ini was not found at: $ReShadeIni`nInstall/launch ReShade once, then run this configurator."
}

$required = @(
    (Join-Path $ShaderDir 'DLSS5_Feed.fx'),
    (Join-Path $ShaderDir 'KageBlink - SideBySide.fx'),
    (Join-Path $ShaderDir 'KageBlink - HDR LOG Sliders.fx'),
    (Join-Path $ShaderDir 'LumeniteFX\lumenite_Kernel.fx')
)
foreach ($p in $required) {
    if (!(Test-Path -LiteralPath $p -PathType Leaf)) { throw "Required Star Lifter shader is missing: $p" }
}

$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$iniBackup = "$ReShadeIni.BEFORE-STAR-LIFTER-$stamp"
Copy-Item -LiteralPath $ReShadeIni -Destination $iniBackup -Force
Pass "Backed up ReShade.ini -> $iniBackup"
if (Test-Path -LiteralPath $PresetPath) {
    Copy-Item -LiteralPath $PresetPath -Destination "$PresetPath.BEFORE-STAR-LIFTER-$stamp" -Force
}

function Set-IniValue {
    param([string]$Text,[string]$Section,[string]$Key,[string]$Value)
    $sectionPattern = '(?ms)^\[' + [regex]::Escape($Section) + '\]\s*\r?\n(?<body>.*?)(?=^\[|\z)'
    $m = [regex]::Match($Text, $sectionPattern)
    if (!$m.Success) {
        if ($Text.Length -gt 0 -and !$Text.EndsWith("`n")) { $Text += "`r`n" }
        return $Text + "`r`n[$Section]`r`n$Key=$Value`r`n"
    }
    $body = $m.Groups['body'].Value
    $keyPattern = '(?m)^' + [regex]::Escape($Key) + '\s*=.*$'
    if ([regex]::IsMatch($body, $keyPattern)) { $body = [regex]::Replace($body, $keyPattern, "$Key=$Value", 1) }
    else { $body = "$Key=$Value`r`n" + $body }
    return $Text.Substring(0,$m.Groups['body'].Index) + $body + $Text.Substring($m.Groups['body'].Index + $m.Groups['body'].Length)
}

function Merge-Definition([string]$Existing,[string]$Wanted) {
    $items = @($Existing -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $key = ($Wanted -split '=',2)[0]
    $items = @($items | Where-Object { $_ -notmatch ('^' + [regex]::Escape($key) + '=') })
    return (@($items) + $Wanted) -join ','
}

$ini = [IO.File]::ReadAllText($ReShadeIni)
$ini = Set-IniValue $ini 'INPUT' 'InputProcessing' '2'
$ini = Set-IniValue $ini 'INPUT' 'KeyOverlay' '79,1,1,0'
$ini = Set-IniValue $ini 'INPUT' 'KeyScreenshot' '117,0,0,0'
$ini = Set-IniValue $ini 'INPUT' 'KeyEffects' '0,0,0,0'
$ini = Set-IniValue $ini 'SCREENSHOT' 'SaveBeforeShot' '1'
$ini = Set-IniValue $ini 'OVERLAY' 'ShowScreenshotMessage' '1'
$ini = Set-IniValue $ini 'GENERAL' 'PresetPath' '.\ReShadePreset.ini'

$defs = ''
$gm = [regex]::Match($ini, '(?ms)^\[GENERAL\]\s*\r?\n(?<body>.*?)(?=^\[|\z)')
if ($gm.Success) {
    $dm = [regex]::Match($gm.Groups['body'].Value, '(?m)^PreprocessorDefinitions\s*=\s*(.*?)\s*$')
    if ($dm.Success) { $defs = $dm.Groups[1].Value }
}
$defs = Merge-Definition $defs 'DLSS5_MV_PROVIDER=3'
$ini = Set-IniValue $ini 'GENERAL' 'PreprocessorDefinitions' $defs
[IO.File]::WriteAllText($ReShadeIni, $ini, (New-Object Text.UTF8Encoding($false)))

# Build a deterministic preset chain. Preserve any unrelated techniques, but force the
# Star Lifter capture/provider/feed/grading/output ordering around them.
$preset = if (Test-Path -LiteralPath $PresetPath) { [IO.File]::ReadAllText($PresetPath) } else { '' }
$capture = 'DLSSCompare_Capture@KageBlink - SideBySide.fx'
$kernel  = 'Lumenite_Kernel@LumeniteFX\lumenite_Kernel.fx'
$feed    = 'DLSS5_Feed@DLSS5_Feed.fx'
$hdr     = 'KB_HDR_LogWheels@KageBlink - HDR LOG Sliders.fx'
$output  = 'DLSSCompare_Output@KageBlink - SideBySide.fx'
$ours = @($capture,$kernel,$feed,$hdr,$output)

function Set-TechniqueList([string]$Text,[string]$Key) {
    $pattern = '(?m)^' + [regex]::Escape($Key) + '=(.*)$'
    $existing = @()
    $m = [regex]::Match($Text,$pattern)
    if ($m.Success) {
        $existing = @($m.Groups[1].Value -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    }
    $existing = @($existing | Where-Object { $ours -notcontains $_ })
    $ordered = @($capture,$kernel,$feed,$hdr) + $existing + @($output)
    $line = $Key + '=' + ($ordered -join ',')
    if ($m.Success) { return [regex]::Replace($Text,$pattern,[System.Text.RegularExpressions.MatchEvaluator]{ param($x) $line },1) }
    if ($Text.Length -gt 0 -and !$Text.EndsWith("`n")) { $Text += "`r`n" }
    return $Text + $line + "`r`n"
}

$preset = Set-TechniqueList $preset 'Techniques'
$preset = Set-TechniqueList $preset 'TechniqueSorting'
[IO.File]::WriteAllText($PresetPath, $preset, (New-Object Text.UTF8Encoding($false)))

Pass 'Configured DLSS5_MV_PROVIDER=3 (LumeniteFX Kernel).'
Pass 'Configured deterministic Star Lifter effect order:'
Write-Host '       1. DLSSCompare_Capture'
Write-Host '       2. Lumenite_Kernel'
Write-Host '       3. DLSS5_Feed'
Write-Host '       4. KB_HDR_LogWheels'
Write-Host '       ...existing unrelated effects...'
Write-Host '       LAST: DLSSCompare_Output'
Write-Host ''
Write-Host 'Controls:' -ForegroundColor Cyan
Write-Host '  Ctrl + Shift + O = ReShade overlay'
Write-Host '  Insert           = Project Sunrise UI'
Write-Host '  F4               = DLSS 5 feeder panel'
Write-Host '  F5               = Toggle DLSS Neural Rendering'
Write-Host '  F6               = Before + After screenshot pair'
Write-Host '  F7               = Side-by-side comparison'
Write-Host '  F8               = HDR grading bypass'
Write-Host ''
Pass 'STAR LIFTER configuration complete.'
