#include "fsr3_fg.h"

#include <cstdio>
#include <cstring>

#include "api/include/ffx_api.h"
#include "api/include/dx12/ffx_api_dx12.h"
#include "framegeneration/include/ffx_framegeneration.h"

static HMODULE g_ffxModule = nullptr;

static PfnFfxCreateContext  g_ffxCreateContext  = nullptr;
static PfnFfxDestroyContext g_ffxDestroyContext = nullptr;
static PfnFfxConfigure      g_ffxConfigure      = nullptr;
static PfnFfxQuery          g_ffxQuery          = nullptr;
static PfnFfxDispatch       g_ffxDispatch       = nullptr;

static ffxContext g_fgContext = {};

static bool g_contextReady = false;

static UINT        g_displayW = 0;
static UINT        g_displayH = 0;
static UINT        g_renderW  = 0;
static UINT        g_renderH  = 0;
static DXGI_FORMAT g_format   = DXGI_FORMAT_UNKNOWN;
static bool        g_depthInv = false;
static bool        g_hdr      = false;

static char g_status[512] = "not initialized";

static void SetStatus(const char* text)
{
    strncpy_s(g_status, text, _TRUNCATE);
}

static uint32_t ToFfxSurfaceFormat(DXGI_FORMAT fmt)
{
    switch (fmt)
    {
        case DXGI_FORMAT_R8G8B8A8_UNORM:
            return FFX_API_SURFACE_FORMAT_R8G8B8A8_UNORM;

        case DXGI_FORMAT_B8G8R8A8_UNORM:
            return FFX_API_SURFACE_FORMAT_B8G8R8A8_UNORM;

        case DXGI_FORMAT_R8G8B8A8_UNORM_SRGB:
            return FFX_API_SURFACE_FORMAT_R8G8B8A8_SRGB;

        case DXGI_FORMAT_B8G8R8A8_UNORM_SRGB:
            return FFX_API_SURFACE_FORMAT_B8G8R8A8_SRGB;

        case DXGI_FORMAT_R16G16B16A16_FLOAT:
            return FFX_API_SURFACE_FORMAT_R16G16B16A16_FLOAT;

        case DXGI_FORMAT_R10G10B10A2_UNORM:
            return FFX_API_SURFACE_FORMAT_R10G10B10A2_UNORM;

        default:
            return FFX_API_SURFACE_FORMAT_UNKNOWN;
    }
}


static ID3D12Device*   g_fgDevice  = nullptr;
static ID3D12Resource* g_generated = nullptr;
static ULONGLONG       g_fgLastTick = 0;

static FfxApiResource Fsr3WrapResource(
    ID3D12Resource* resource,
    uint32_t state,
    uint32_t usage = FFX_API_RESOURCE_USAGE_READ_ONLY)
{
    FfxApiResource out = {};

    if (resource == nullptr)
        return out;

    const D3D12_RESOURCE_DESC rd = resource->GetDesc();

    out.resource = resource;
    out.description.type = FFX_API_RESOURCE_TYPE_TEXTURE2D;
    out.description.format = ToFfxSurfaceFormat(rd.Format);
    out.description.width = static_cast<uint32_t>(rd.Width);
    out.description.height = rd.Height;
    out.description.depth = 1;
    out.description.mipCount = rd.MipLevels;
    out.description.flags = FFX_API_RESOURCE_FLAGS_NONE;
    out.description.usage = usage;
    out.state = state;

    return out;
}

