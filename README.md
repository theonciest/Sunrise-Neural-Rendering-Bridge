<h1 align="center">STAR LIFTER</h1>

<p align="center">
  <strong>Neural Rendering Bridge for Project Sunrise</strong><br>
  DLSS Neural Rendering through a D3D11 → D3D12 external host.
</p>

<p align="center">
  <img alt="Release" src="https://img.shields.io/badge/release-v0.1.1--alpha-blue">
  <img alt="Pass 1" src="https://img.shields.io/badge/Pass%201-validated-brightgreen">
  <img alt="ReShade" src="https://img.shields.io/badge/ReShade-6.8.0-6f42c1">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%20x64-lightgrey">
</p>

<p align="center">
  <a href="#install">Install</a> ·
  <a href="#controls">Controls</a> ·
  <a href="#status">Status</a> ·
  <a href="#how-it-works">How it works</a>
</p>

---

> [!IMPORTANT]
> Install and verify **ReShade 6.8.0 with Add-on Support first**, then install **Star Lifter over that ReShade installation**. Star Lifter includes a Project Sunrise-compatible ReShade build. **Do not reinstall or update stock ReShade afterward**, or Project Sunrise's **Insert** UI may stop working again.

## Validated coexistence architecture

As of **v0.1.1-alpha**, the tested Project Sunrise path keeps all three components alive at the same time:

- **Project Sunrise** / `steam_api64.dll`
- **ReShade 6.8.0 + DLSS5 feeder**
- **Star Lifter / Sunrise NRB Detours bridge**

The compatibility fix is intentionally narrow: ReShade continues to proxy the real Destiny swap chain, but leaves Project Sunrise's exact hidden **64×64 DXGI discovery probe** unproxied so Sunrise can resolve the real system `dxgi.dll` vtable.

On the validated RTX 3080 Ti configuration:

- **Ctrl + Shift + O** opens ReShade.
- **Insert** opens the Project Sunrise UI.
- DLSS Neural Rendering remains active.
- Project Sunrise's protected `steam_api64.dll` remains byte-for-byte unchanged.

## Requirements

- A working Project Sunrise install
- NVIDIA RTX GPU
- Current NVIDIA graphics driver
- **ReShade 6.8.0 with Add-on Support**
- **LumeniteFX**
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

> NVIDIA runtime files are not included.

## Install

### 1. Start with a working Project Sunrise install

Make sure Project Sunrise launches normally before installing Star Lifter.

Do **not** replace or modify:

`bin\x64\steam_api64.dll`

### 2. Install ReShade 6.8.0 with Add-on Support **first**

Install **ReShade 6.8.0 with Add-on Support** to your Project Sunrise `destiny2.exe`.

Choose:

**DirectX 10 / 11 / 12**

Install **LumeniteFX** and any other ReShade effects you want.

Launch Project Sunrise once at this point and press **Ctrl + Shift + O** to confirm the normal ReShade overlay opens.

If ReShade does not work here, stop and fix the base ReShade installation before continuing.

### 3. Install Star Lifter

Download the latest Star Lifter release.

Extract the **contents of the ZIP directly into your Project Sunrise root**, next to:

`destiny2.exe`

Allow the release files to overwrite the stock ReShade DLL when prompted.

> [!WARNING]
> Do **not** reinstall or update stock ReShade after this step. Star Lifter includes the patched ReShade 6.8.0 compatibility build required to preserve Project Sunrise's **Insert** UI while keeping ReShade/DLSS active.

### 4. Supply the NVIDIA runtime

Put your own legitimate copies of:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

into:

`USER-RUNTIME\NVIDIA\`

NVIDIA runtime binaries are not distributed with this project.

### 5. Install/bootstrap the NVIDIA runtime

If your release package contains:

`BOOTSTRAP-NVIDIA-RUNTIME.bat`

run it and follow the prompts to install/repair the supplied NVIDIA runtime files.

### 6. Launch Project Sunrise through Star Lifter

Run:

`SUNRISE-NRB.bat`

The launcher filename remains unchanged in v0.1.1-alpha so the proven V7 path is not disturbed.

Do **not** use the older experimental SunriseNRB launchers.

When everything is working:

- **Ctrl + Shift + O** → ReShade
- **Insert** → Project Sunrise UI
- DLSS Neural Rendering should be available through the bridge

## Controls

| Action | Control |
|---|---|
| Open ReShade | **Ctrl + Shift + O** |
| Open Project Sunrise UI | **Insert** |

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

<details>
<summary><strong>Local tested hashes</strong></summary>

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

</details>

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

The V7 launcher injects one small bridge DLL. That bridge waits until Project Sunrise's Steam module exists, then immediately loads the patched ReShade build. There is no post-module timing sweep and no remote ReShade injection.

The feeder transports D3D11 color, depth, motion, and rendering metadata through shared GPU resources / IPC to the external D3D12 host.

## NVIDIA runtime

NVIDIA proprietary runtime binaries are **not** shipped by this repository. Users supply legitimate copies separately.

## Source / upstream

Star Lifter is a Project Sunrise-focused fork of **DLSS5-Feeder by Jean-Laurent ROUZIES**.

- Upstream feeder: `jlrouzies-fr/DLSS5-Feeder`
- ReShade: `crosire/reshade`
- Microsoft Detours: `microsoft/Detours`

See `THIRD-PARTY-NOTICES.md` and `third-party/licenses/`.

## Legal / independence notice

Star Lifter is an independent interoperability project. It is not affiliated with, sponsored by, approved by, or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Microsoft, or Project Sunrise unless explicitly stated by the relevant rights holder.

No Destiny executable, Bungie game assets, Project Sunrise binaries, or NVIDIA proprietary runtime binaries are included in the public release.
