# STAR 💫 LIFTER v0.1.3-alpha

This release replaces the old inherited-ZIP delivery path with a clean-room package assembled from an empty staging directory.

## What changed

- The installer now deploys the **complete** Star Lifter runtime described by the release manifest, not only the feeder DLL and host EXE.
- The final release ZIP is extracted into a second clean directory and validated before GitHub is allowed to publish it.
- The release no longer inherits files from v0.1.0/v0.1.1/v0.1.2 ZIPs.
- The proven V7 Sunrise/ReShade coexistence bridge remains the launcher path.
- The game-side feeder includes the Star Lifter **F5 Neural Rendering toggle**.
- **F4** feeder panel, **F5** Neural Rendering, **F6** Before/After screenshots, **F7** side-by-side and **F8** HDR grading bypass are the intended controls.
- The configurator now sets `DLSS5_MV_PROVIDER=3` and builds the required ReShade technique order automatically.
- The installer fetches pinned **LumeniteFX** and the pinned public **RenoDX DLSS5 4.60** archive from upstream, verifies the archive SHA-256, and records the exact extracted RenoDX add-on hash.

## NVIDIA runtime

NVIDIA proprietary runtime binaries are **not distributed** with Star Lifter.

Before running the installer, put legitimate copies of:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

in:

`USER-RUNTIME\NVIDIA\`

## Install

1. Start with a working Project Sunrise installation.
2. Extract this release.
3. Put your NVIDIA runtime DLLs in `USER-RUNTIME\NVIDIA\`.
4. Run `Install-Sunrise.bat`.
5. Launch with `SUNRISE-NRB.bat` from the Project Sunrise root.

The installer never replaces Project Sunrise's protected `bin\x64\steam_api64.dll`.

## Alpha status

FSR3 Frame Generation remains experimental. Neural Rendering work scale below 50% remains a separate validation target.
