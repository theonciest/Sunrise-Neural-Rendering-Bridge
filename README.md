# Sunrise Neural Rendering Bridge

**DLSS Neural Rendering for Project Sunrise via a D3D11 → D3D12 external host.**

## Requirements

- Project Sunrise
- NVIDIA RTX GPU
- Current NVIDIA graphics driver
- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

> NVIDIA runtime files are not included.

### Getting `nvngx_dlssnr.dll`

Join the **RenoDX Discord**, go to **`#dlss5-downloads`**, and check the pinned/current DLSS 5 downloads.

For **RTX 20 / 30 / 40 series**, RenoDX currently provides a patched `nvngx_dlssnr.dll` in that channel. Use the version appropriate for your GPU.

Once obtained, put `nvngx_dlssnr.dll` in:

`USER-RUNTIME\NVIDIA\`

## Install

1. Download the latest release and extract it.
2. Put `nvngx_dlss.dll` and `nvngx_dlssnr.dll` in `USER-RUNTIME\NVIDIA`.
3. Run `BOOTSTRAP-NVIDIA-RUNTIME.bat`.
4. Launch Project Sunrise normally.

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

### NVIDIA runtime

`nvngx_dlss.dll` is available from NVIDIA's official DLSS repository. `nvngx_dlssnr.dll` must be supplied by the user; current RenoDX DLSS 5 downloads are available through the RenoDX Discord `#dlss5-downloads` channel.

The Runtime Bootstrapper validates the supplied binaries and reports their version/hash before use.

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
