#pragma once

#include <windows.h>
#include <cstdint>
#include <d3d12.h>
#include <dxgi1_6.h>

bool Fsr3FgEnsureContext(
    ID3D12Device* device,
    UINT displayWidth,
    UINT displayHeight,
    UINT renderWidth,
    UINT renderHeight,
    DXGI_FORMAT backBufferFormat,
    bool depthInverted,
    bool hdr);


bool Fsr3FgGenerate(
    ID3D12GraphicsCommandList* commandList,
    ID3D12Resource* presentColor,
    ID3D12Resource* depth,
    ID3D12Resource* motionVectors,
    UINT renderWidth,
    UINT renderHeight,
    float jitterX,
    float jitterY,
    float mvScaleX,
    float mvScaleY,
    bool reset,
    uint64_t frameID);

ID3D12Resource* Fsr3FgGeneratedTexture();
void Fsr3FgShutdown();

bool Fsr3FgReady();

const char* Fsr3FgStatus();

