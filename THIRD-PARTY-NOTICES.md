# Third-Party Notices

Sunrise Neural Rendering Bridge is an independent interoperability project. It is not affiliated with or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Microsoft, Project Sunrise, or any other third-party project referenced below.

## Upstream DLSS5-Feeder

This project is based on **DLSS5-Feeder by Jean-Laurent ROUZIES**.

The upstream project is licensed under the MIT License. The original copyright and permission notice are preserved in this repository's `LICENSE` file.

Upstream repository: `jlrouzies-fr/DLSS5-Feeder`

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

## RenoDX

RenoDX is distributed under the MIT License.

Official project: `clshortfuse/renodx`

If RenoDX components are redistributed with a release, preserve the applicable MIT copyright and permission notice.

## AMD FidelityFX SDK / FSR

AMD FidelityFX components remain the property of Advanced Micro Devices, Inc. and are subject to AMD's applicable FidelityFX SDK license and third-party notices.

A public binary release containing FidelityFX DLLs must include AMD's applicable license and notice text.

Official project: `GPUOpen-LibrariesAndSDKs/FidelityFX-SDK`

## NVIDIA DLSS / NGX Runtime

**NVIDIA runtime binaries are not part of this project's open-source code and are not included in the public bridge package by default.**

Users supply their own legitimate NVIDIA runtime files where required:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

The bridge loads and interoperates with those vendor-provided runtime components. It does not claim ownership of, relicense, or modify NVIDIA's proprietary runtime binaries.

Official NVIDIA DLSS repository: `NVIDIA/DLSS`

## Bungie / Destiny / Project Sunrise

This repository does not grant rights to Destiny, Destiny 2, Bungie content, game assets, trademarks, or Project Sunrise files.

Public releases must not contain Bungie game assets, `destiny2.exe`, Project Sunrise's `steam_api64.dll`, saves, extracted proprietary game data, or other third-party proprietary content unless separate permission clearly allows it.

## Public release rule

Before publishing a binary release, verify the actual files in that release against their applicable licenses.

**Default public-package policy:** ship the bridge and permitted dependencies; require users to supply NVIDIA runtime binaries separately.
