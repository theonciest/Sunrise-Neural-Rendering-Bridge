# Third-Party Notices

Sunrise Neural Rendering Bridge is an independent interoperability project. It is not affiliated with or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, Project Sunrise, or any other third-party project referenced below.

## Upstream DLSS5-Feeder

This project is based on **DLSS5-Feeder by Jean-Laurent ROUZIES**.

The upstream project is licensed under the MIT License. The original copyright and permission notice are preserved in this repository's `LICENSE` file.

Upstream repository: `jlrouzies-fr/DLSS5-Feeder`

Portions derived from `dlss5-dx11-bridge` are also identified in the MIT notice in `LICENSE`.

## ReShade

ReShade is Copyright (c) Patrick Mours and contributors and is distributed under a BSD 3-Clause-style license.

If ReShade binaries are redistributed with a release, the ReShade copyright notice, license conditions, and disclaimer must accompany the binary distribution.

Official project: `crosire/reshade`

## RenoDX

RenoDX is distributed under the MIT License.

Official project: `clshortfuse/renodx`

If RenoDX components are redistributed with a release, preserve the applicable MIT copyright and permission notice.

## AMD FidelityFX SDK / FSR

AMD FidelityFX components remain the property of Advanced Micro Devices, Inc. and are subject to AMD's applicable FidelityFX SDK license and third-party notices.

The FidelityFX SDK license permits redistribution of covered software in binary form subject to its conditions, including reproduction of the applicable copyright notice, permission notice, disclaimers, and notices in documentation and/or other materials accompanying the distribution.

Official project: `GPUOpen-LibrariesAndSDKs/FidelityFX-SDK`

A public binary release containing FidelityFX DLLs must include AMD's applicable license and notice text.

## NVIDIA DLSS / NGX Runtime

**NVIDIA runtime binaries are not part of this project's open-source code and are not included in the public bridge package by default.**

Users supply their own legitimate NVIDIA runtime files where required:

- `nvngx_dlss.dll`
- `nvngx_dlssnr.dll`

The bridge loads and interoperates with those vendor-provided runtime components. It does not claim ownership of, relicense, or modify NVIDIA's proprietary runtime binaries.

NVIDIA DLSS / NGX software is governed by NVIDIA's own license terms. Do not add NVIDIA SDK/runtime binaries to a public release without separately confirming that the proposed distribution complies with those terms.

Official NVIDIA DLSS repository: `NVIDIA/DLSS`

## Bungie / Destiny / Project Sunrise

This repository does not grant rights to Destiny, Destiny 2, Bungie content, game assets, trademarks, or Project Sunrise files.

Public releases of this bridge should not contain Bungie game assets, Destiny executable content, Project Sunrise binaries, saves, extracted proprietary game data, or other third-party content unless separate permission clearly allows it.

Project Sunrise is a separate community project. This bridge is an independent integration and is not an official Project Sunrise component unless explicitly stated by that project's maintainers.

## Vulkan / shader-tool dependencies

Vulkan headers, shader compilers, SPIR-V libraries, DXC, glslang, shaderc, Slang, and other external build dependencies retain their own licenses. Development checkouts are not automatically part of the public binary distribution.

## Trademarks

Names such as NVIDIA, DLSS, NGX, GeForce, AMD, FidelityFX, FSR, ReShade, RenoDX, Bungie, Destiny, and Project Sunrise are used only to identify compatibility, interoperability, or upstream technology. All trademarks remain the property of their respective owners.

## Public release rule

Before publishing a binary release, verify the actual files in that release against their applicable licenses. A source repository being redistributable does not automatically mean every bundled binary from every vendor is redistributable under the same terms.

**Default public-package policy:** ship the bridge and permitted dependencies; require users to supply NVIDIA runtime binaries separately.

This document is informational and does not replace the license text supplied by each rights holder.
