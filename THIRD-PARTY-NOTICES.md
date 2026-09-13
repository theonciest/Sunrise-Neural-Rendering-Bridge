# Third-Party Notices

Star Lifter / Sunrise Neural Rendering Bridge is an independent interoperability project. It is not affiliated with or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Microsoft, LumeniteFX, Project Sunrise, or any other third-party project referenced below.

## Upstream DLSS5-Feeder

This project is based on **DLSS5-Feeder by Jean-Laurent ROUZIES**.

The upstream project is licensed under the MIT License. The original copyright and permission notice are preserved in this repository's `LICENSE` file.

Upstream repository: `jlrouzies-fr/DLSS5-Feeder`

The v0.1.3-alpha clean-room release obtains the known-good v0.12.0 helper from the upstream v0.12.0 release and verifies its archive and helper hashes before packaging.

## ReShade

ReShade is Copyright (c) Patrick Mours and contributors and is distributed under a BSD 3-Clause-style license.

The Sunrise coexistence release builds ReShade 6.8.0 from pinned upstream source with one narrow compatibility change: the exact opt-in Project Sunrise 64×64 DXGI discovery probe is left unproxied. Normal game swap chains retain stock ReShade proxy behavior.

The complete ReShade license is preserved at:

`third-party/licenses/ReShade-6.8.0-LICENSE.md`

Official project: `crosire/reshade`

## Microsoft Detours

The Sunrise V7 bootstrap uses **Microsoft Detours 4.0.1** for single-DLL process creation/injection.

Microsoft Detours is distributed under the MIT License. The complete license text is preserved at:

`third-party/licenses/Microsoft-Detours-4.0.1-LICENSE.md`

Official project: `microsoft/Detours`

## RenoDX DLSS5

Star Lifter does not redistribute the RenoDX DLSS5 binary in its release ZIP. The installer downloads the pinned public **RenoDX DLSS5 4.60** release directly from its upstream release host and verifies the archive SHA-256 before installing the add-on into `host64`.

Upstream project/release mirror used by the installer: `RankFTW/rhi-repo`, tag `renodx-dlss5-4.60`.

## LumeniteFX

Star Lifter does not copy LumeniteFX into the release ZIP. The installer downloads a pinned public LumeniteFX source revision directly from `umar-afzaal/LumeniteFX` and installs its shader/runtime files into the user's ReShade shader tree.

Pinned v0.1.3-alpha revision: `f8cbbb4eccfcb7adf0d74bb358ba349272e3c1e9`.

LumeniteFX remains subject to its own notices and license terms supplied by its upstream repository.

## AMD FidelityFX SDK / FSR

AMD FidelityFX components remain the property of Advanced Micro Devices, Inc. and are subject to AMD's applicable FidelityFX SDK license and third-party notices.

A public binary release containing FidelityFX DLLs must include AMD's applicable license and notice text.

Official project: `GPUOpen-LibrariesAndSDKs/FidelityFX-SDK`

## NVIDIA DLSS / NGX Runtime

**NVIDIA runtime binaries are not included in the public Star Lifter package.**

Users supply legitimate copies of:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

The installer copies those user-supplied files into the helper runtime location. Star Lifter does not claim ownership of, relicense, or modify NVIDIA's proprietary runtime binaries.

Official NVIDIA DLSS repository: `NVIDIA/DLSS`

## Bungie / Destiny / Project Sunrise

This repository does not grant rights to Destiny, Destiny 2, Bungie content, game assets, trademarks, or Project Sunrise files.

Public releases must not contain Bungie game assets, `destiny2.exe`, Project Sunrise's `steam_api64.dll`, saves, extracted proprietary game data, or other third-party proprietary content unless separate permission clearly allows it.

## Public release rule

Every public Star Lifter release is assembled from an empty staging directory. The finished ZIP is extracted into a second clean directory and validated before publication. Forbidden vendor/game files and stale test/backup artifacts cause the release job to fail.
