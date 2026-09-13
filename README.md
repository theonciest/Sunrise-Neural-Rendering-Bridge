<h1 align="center">STAR 💫 LIFTER</h1>

<p align="center">
  <strong>Neural Rendering Bridge for Project Sunrise</strong><br>
  DLSS Neural Rendering through a D3D11 → D3D12 external host.
</p>

<p align="center">
  <img alt="Release" src="https://img.shields.io/badge/release-v0.1.3--alpha-blue">
  <img alt="Pass 1" src="https://img.shields.io/badge/Pass%201-validated-brightgreen">
  <img alt="ReShade" src="https://img.shields.io/badge/ReShade-6.8.0-6f42c1">
  <img alt="Platform" src="https://img.shields.io/badge/platform-Windows%20x64-lightgrey">
</p>

---

> [!IMPORTANT]
> **v0.1.3-alpha changes the delivery, not the proven Sunrise coexistence architecture.** The installer now deploys the complete Star Lifter runtime from a clean manifest. You should no longer search for add-ons, move `host64` by hand, or copy nested release files around manually.

## What Star Lifter keeps alive together

The validated Project Sunrise path keeps all three components alive in the same process:

- **Project Sunrise** / protected `bin\x64\steam_api64.dll`
- **ReShade 6.8.0 + DLSS5 feeder**
- **Star Lifter / Sunrise NRB V7 Detours bridge**

ReShade continues to proxy the real Destiny swap chain but leaves Project Sunrise's exact hidden **64×64 DXGI discovery probe** unproxied so Sunrise can resolve the real system DXGI vtable.

## Requirements

- A working Project Sunrise installation against the correct Destiny depot
- NVIDIA RTX GPU and current NVIDIA driver
- ReShade **6.8.0 with Add-on Support** installed/launched once so the game has a normal `ReShade.ini`
- Legitimate copies of:
  - `nvngx_dlss.dll`
  - `nvngx_dlssnr.dll`
- Internet access during installation for the pinned LumeniteFX and RenoDX runtime dependencies

Star Lifter does **not** distribute NVIDIA proprietary runtime DLLs.

## Install

### 1. Verify Project Sunrise first

Launch Project Sunrise normally before installing Star Lifter. If Sunrise itself is not working, fix that first.

Star Lifter must **not** replace or modify:

`bin\x64\steam_api64.dll`

### 2. Install ReShade 6.8.0 with Add-on Support once

Install ReShade 6.8.0 with Add-on Support for `destiny2.exe` using **DirectX 10 / 11 / 12** and launch once so its normal configuration exists.

You do **not** need to manually install Star Lifter's Lumenite/RenoDX pieces afterward; the v0.1.3 installer handles the pinned runtime dependencies.

### 3. Extract Star Lifter

Download `STAR-LIFTER-v0.1.3-alpha.zip` and extract it.

You may extract it into the Project Sunrise root or into a temporary folder; the installer checks its own folder first, common Sunrise locations next, then prompts if necessary.

### 4. Supply your NVIDIA runtime

Inside the extracted Star Lifter package, put your legitimate copies of:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

into:

`USER-RUNTIME\NVIDIA\`

### 5. Run the installer

Run:

`Install-Sunrise.bat`

The installer now performs the complete deployment:

- validates every file in the shipped payload manifest before touching Sunrise
- backs up files it will replace
- installs the patched game-side DLSS feeder
- installs the known-good 64-bit helper host
- installs the patched ReShade 6.8.0 build for the Sunrise coexistence bridge and host
- installs the V7 Sunrise NRB bridge + launcher
- downloads and verifies pinned **RenoDX DLSS5 4.60**
- downloads pinned **LumeniteFX**
- copies your NVIDIA runtime into `host64`
- configures the actual DLSS effect chain and hotkeys
- verifies the required final files exist
- verifies Project Sunrise's protected `steam_api64.dll` did not change

There is no manual "search for addon", no manual `host64` relocation, and no separate shader-copy step.

### 6. Launch through Star Lifter

From the Project Sunrise root run:

`SUNRISE-NRB.bat`

Do not use old experimental SunriseNRB launchers.

## Controls

| Action | Control |
|---|---|
| Open / close ReShade | **Ctrl + Shift + O** |
| Open Project Sunrise UI | **Insert** |
| Show / hide DLSS 5 feeder panel | **F4** |
| Toggle DLSS Neural Rendering | **F5** |
| Save matched Before + After screenshots | **F6** |
| Toggle side-by-side comparison | **F7** |
| Bypass / restore KageBlink HDR grading | **F8** |

F5 uses Star Lifter's game-side input path. It changes RenoDX's `NeuralUplift` setting in the helper configuration and deterministically restarts the helper. It does not rely on RenoDX's background global F5 hotkey.

## Effect chain installed by the configurator

Star Lifter sets `DLSS5_MV_PROVIDER=3` and forces the important techniques into this order:

```text
DLSSCompare_Capture
Lumenite_Kernel
DLSS5_Feed
KB_HDR_LogWheels
...any unrelated existing effects...
DLSSCompare_Output
```

`DLSSCompare_Capture` must remain first and `DLSSCompare_Output` must remain last for F7 comparisons to be meaningful.

## Status

| Feature | Status |
|---|---|
| D3D11 → D3D12 bridge | ✅ Working |
| Color / depth / motion transport | ✅ Working |
| DLSS Neural Rendering | ✅ Working |
| ReShade / Sunrise coexistence | ✅ Working |
| Project Sunrise Insert UI | ✅ Working |
| F4 feeder panel | ✅ Working |
| F5 Neural Rendering toggle | ✅ Working through host-settings restart path |
| F6 matched Before / After screenshots | ✅ Working |
| F7 side-by-side comparison | ✅ Working |
| F8 HDR grading bypass | ✅ Shader-owned |
| Neural Rendering Work Scale | ✅ 50–100%; below 50% is a separate validation target |
| FSR3 Frame Generation | 🧪 Experimental |

## Clean-room release rule

v0.1.3-alpha and later are built from an **empty staging directory**. The release workflow does not download or inherit an older Star Lifter ZIP.

Before publishing, CI:

1. builds/fetches the pinned components,
2. creates the complete payload manifest from the staged files,
3. rejects forbidden and stale files,
4. creates the ZIP,
5. extracts that **finished ZIP into a second clean directory**,
6. verifies required paths and payload hashes from the extracted artifact,
7. verifies the known-good helper host and Star Lifter F5 patch,
8. only then publishes the GitHub release.

The shipped ZIP is the release authority.

## Distribution

The release does **not** contain:

- `steam_api64.dll`
- `destiny2.exe`
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

Users supply NVIDIA runtime files separately. Project Sunrise game/binary content is not redistributed.

## Source / upstream

Star Lifter is a Project Sunrise-focused integration built around **DLSS5-Feeder by Jean-Laurent ROUZIES**, ReShade, Microsoft Detours, RenoDX DLSS5 and LumeniteFX.

See `THIRD-PARTY-NOTICES.md` and the repository source for attribution and pinned dependency details.

## Legal / independence notice

Star Lifter is an independent interoperability project. It is not affiliated with, sponsored by, approved by, or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Microsoft, LumeniteFX, or Project Sunrise unless explicitly stated by the relevant rights holder.