static bool Fsr3CreateOutputTexture()
{
    if (g_fgDevice == nullptr)
        return false;

    if (g_generated != nullptr)
    {
        g_generated->Release();
        g_generated = nullptr;
    }

    D3D12_HEAP_PROPERTIES hp = {};
    hp.Type = D3D12_HEAP_TYPE_DEFAULT;

    D3D12_RESOURCE_DESC rd = {};
    rd.Dimension = D3D12_RESOURCE_DIMENSION_TEXTURE2D;
    rd.Width = g_displayW;
    rd.Height = g_displayH;
    rd.DepthOrArraySize = 1;
    rd.MipLevels = 1;
    rd.Format = g_format;
    rd.SampleDesc.Count = 1;
    rd.Layout = D3D12_TEXTURE_LAYOUT_UNKNOWN;
    rd.Flags = D3D12_RESOURCE_FLAG_ALLOW_UNORDERED_ACCESS;

    const HRESULT hr = g_fgDevice->CreateCommittedResource(
        &hp,
        D3D12_HEAP_FLAG_NONE,
        &rd,
        D3D12_RESOURCE_STATE_UNORDERED_ACCESS,
        nullptr,
        IID_PPV_ARGS(&g_generated));

    if (FAILED(hr))
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "FG output texture failed 0x%08X",
            static_cast<unsigned>(hr));

        return false;
    }

    return true;
}
static bool LoadApi()
{
    if (g_ffxModule != nullptr)
        return true;

    wchar_t exePath[MAX_PATH] = {};
    GetModuleFileNameW(nullptr, exePath, MAX_PATH);

    wchar_t* slash = wcsrchr(exePath, L'\\');
    if (slash != nullptr)
        *(slash + 1) = L'\0';

    wchar_t dllPath[MAX_PATH] = {};
    wcscpy_s(dllPath, exePath);
    wcscat_s(dllPath, L"amd_fidelityfx_loader_dx12.dll");

    g_ffxModule = LoadLibraryW(dllPath);

    if (g_ffxModule == nullptr)
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "loader failed (%lu)",
            GetLastError());

        return false;
    }

    g_ffxCreateContext =
        reinterpret_cast<PfnFfxCreateContext>(
            GetProcAddress(g_ffxModule, "ffxCreateContext"));

    g_ffxDestroyContext =
        reinterpret_cast<PfnFfxDestroyContext>(
            GetProcAddress(g_ffxModule, "ffxDestroyContext"));

    g_ffxConfigure =
        reinterpret_cast<PfnFfxConfigure>(
            GetProcAddress(g_ffxModule, "ffxConfigure"));

    g_ffxQuery =
        reinterpret_cast<PfnFfxQuery>(
            GetProcAddress(g_ffxModule, "ffxQuery"));

    g_ffxDispatch =
        reinterpret_cast<PfnFfxDispatch>(
            GetProcAddress(g_ffxModule, "ffxDispatch"));

    if (!g_ffxCreateContext ||
        !g_ffxDestroyContext ||
        !g_ffxConfigure ||
        !g_ffxQuery ||
        !g_ffxDispatch)
    {
        SetStatus("loader exports incomplete");
        return false;
    }

    SetStatus("FidelityFX loader ready");
    return true;
}

void Fsr3FgShutdown()
{
    if (g_contextReady && g_ffxDestroyContext)
    {
        g_ffxDestroyContext(&g_fgContext, nullptr);
    }

    memset(&g_fgContext, 0, sizeof(g_fgContext));

    g_contextReady = false;

    g_displayW = 0;
    g_displayH = 0;
    g_renderW  = 0;
    g_renderH  = 0;

    g_format   = DXGI_FORMAT_UNKNOWN;
}

