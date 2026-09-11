# Sunrise Neural Rendering Bridge

**DLSS Neural Rendering for Project Sunrise via a D3D11 → D3D12 external host.**

## Validated coexistence architecture

As of **v0.1.1-alpha**, the tested Project Sunrise path keeps all three components alive at the same time:

- Project Sunrise / `steam_api64.dll`
- ReShade 6.8.0 + DLSS5 feeder
- Sunrise NRB Detours bridge

The compatibility fix is intentionally narrow: ReShade continues to proxy the real Destiny swap chain, but leaves Project Sunrise's exact hidden **64×64 DXGI discovery probe** unproxied so Sunrise can resolve the real system `dxgi.dll` vtable.

On the validated RTX 3080 Ti configuration:

- **Home** opens ReShade.
- **Insert** opens the Project Sunrise UI.
- DLSS Neural Rendering remains active.
- Project Sunrise's protected `steam_api64.dll` remains byte-for-byte unchanged.

## Requirements

- A working Project Sunrise install
- NVIDIA RTX GPU
- Current NVIDIA graphics driver
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

> NVIDIA runtime files are not included.

## Install

1. Download the latest release and extract its **contents** into the Project Sunrise root, next to `destiny2.exe`.
2. Put your own legitimate NVIDIA runtime files in `USER-RUNTIME\NVIDIA\`:
   - `nvngx_dlss.dll`
   - `nvngx_dlssnr.dll`
3. Run the included NVIDIA runtime bootstrapper if the release provides it.
4. Launch with:

   `SUNRISE-NRB.bat`

Do **not** replace Project Sunrise's `bin\x64\steam_api64.dll`.

The V7 launcher injects one small bridge DLL. That bridge waits until Project Sunrise's Steam module exists, then immediately loads the patched ReShade build. There is no post-module timing sweep and no remote ReShade injection.

## Controls

- **Home** → ReShade
- **Insert** → Project Sunrise UI

The separate D3D12 host window is expected and should remain open while using the bridge.

## Status

| Feature | Status |
|---|---|
| D3D11 → D3D12 bridge | ✅ Working |
| Color / depth / motion transport | ✅ Working |
| DLSS Neural Rendering | ✅ Working |
| ReShade / Sunrise coexistence | ✅ Working |
| Project Sunrise Insert UI | ✅ Working |
| Neural Rendering Work Scale | ✅ 50–100%; below 50% is the next validation target |
| FSR3 Frame Generation | 🧪 Experimental |

## Pass-1 validation authority

The September 11, 2026 validation run observed the complete live module chain and left Destiny running:

```text
MODULE SunriseNRB.dll observed
MODULE steam_api64.dll observed
MODULE ReShade64.dll observed
PASS module chain alive: bridge + Sunrise + patched ReShade
launcher handoff complete; processExit=0x00000103 bridge=1 steam=1 reshade=1
```

Local tested hashes:

```text
Protected Project Sunrise steam_api64.dll
EEF191955C803D7A4B0BDC079ABEC519CD2BFD0C3909C7C19B6B7BAA078553DB

Patched ReShade64.dll
9E85F8644830338F48EF6F4DB4E0BAE66F0B3FAF9BE2189CEF26F3B65B4A8E18

V7 bridge
0977BCD616771A71D9E3CB78C510C1D3A03AF5265A4E465AB61B64CFDA88920F

V7 launcher
43EC5E9EF325B4EDEE7B7F44176C9DB6CD73A05F6E2B01A38D6D9B2B63CB5714

DLSS5 feed
CCC162E899B132BCDA3F80C5AE3309F0EE0FAB6254B98D0C5DA2F986AF52EE93
```

CI-built portable binaries may have different hashes because of toolchain/build metadata; the source architecture and ReShade compatibility rule are locked under `sunrise/v7/`.

## How it works

```text
SUNRISE-NRB.bat
      │
      ▼
Detours V7 launcher
      │ injects one bridge DLL
      ▼
destiny2.exe
      │
      ├── Project Sunrise steam_api64.dll
      │
      └── SunriseNRB.dll worker
                │ waits for steam_api64.dll
                │ zero post-module delay
                ▼
         patched ReShade 6.8.0
                │
                ├── real Destiny swap chain → normal ReShade proxy
                └── exact Sunrise 64×64 probe → raw system DXGI object
```

The feeder transports D3D11 color, depth, motion, and rendering metadata through shared GPU resources / IPC to the external D3D12 host.

## NVIDIA runtime

NVIDIA proprietary runtime binaries are **not** shipped by this repository. Users supply legitimate copies separately.

## Source / upstream

This repository is a Project Sunrise-focused fork of **DLSS5-Feeder by Jean-Laurent ROUZIES**.

- Upstream feeder: `jlrouzies-fr/DLSS5-Feeder`
- ReShade: `crosire/reshade`
- Microsoft Detours: `microsoft/Detours`

See `THIRD-PARTY-NOTICES.md` and `third-party/licenses/`.

## Legal / independence notice

Sunrise Neural Rendering Bridge is an independent interoperability project. It is not affiliated with, sponsored by, approved by, or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Microsoft, or Project Sunrise unless explicitly stated by the relevant rights holder.

No Destiny executable, Bungie game assets, Project Sunrise binaries, or NVIDIA proprietary runtime binaries are included in the public release.
