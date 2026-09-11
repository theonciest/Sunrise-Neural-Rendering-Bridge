# Sunrise Neural Rendering Bridge v0.1.1-alpha

**Pass 1 coexistence release.**

This release locks in the V7 architecture that keeps Project Sunrise, ReShade 6.8.0, and the DLSS5 feeder alive together.

## Fixed

- Project Sunrise **Insert** UI now survives the bridge.
- ReShade **Home** overlay remains available.
- DLSS Neural Rendering remains active.
- Removed the old timing-sweep architecture.
- Removed remote ReShade injection.
- Project Sunrise's protected `steam_api64.dll` is never replaced.

## Root cause

Project Sunrise creates a hidden 64×64 D3D11/DXGI swap chain to discover the real system `IDXGISwapChain` vtable. ReShade normally proxies that temporary swap chain, which makes Sunrise correctly reject it because the vtable no longer belongs to the system `dxgi.dll` image.

The bundled ReShade 6.8.0 compatibility build leaves **only that exact opt-in 64×64 probe** unproxied. The real Destiny swap chain remains ReShade-proxied.

## Validated configuration

- NVIDIA GeForce RTX 3080 Ti 12 GB
- Project Sunrise protected `steam_api64.dll` SHA-256:
  `EEF191955C803D7A4B0BDC079ABEC519CD2BFD0C3909C7C19B6B7BAA078553DB`
- ReShade 6.8.0 source commit:
  `18deaa52de0c425a78b329e9cb3c497281cd00ec`
- Microsoft Detours 4.0.1 source commit:
  `e4bfd6b03e50de46b47abfbd1e46b384f0c5f833`

The live validation observed:

```text
MODULE SunriseNRB.dll observed
MODULE steam_api64.dll observed
MODULE ReShade64.dll observed
PASS module chain alive: bridge + Sunrise + patched ReShade
launcher handoff complete; processExit=0x00000103 bridge=1 steam=1 reshade=1
```

`0x00000103` is Windows `STILL_ACTIVE`.

## Known remaining work

- Neural Rendering Work Scale below 50% remains the next validation target.
- FSR3 Frame Generation presentation remains experimental.

## Distribution

The release does **not** include:

- `steam_api64.dll`
- `destiny2.exe`
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

Users supply NVIDIA runtime binaries separately.

ReShade and Microsoft Detours notices are included with the release.
