// KageBlink - SideBySide.fx
// Star Lifter comparison helper.
// IMPORTANT ORDERING:
//   DLSSCompare_Capture must be FIRST / TOP in the ReShade technique list.
//   DLSSCompare_Output must be LAST / BOTTOM in the ReShade technique list.
// F7 toggles the final side-by-side presentation without changing the rest of the effect chain.

texture2D BackBuffer : COLOR;

// F7 = VK_F7 (0x76). ReShade exposes keyboard state directly to effect uniforms.
uniform bool DLSSCompare_SideBySideEnabled <
    source = "key";
    keycode = 0x76;
    mode = "toggle";
>;

// Only store the ORIGINAL at the size we actually need.
// At 3440 output this becomes 1720x1290 instead of 3440x1440.
texture2D OriginalHalf
{
    Width = BUFFER_WIDTH / 2;
    Height = BUFFER_WIDTH * 3 / 8;
    Format = RGBA8;
};

sampler2D BackBufferSampler
{
    Texture = BackBuffer;
};

sampler2D OriginalSampler
{
    Texture = OriginalHalf;
};

void SBS_VS(
    uint id : SV_VertexID,
    out float4 position : SV_Position,
    out float2 texcoord : TEXCOORD0)
{
    texcoord.x = (id == 2) ? 2.0 : 0.0;
    texcoord.y = (id == 1) ? 2.0 : 0.0;

    position = float4(
        texcoord * float2(2.0, -2.0) + float2(-1.0, 1.0),
        0.0,
        1.0
    );
}

// Save ONLY the real 4:3 game image.
// The render target itself is already 4:3.
float4 CaptureOriginalPS(
    float4 pos : SV_Position,
    float2 uv : TEXCOORD0
) : SV_Target
{
    const float gameAspect = 4.0 / 3.0;
    const float backAspect = BUFFER_WIDTH / BUFFER_HEIGHT;

    float gameWidthUV = gameAspect / backAspect;
    float cropLeft = (1.0 - gameWidthUV) * 0.5;

    float2 src;
    src.x = cropLeft + uv.x * gameWidthUV;
    src.y = uv.y;

    return tex2D(BackBufferSampler, src);
}

float4 SideBySidePS(
    float4 pos : SV_Position,
    float2 uv : TEXCOORD0
) : SV_Target
{
    // F7 OFF: pass the fully processed frame through unchanged.
    if (!DLSSCompare_SideBySideEnabled)
        return tex2D(BackBufferSampler, uv);

    const float gameAspect = 4.0 / 3.0;
    const float backAspect = BUFFER_WIDTH / BUFFER_HEIGHT;

    float gameWidthUV = gameAspect / backAspect;
    float cropLeft = (1.0 - gameWidthUV) * 0.5;

    // Preserve 4:3 inside each half of the ultrawide output.
    float halfAspect = (BUFFER_WIDTH * 0.5) / BUFFER_HEIGHT;
    float imageHeight = halfAspect / gameAspect;

    float top = (1.0 - imageHeight) * 0.5;
    float bottom = top + imageHeight;

    if (uv.y < top || uv.y > bottom)
        return float4(0.0, 0.0, 0.0, 1.0);

    float y = (uv.y - top) / imageHeight;

    if (uv.x < 0.5)
    {
        // LEFT = saved pre-chain / vanilla image captured at the top.
        float x = uv.x * 2.0;
        return tex2D(OriginalSampler, float2(x, y));
    }
    else
    {
        // RIGHT = current fully processed Star Lifter / ReShade image.
        float x = (uv.x - 0.5) * 2.0;
        float sourceX = cropLeft + x * gameWidthUV;

        return tex2D(BackBufferSampler, float2(sourceX, y));
    }
}

technique DLSSCompare_Capture <
    ui_label = "DLSSCompare_Capture — PLACE FIRST / TOP";
    ui_tooltip = "Must be the first enabled technique so it captures the image before Star Lifter/ReShade processing.";
>
{
    pass
    {
        VertexShader = SBS_VS;
        PixelShader = CaptureOriginalPS;
        RenderTarget = OriginalHalf;
    }
}

technique DLSSCompare_Output <
    ui_label = "DLSSCompare_Output — PLACE LAST / BOTTOM — F7";
    ui_tooltip = "Must be the last enabled technique. Press F7 to toggle side-by-side presentation.";
>
{
    pass
    {
        VertexShader = SBS_VS;
        PixelShader = SideBySidePS;
    }
}