bool Fsr3FgEnsureContext(
    ID3D12Device* device,
    UINT displayWidth,
    UINT displayHeight,
    UINT renderWidth,
    UINT renderHeight,
    DXGI_FORMAT backBufferFormat,
    bool depthInverted,
    bool hdr)
{
    if (device == nullptr)
    {
        SetStatus("no D3D12 device");
        return false;
    }

    if (g_contextReady &&
        g_displayW == displayWidth &&
        g_displayH == displayHeight &&
        g_renderW == renderWidth &&
        g_renderH == renderHeight &&
        g_format == backBufferFormat &&
        g_depthInv == depthInverted &&
        g_hdr == hdr)
    {
        return true;
    }

    Fsr3FgShutdown();

    if (!LoadApi())
        return false;

    const uint32_t surfaceFormat =
        ToFfxSurfaceFormat(backBufferFormat);

    if (surfaceFormat == FFX_API_SURFACE_FORMAT_UNKNOWN)
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "unsupported backbuffer format %u",
            static_cast<unsigned>(backBufferFormat));

        return false;
    }

    // Main Frame Generation context.
    ffxCreateContextDescFrameGeneration fg = {};

    fg.header.type =
        FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATION;

    fg.displaySize.width  = displayWidth;
    fg.displaySize.height = displayHeight;

    fg.maxRenderSize.width  = renderWidth;
    fg.maxRenderSize.height = renderHeight;

    fg.backBufferFormat = surfaceFormat;

    fg.flags = 0;

    if (depthInverted)
        fg.flags |= FFX_FRAMEGENERATION_ENABLE_DEPTH_INVERTED;

    if (hdr)
        fg.flags |= FFX_FRAMEGENERATION_ENABLE_HIGH_DYNAMIC_RANGE;

    // Keep first validation synchronous.
    // We can enable async compute after it works.
    //
    // fg.flags |= FFX_FRAMEGENERATION_ENABLE_ASYNC_WORKLOAD_SUPPORT;

    // DX12 backend descriptor.
    ffxCreateBackendDX12Desc backend = {};

    backend.header.type =
        FFX_API_CREATE_CONTEXT_DESC_TYPE_BACKEND_DX12;

    backend.device = device;

    // Tell the runtime which FG API our application was built against.
    ffxCreateContextDescFrameGenerationVersion version = {};

    version.header.type =
        FFX_API_CREATE_CONTEXT_DESC_TYPE_FRAMEGENERATION_VERSION;

    version.version =
        FFX_FRAMEGENERATION_VERSION;

    // Descriptor chain:
    //
    // FG
    //  ?
    // DX12 backend
    //  ?
    // API version

    fg.header.pNext =
        reinterpret_cast<ffxApiHeader*>(&backend);

    backend.header.pNext =
        reinterpret_cast<ffxApiHeader*>(&version);

    version.header.pNext = nullptr;

    memset(&g_fgContext, 0, sizeof(g_fgContext));

    const ffxReturnCode_t rc =
        g_ffxCreateContext(
            &g_fgContext,
            &fg.header,
            nullptr);

    if (rc != FFX_API_RETURN_OK)
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "CreateContext failed rc=%d",
            static_cast<int>(rc));

        memset(&g_fgContext, 0, sizeof(g_fgContext));
        return false;
    }

    g_contextReady = true;

    g_fgDevice = device;

    g_displayW = displayWidth;
    g_displayH = displayHeight;

    g_renderW = renderWidth;
    g_renderH = renderHeight;

    g_format   = backBufferFormat;
    g_depthInv = depthInverted;
    g_hdr      = hdr;

    if (!Fsr3CreateOutputTexture())
    {
        if (g_ffxDestroyContext)
            g_ffxDestroyContext(&g_fgContext, nullptr);

        memset(&g_fgContext, 0, sizeof(g_fgContext));
        g_contextReady = false;
        g_fgDevice = nullptr;
        return false;
    }

    snprintf(
        g_status,
        sizeof(g_status),
        "context created: render %ux%u -> display %ux%u fmt=%u%s%s",
        renderWidth,
        renderHeight,
        displayWidth,
        displayHeight,
        static_cast<unsigned>(backBufferFormat),
        depthInverted ? " inverted-depth" : "",
        hdr ? " HDR" : "");

    return true;
}


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
    uint64_t frameID)
{
    if (!g_contextReady ||
        !g_ffxDispatch ||
        commandList == nullptr ||
        presentColor == nullptr ||
        depth == nullptr ||
        motionVectors == nullptr ||
        g_generated == nullptr)
    {
        SetStatus("FG dispatch resources not ready");
        return false;
    }

    const ULONGLONG now = GetTickCount64();

    float frameTimeMs = 16.6667f;

    if (g_fgLastTick != 0 && now > g_fgLastTick)
        frameTimeMs = static_cast<float>(now - g_fgLastTick);

    g_fgLastTick = now;

    ffxDispatchDescFrameGenerationPrepareV2 prep = {};

    prep.header.type =
        FFX_API_DISPATCH_DESC_TYPE_FRAMEGENERATION_PREPARE_V2;

    prep.frameID = frameID;
    prep.flags = FFX_FRAMEGENERATION_FLAG_NO_SWAPCHAIN_CONTEXT_NOTIFY;
    prep.commandList = commandList;

    prep.renderSize.width = renderWidth;
    prep.renderSize.height = renderHeight;

    prep.jitterOffset.x = jitterX;
    prep.jitterOffset.y = jitterY;

    prep.motionVectorScale.x = mvScaleX;
    prep.motionVectorScale.y = mvScaleY;

    prep.frameTimeDelta = frameTimeMs;
    prep.reset = reset;

    // Temporary camera values for workload validation.
    prep.cameraNear = 0.1f;
    prep.cameraFar = 10000.0f;
    prep.cameraFovAngleVertical = 1.0471975512f;
    prep.viewSpaceToMetersFactor = 1.0f;

    prep.cameraPosition[0] = 0.0f;
    prep.cameraPosition[1] = 0.0f;
    prep.cameraPosition[2] = 0.0f;

    prep.cameraUp[0] = 0.0f;
    prep.cameraUp[1] = 1.0f;
    prep.cameraUp[2] = 0.0f;

    prep.cameraRight[0] = 1.0f;
    prep.cameraRight[1] = 0.0f;
    prep.cameraRight[2] = 0.0f;

    prep.cameraForward[0] = 0.0f;
    prep.cameraForward[1] = 0.0f;
    prep.cameraForward[2] = 1.0f;

    prep.depth = Fsr3WrapResource(
        depth,
        FFX_API_RESOURCE_STATE_COMPUTE_READ);

    prep.motionVectors = Fsr3WrapResource(
        motionVectors,
        FFX_API_RESOURCE_STATE_COMPUTE_READ);

    const ffxReturnCode_t prepRc =
        g_ffxDispatch(&g_fgContext, &prep.header);

    if (prepRc != FFX_API_RETURN_OK)
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "PrepareV2 failed rc=%d frame=%llu",
            static_cast<int>(prepRc),
            static_cast<unsigned long long>(frameID));

        return false;
    }

    ffxDispatchDescFrameGeneration gen = {};

    gen.header.type =
        FFX_API_DISPATCH_DESC_TYPE_FRAMEGENERATION;

    gen.commandList = commandList;

    gen.presentColor = Fsr3WrapResource(
        presentColor,
        FFX_API_RESOURCE_STATE_COMPUTE_READ);

    gen.outputs[0] = Fsr3WrapResource(
        g_generated,
        FFX_API_RESOURCE_STATE_UNORDERED_ACCESS,
        FFX_API_RESOURCE_USAGE_UAV);

    gen.numGeneratedFrames = 1;
    gen.reset = reset;

    gen.backbufferTransferFunction =
        g_hdr
            ? FFX_API_BACKBUFFER_TRANSFER_FUNCTION_SCRGB
            : FFX_API_BACKBUFFER_TRANSFER_FUNCTION_SRGB;

    gen.minMaxLuminance[0] = 0.0f;
    gen.minMaxLuminance[1] = g_hdr ? 1000.0f : 100.0f;

    gen.generationRect.left = 0;
    gen.generationRect.top = 0;
    gen.generationRect.width = static_cast<int32_t>(g_displayW);
    gen.generationRect.height = static_cast<int32_t>(g_displayH);

    gen.frameID = frameID;

    const ffxReturnCode_t genRc =
        g_ffxDispatch(&g_fgContext, &gen.header);

    if (genRc != FFX_API_RETURN_OK)
    {
        snprintf(
            g_status,
            sizeof(g_status),
            "Generate failed rc=%d frame=%llu",
            static_cast<int>(genRc),
            static_cast<unsigned long long>(frameID));

        return false;
    }

    snprintf(
        g_status,
        sizeof(g_status),
        "generated frame %llu (%ux%u)",
        static_cast<unsigned long long>(frameID),
        g_displayW,
        g_displayH);

    return true;
}

ID3D12Resource* Fsr3FgGeneratedTexture()
{
    return g_generated;
}
bool Fsr3FgReady()
{
    return g_contextReady;
}

const char* Fsr3FgStatus()
{
    return g_status;
}


