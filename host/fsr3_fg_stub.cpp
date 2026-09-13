#include "fsr3_fg.h"

// Standard host build: FSR3 presentation is intentionally not compiled here.
// The experimental FidelityFX implementation belongs to build-host-fsr3.bat.

bool Fsr3FgEnsureContext(
    ID3D12Device*, UINT, UINT, UINT, UINT, DXGI_FORMAT, bool, bool)
{
    return false;
}

bool Fsr3FgGenerate(
    ID3D12GraphicsCommandList*,
    ID3D12Resource*,
    ID3D12Resource*,
    ID3D12Resource*,
    UINT,
    UINT,
    float,
    float,
    float,
    float,
    bool,
    uint64_t)
{
    return false;
}

ID3D12Resource* Fsr3FgGeneratedTexture()
{
    return nullptr;
}

void Fsr3FgShutdown()
{
}

bool Fsr3FgReady()
{
    return false;
}

const char* Fsr3FgStatus()
{
    return "FSR3 frame generation not compiled in standard host build";
}