# Sunrise Neural Rendering Bridge v0.1.0-alpha

Initial public alpha release.

A D3D11 -> D3D12 interoperability bridge and external neural rendering host for Project Sunrise experimentation.

## Validated on
- NVIDIA GeForce RTX 3080 Ti 12 GB

## Working on the tested configuration
- D3D11 -> D3D12 bridge
- color / depth / motion transport
- external D3D12 host
- NVIDIA DLSS Neural Rendering host path
- Neural Rendering Work Scale
- ReShade / Sunrise coexistence

## Experimental
- AMD FidelityFX / FSR3 Frame Generation presentation path

## NVIDIA runtime
NVIDIA runtime binaries are NOT included. Users supply legitimate copies of:
- nvngx_dlss.dll
- nvngx_dlssnr.dll

This is an independent interoperability project and is not affiliated with or endorsed by NVIDIA, AMD, Bungie, ReShade, RenoDX, or Project Sunrise.
