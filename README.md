# Sunrise Neural Rendering Bridge

### D3D11 → D3D12 Interoperability Bridge & External Neural Rendering Host for Project Sunrise

> **Independent interoperability project. NVIDIA runtime not included.**
>
> Tested hardware: **GeForce RTX 3080 Ti 12 GB**. Other RTX GPUs may work, but have not been personally validated yet.

| Component | Status |
|---|---|
| D3D11 → D3D12 bridge | ✅ Working |
| Color / depth / motion transport | ✅ Working |
| External D3D12 host | ✅ Working |
| NVIDIA DLSS Neural Rendering host path | ✅ Working on tested configuration |
| Neural Rendering Work Scale | ✅ Working |
| FSR3 Frame Generation dispatch | 🧪 Experimental |
| Visible generated-frame presentation | ⚠️ Not yet claimed |

Sunrise Neural Rendering Bridge captures the rendering inputs needed from Project Sunrise / Destiny 2's D3D11 renderer, transports them through shared GPU resources / IPC, and exposes them to a dedicated external D3D12 host.

The bridge itself does **not** contain or relicense NVIDIA's proprietary neural-rendering runtime. Users supply the required NVIDIA runtime files separately.

---

## What this project actually is

This repository is a Project Sunrise-focused fork of **DLSS5-Feeder by Jean-Laurent ROUZIES**.

The upstream project established the core feeder-to-external-host architecture. This fork adapts that architecture for Project Sunrise and adds Sunrise-focused integration, diagnostics, an external D3D12 host, Neural Rendering Work Scale controls, packaging work, and experimental FidelityFX frame-generation integration.

The public-facing pieces are named by their actual jobs:

- **D3D11 → D3D12 Interoperability Bridge** — transfers rendering inputs out of the D3D11 application.
- **Neural Rendering Host** — external D3D12 process that evaluates supported neural-rendering functionality.
- **Runtime Bootstrapper** — validates and installs the bridge and user-supplied runtime dependencies.
- **User-Supplied NVIDIA Runtime** — NVIDIA-provided binaries required by the host; not included in this project's public package.
- **Experimental Frame Generation Backend** — FidelityFX-based frame-generation research path.

---

## Why there is a second window

Project Sunrise runs Destiny 2 as a D3D11 application. The neural-rendering path used by this project is evaluated in a separate D3D12 host.

The side window is therefore **expected**. It is not another copy of Destiny. It is the external rendering host used by the bridge.

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

Do not close the host while using the neural-rendering path.

---

# Quick Start

## Requirements

You need:

- A working Project Sunrise installation
- A compatible NVIDIA RTX GPU
- A current NVIDIA graphics driver
- The Sunrise Neural Rendering Bridge release
- Your own legitimate copies of:
  - `nvngx_dlss.dll`
  - `nvngx_dlssnr.dll`

### NVIDIA runtime files are not included

This project intentionally does **not** redistribute NVIDIA's proprietary neural runtime in its public package.

`nvngx_dlss.dll` is available from NVIDIA's official DLSS repository. `nvngx_dlssnr.dll` must also be supplied by the user from a legitimate NVIDIA-provided source.

The Runtime Bootstrapper should validate supplied binaries and report their version/hash before use.

---

## Installation model

The intended public install flow is:

```text
1. Download the Sunrise Neural Rendering Bridge release
2. Extract it
3. Supply nvngx_dlss.dll and nvngx_dlssnr.dll when requested
4. Run the Runtime Bootstrapper
5. Launch Project Sunrise normally
```

The bootstrapper should fail closed if required files are missing or if the local Project Sunrise layout is incompatible.

A public release must **not** replace or redistribute Project Sunrise's own `steam_api64.dll` or other Sunrise/game binaries.

---

# Current Status

## Working on the tested configuration

- D3D11 game-side feeder
- ReShade-derived color input
- depth transfer
- motion-vector transfer
- shared GPU resources / IPC
- separate D3D12 host
- NVIDIA NGX initialization where supported
- DLSS Neural Rendering evaluation
- Project Sunrise integration
- Neural Rendering Work Scale controls
- FidelityFX SDK frame-generation dispatch path

## Experimental / incomplete

FSR3 Frame Generation remains experimental.

The current code contains the frame-generation dispatch path and generated-frame resources, but this project does **not currently advertise visible FPS doubling**. Generated-frame presentation/interleaving remains a separate validation target.

---

# Tested Hardware

Current personal validation has been performed on:

- **NVIDIA GeForce RTX 3080 Ti 12 GB**
- Windows
- Project Sunrise / Destiny 2 D3D11 rendering path

Other hardware may work, but should be considered unverified until reported and reproduced.

---

# Logs / Support

The host writes diagnostic information under its `logs` directory. The most useful user-facing file is typically:

```text
host64\logs\status.log
```

When reporting an issue, include the status log, GPU model, driver version, and the versions/hashes of the user-supplied NVIDIA runtime files.

---

# Building From Source

For developers:

```text
build.bat
host\build-host-fsr3.bat
```

The normal end user should use a packaged bridge release rather than building manually.

---

# Credits

## DLSS5-Feeder

This project is based on **DLSS5-Feeder by Jean-Laurent ROUZIES**. The upstream feeder/external-host architecture is the technical foundation of this fork.

The original MIT copyright and permission notice are preserved in `LICENSE`.

Upstream project: `jlrouzies-fr/DLSS5-Feeder`

## Third-party technology

This project interoperates with technology and/or software from NVIDIA, AMD, ReShade, RenoDX, Project Sunrise, and other upstream projects.

Those projects remain subject to their own licenses and redistribution terms. See `THIRD-PARTY-NOTICES.md` before creating or distributing binary releases.

---

# Legal / Independence Notice

Sunrise Neural Rendering Bridge is an **independent interoperability project**.

It is not affiliated with, sponsored by, approved by, or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, or Project Sunrise unless explicitly stated by the relevant rights holder.

Names such as NVIDIA, DLSS, NGX, AMD, FidelityFX, FSR, Bungie, Destiny, ReShade, RenoDX, and Project Sunrise are used solely to identify compatibility, interoperability, or upstream technology. All trademarks and copyrights remain the property of their respective owners.

This repository does not grant rights to Destiny / Destiny 2 game content, Project Sunrise files, NVIDIA runtime binaries, or other third-party proprietary materials.

**No Bungie game assets, Project Sunrise binaries, or NVIDIA proprietary runtime binaries should be included in the public bridge release unless their applicable terms separately permit that redistribution.**

See `LICENSE` and `THIRD-PARTY-NOTICES.md` for the applicable notices.

---

## Release philosophy

**We ship the bridge. Vendors supply their runtimes.**

That keeps the project focused on the interoperability work it actually implements and keeps third-party ownership boundaries clear.
