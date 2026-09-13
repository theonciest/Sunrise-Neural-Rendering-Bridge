param(
    [Parameter(Mandatory)]
    [string]$SourcePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$SourcePath = (Resolve-Path -LiteralPath $SourcePath).Path
$text = [IO.File]::ReadAllText($SourcePath)

if ($text -match 'STAR LIFTER F5: Enable DLSS Neural Rendering') {
    Write-Host '[PASS] Star Lifter F5 patch already present.' -ForegroundColor Green
    exit 0
}

$helper = @'

// ---------------------------------------------------------------------------
// STAR LIFTER: deterministic game-side F5 Neural Rendering toggle.
//
// The host RenoDX add-on reads NeuralUplift from host64\ReShade.ini at startup.
// Its background global hotkey is deliberately disabled; the physical F5 press is
// observed here through ReShade's game-side input path, which is already reliable
// for feeder controls. HostClose() MUST happen before the INI write because the
// host ReShade saves its INI during shutdown and would otherwise clobber the value.
// ---------------------------------------------------------------------------
static void StarLifterToggleNeuralRenderingF5()
{
    char ini[MAX_PATH] = {};
    GetModuleFileNameA(g_self, ini, MAX_PATH);

    if (char *slash = strrchr(ini, '\\'))
        strcpy_s(slash + 1, MAX_PATH - (slash + 1 - ini), "host64\\ReShade.ini");
    else
    {
        Log("[feed32] STAR LIFTER F5: could not resolve host64\\ReShade.ini");
        return;
    }

    char value[32] = {};
    GetPrivateProfileStringA("RenoDX.DLSS5", "NeuralUplift", "1", value, sizeof(value), ini);
    const bool was_on = atoi(value) != 0;
    const bool now_on = !was_on;

    CaptureGameFocus();
    HostClose();

    if (!WritePrivateProfileStringA("RenoDX.DLSS5", "NeuralUplift", now_on ? "1" : "0", ini))
    {
        Log("[feed32] STAR LIFTER F5: FAILED writing NeuralUplift to %s (error %lu)", ini, GetLastError());
        return;
    }

    g.built = false;
    g.disabled = false;
    g.consecutive_fails = 0;
    g_retry_at = 0;
    g_disable_why[0] = '\0';

    Log("[feed32] STAR LIFTER F5: Enable DLSS Neural Rendering -> %s; host will respawn",
        now_on ? "ON" : "OFF");
}

'@

$castSig = '(?m)^\s*static\s+void\s+CastTick\s*\(\s*reshade::api::effect_runtime\s*\*\s*rt\s*\)\s*$'
$m = [regex]::Match($text, $castSig)
if (-not $m.Success) {
    throw 'Could not locate CastTick() in src/dlss5-feed32.cpp.'
}
$text = $text.Insert($m.Index, $helper)

$guard = '(?ms)(static\s+void\s+CastTick\s*\(\s*reshade::api::effect_runtime\s*\*\s*rt\s*\)\s*\{\s*if\s*\(\s*rt\s*!=\s*g\.runtime\s*\|\|\s*rt\s*==\s*nullptr\s*\)\s*return\s*;\s*)'
$g = [regex]::Match($text, $guard)
if (-not $g.Success) {
    throw 'Found CastTick(), but not its runtime guard.'
}

$inject = @'

    // STAR LIFTER: F5 owns the NeuralUplift A/B toggle.
    if (rt->is_key_pressed(VK_F5))
    {
        StarLifterToggleNeuralRenderingF5();
        return;
    }

'@
$text = $text.Insert($g.Index + $g.Length, $inject)

if ($text -notmatch 'is_key_pressed\(VK_F5\)' -or
    $text -notmatch 'WritePrivateProfileStringA\("RenoDX\.DLSS5",\s*"NeuralUplift"') {
    throw 'F5 patch verification failed before writing source.'
}

[IO.File]::WriteAllText($SourcePath, $text, (New-Object Text.UTF8Encoding($false)))
Write-Host '[PASS] Patched physical F5 -> host64\ReShade.ini NeuralUplift -> deterministic host restart.' -ForegroundColor Green
