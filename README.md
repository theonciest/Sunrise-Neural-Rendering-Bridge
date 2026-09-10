# Sunrise Neural Rendering Bridge

**DLSS Neural Rendering for Project Sunrise via a D3D11 → D3D12 external host.**

## Requirements

- A working Project Sunrise install
- NVIDIA RTX GPU
- Current NVIDIA graphics driver
- **ReShade 6.8.0 Add-on Support**
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

> NVIDIA runtime files are not included.

## Install

### 1. Install ReShade first

Download **ReShade 6.8.0 with Add-on Support** from the official ReShade site.

Run the installer and point it at your Project Sunrise `destiny2.exe`.

Choose:

**DirectX 10 / 11 / 12**

Launch Project Sunrise once after installing ReShade. Press **Home** and confirm the ReShade overlay opens.

**If ReShade does not load, stop here and fix that first. The bridge will not work until the game-side ReShade installation is working.**

### 2. Install the bridge

Download the latest Sunrise Neural Rendering Bridge release and extract it.

Copy the **contents** of the extracted folder into your Project Sunrise root — the same folder that contains `destiny2.exe`.

### 3. Supply the NVIDIA runtime

Put both of these files in:

`USER-RUNTIME\NVIDIA\`

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

For `nvngx_dlssnr.dll`:

- **RTX 50 series:** use the normal NVIDIA-signed DLSS-NR 310.8 runtime from the current RenoDX DLSS5 / DLSS Tool (ShortFuse Version) downloads.
- **RTX 20 / 30 / 40 series:** use ShortFuse's cross-generation patched DLSS-NR 310.8 runtime from the RenoDX DLSS5 forum/downloads.

The Runtime Bootstrapper validates the supplied runtime by SHA-256 and stops instead of guessing if the DLSS-NR file is not one of the validated builds.

### 4. Run the Runtime Bootstrapper

Double-click:

`BOOTSTRAP-NVIDIA-RUNTIME.bat`

The bootstrapper validates the NVIDIA files and installs them into the bridge runtime locations.

When rerun, the bootstrapper should offer install/repair, remove, or exit. Removal must only remove files that match known installed runtime hashes and must leave unknown/user-modified files alone.

### 5. Launch Project Sunrise

Launch Project Sunrise normally.

- **Home** → ReShade
- **Insert** → Project Sunrise UI
- The separate D3D12 host window is expected and should remain open while using the bridge.

**Tested on GeForce RTX 3080 Ti 12 GB.**

---

## Status

| Feature | Status |
|---|---|
| D3D11 → D3D12 bridge | ✅ Working |
| Color / depth / motion transport | ✅ Working |
| DLSS Neural Rendering | ✅ Working |
| Neural Rendering Work Scale | ✅ Working |
| FSR3 Frame Generation | 🧪 Experimental |

## Why is there a second window?

The second window is the external D3D12 neural-rendering host. It is expected and should remain open while using the bridge.

```text
Project Sunrise / Destiny 2
           │
           │ D3D11 color + depth + motion
           ▼
   Game-side bridge / feeder
           │
           │ shared GPU resources + IPC
           ▼
     External D3D12 Host
           │
           ├── NVIDIA DLSS Neural Rendering
           └── Experimental FidelityFX FG backend
```

---

## How it works

Sunrise Neural Rendering Bridge captures color, depth, motion, and rendering metadata from Project Sunrise / Destiny 2's D3D11 renderer and transports them through shared GPU resources / IPC to a dedicated D3D12 host.

This repository is a Project Sunrise-focused fork of **DLSS5-Feeder by Jean-Laurent ROUZIES**. The upstream project established the core feeder-to-external-host architecture. This fork adds Sunrise integration, diagnostics, the external D3D12 neural-rendering host, Neural Rendering Work Scale controls, packaging, and experimental FidelityFX frame-generation integration.

The bridge does not contain NVIDIA's proprietary neural-rendering runtime. Users supply the required NVIDIA runtime files separately.

---

## Experimental

FSR3 Frame Generation remains experimental.

The current code contains the frame-generation dispatch path and generated-frame resources, but this project does **not currently advertise visible FPS doubling**. Generated-frame presentation/interleaving remains a separate validation target.

---

## Logs / Support

The main user-facing diagnostic log is:

```text
host64\logs\status.log
```

When reporting an issue, include the status log, GPU model, driver version, and versions/hashes of the user-supplied NVIDIA runtime files.

---

## Building From Source

```text
build.bat
host\build-host-fsr3.bat
```

Normal users should use the packaged release rather than building manually.

---

## Credits

This project is based on **DLSS5-Feeder by Jean-Laurent ROUZIES**. The upstream feeder/external-host architecture is the technical foundation of this fork. The original MIT copyright and permission notice are preserved in `LICENSE`.

Upstream project: `jlrouzies-fr/DLSS5-Feeder`

This project also interoperates with technology and/or software from NVIDIA, AMD, ReShade, RenoDX, Project Sunrise, and other upstream projects. See `THIRD-PARTY-NOTICES.md` for applicable notices and licenses.

---

## Legal / Independence Notice

Sunrise Neural Rendering Bridge is an independent interoperability project. It is not affiliated with, sponsored by, approved by, or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, or Project Sunrise unless explicitly stated by the relevant rights holder.

Names such as NVIDIA, DLSS, NGX, AMD, FidelityFX, FSR, Bungie, Destiny, ReShade, RenoDX, and Project Sunrise are used solely to identify compatibility, interoperability, or upstream technology. All trademarks and copyrights remain the property of their respective owners.

This repository does not grant rights to Destiny / Destiny 2 game content, Project Sunrise files, NVIDIA runtime binaries, or other third-party proprietary materials. No Bungie game assets, Project Sunrise binaries, or NVIDIA proprietary runtime binaries are included in the public bridge release.

See `LICENSE` and `THIRD-PARTY-NOTICES.md` for the applicable notices.
