param(
    [Parameter(Mandatory=$true)]
    [string]$ReShadeRoot
)

$ErrorActionPreference = 'Stop'

$dxgiCpp = Join-Path $ReShadeRoot 'source\dxgi\dxgi.cpp'
if (-not (Test-Path -LiteralPath $dxgiCpp)) {
    throw "Missing ReShade source file: $dxgiCpp"
}

$text = [IO.File]::ReadAllText($dxgiCpp)
$needle = "`tDXGISwapChain *swapchain_proxy = nullptr;"
$count = ([regex]::Matches($text, [regex]::Escape($needle))).Count
if ($count -ne 1) {
    throw "Expected exactly one ReShade 6.8.0 insertion point; found $count"
}

$replacement = @'
	DXGISwapChain *swapchain_proxy = nullptr;

	// Sunrise NRB compatibility contract:
	// Project Sunrise creates one tiny hidden classic DXGI swap chain solely to discover
	// the real system IDXGISwapChain vtable. ReShade normally wraps that probe in its
	// DXGISwapChain proxy, causing Sunrise to reject the vtable because it no longer
	// belongs to the system dxgi.dll image. Leave ONLY the exact opt-in 64x64 discovery
	// probe raw. Normal game swap chains remain fully proxied by ReShade.
	wchar_t sunrise_probe_class[32] = {};
	const bool sunrise_probe_static_window =
		orig_desc.OutputWindow != nullptr &&
		GetClassNameW(orig_desc.OutputWindow, sunrise_probe_class, ARRAYSIZE(sunrise_probe_class)) > 0 &&
		lstrcmpiW(sunrise_probe_class, L"STATIC") == 0;
	const bool sunrise_probe_exact =
		GetEnvironmentVariableW(L"SUNRISE_NRB_PROBE_COMPAT", nullptr, 0) != 0 &&
		sunrise_probe_static_window &&
		orig_desc.BufferDesc.Width == 64 &&
		orig_desc.BufferDesc.Height == 64 &&
		orig_desc.BufferDesc.RefreshRate.Numerator == 0 &&
		orig_desc.BufferDesc.RefreshRate.Denominator == 0 &&
		orig_desc.BufferDesc.Format == DXGI_FORMAT_R8G8B8A8_UNORM &&
		orig_desc.BufferDesc.ScanlineOrdering == DXGI_MODE_SCANLINE_ORDER_UNSPECIFIED &&
		orig_desc.BufferDesc.Scaling == DXGI_MODE_SCALING_UNSPECIFIED &&
		orig_desc.SampleDesc.Count == 1 &&
		orig_desc.SampleDesc.Quality == 0 &&
		orig_desc.BufferUsage == DXGI_USAGE_RENDER_TARGET_OUTPUT &&
		orig_desc.BufferCount == 1 &&
		orig_desc.Windowed != FALSE &&
		orig_desc.SwapEffect == DXGI_SWAP_EFFECT_DISCARD &&
		orig_desc.Flags == 0;

	if (sunrise_probe_exact)
	{
		reshade::log::message(reshade::log::level::info,
			"[Sunrise NRB] Exact 64x64 Sunrise DXGI discovery probe detected; leaving swap chain unproxied.");
		return;
	}
'@

$text = $text.Replace($needle, $replacement)

if (-not $text.Contains('Exact 64x64 Sunrise DXGI discovery probe detected')) {
    throw 'Patch verification failed.'
}

[IO.File]::WriteAllText($dxgiCpp, $text, (New-Object Text.UTF8Encoding($false)))
Write-Host '[PASS] ReShade 6.8.0 Sunrise probe-compat patch applied.' -ForegroundColor Green
