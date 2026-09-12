// KB_HDR_LogWheels_JUICED.fx
// ReShade FX implementation of Resolve-inspired Primaries / Log Wheels.
// Pure .fx version: standard ReShade widgets only. A companion add-on can replace
// these controls with persistent circular wheels while driving the same uniforms.

#include "ReShade.fxh"

// -----------------------------------------------------------------------------
// UI
// -----------------------------------------------------------------------------

uniform int KB_SignalType <
    ui_type = "combo";
    ui_label = "Signal / Backbuffer";
    ui_items = "SDR / sRGB (Rec.709)\0HDR scRGB / Linear (Rec.709)\0HDR10 PQ / BT.2020\0";
    ui_tooltip = "Choose the encoding ReShade is actually receiving. The future add-on can auto-detect this from the swapchain.";
    ui_category = "00 - HDR / Signal";
> = 0;

uniform float KB_HDRReferenceWhite <
    ui_type = "drag";
    ui_min = 80.0; ui_max = 400.0; ui_step = 1.0;
    ui_units = " nits";
    ui_label = "HDR Reference White";
    ui_tooltip = "Reference white used when converting scRGB/PQ to the internal linear working space.";
    ui_category = "00 - HDR / Signal";
> = 203.0;

uniform float KB_Temperature <
    ui_type = "drag";
    ui_min = -100.0; ui_max = 100.0; ui_step = 0.1;
    ui_label = "Temp";
    ui_category = "01 - Primaries - Log Wheels";
> = 0.0;

uniform float KB_Tint <
    ui_type = "drag";
    ui_min = -100.0; ui_max = 100.0; ui_step = 0.1;
    ui_label = "Tint";
    ui_category = "01 - Primaries - Log Wheels";
> = 0.0;

uniform float KB_Contrast <
    ui_type = "drag";
    ui_min = 0.25; ui_max = 3.0; ui_step = 0.001;
    ui_label = "Contrast";
    ui_category = "01 - Primaries - Log Wheels";
> = 1.0;

uniform float KB_Pivot <
    ui_type = "drag";
    ui_min = 0.01; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Pivot";
    ui_category = "01 - Primaries - Log Wheels";
> = 0.435;

uniform float KB_LowRange <
    ui_type = "drag";
    ui_min = 0.01; ui_max = 0.95; ui_step = 0.001;
    ui_label = "Down Range";
    ui_tooltip = "Upper reach of the shadow/log range.";
    ui_category = "01 - Primaries - Log Wheels";
> = 0.333;

uniform float KB_HighRange <
    ui_type = "drag";
    ui_min = 0.05; ui_max = 0.99; ui_step = 0.001;
    ui_label = "Up Range";
    ui_tooltip = "Lower reach of the highlight/log range.";
    ui_category = "01 - Primaries - Log Wheels";
> = 0.550;

// Vector drags intentionally use -1..+1 with 0 = neutral. ReShade shows the
// components as RGB numeric controls. The custom add-on can render these as wheels.
uniform float3 KB_ShadowRGB <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
    ui_label = "Shadow RGB";
    ui_tooltip = "Log-domain RGB balance. 0,0,0 is neutral.";
    ui_category = "02 - Shadow";
> = float3(0.0, 0.0, 0.0);

uniform float KB_ShadowLevel <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Shadow Level";
    ui_category = "02 - Shadow";
> = 0.0;

uniform float3 KB_MidtoneRGB <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
    ui_label = "Midtone RGB";
    ui_tooltip = "Log-domain RGB balance. 0,0,0 is neutral.";
    ui_category = "03 - Midtone";
> = float3(0.0, 0.0, 0.0);

uniform float KB_MidtoneLevel <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Midtone Level";
    ui_category = "03 - Midtone";
> = 0.0;

uniform float3 KB_HighlightRGB <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
    ui_label = "Highlights RGB";
    ui_tooltip = "Log-domain RGB balance. 0,0,0 is neutral.";
    ui_category = "04 - Highlights";
> = float3(0.0, 0.0, 0.0);

uniform float KB_HighlightLevel <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Highlights Level";
    ui_category = "04 - Highlights";
> = 0.0;

uniform float3 KB_OffsetRGB <
    ui_type = "drag";
    ui_min = -1.0; ui_max = 1.0; ui_step = 0.001;
    ui_label = "Offset RGB";
    ui_tooltip = "Global RGB offset in the linear working space.";
    ui_category = "05 - Offset";
> = float3(0.0, 0.0, 0.0);

uniform float KB_OffsetLevel <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Offset Level";
    ui_category = "05 - Offset";
> = 0.0;

uniform float KB_MidDetails <
    ui_type = "drag";
    ui_min = -50.0; ui_max = 50.0; ui_step = 0.05;
    ui_label = "Mid Details (JUICED)";
    ui_tooltip = "HDR-aware local contrast / texture punch. Much stronger than v1; 0 is neutral.";
    ui_category = "06 - Primaries Extras";
> = 0.0;

uniform float KB_MidDetailRadius <
    ui_type = "drag";
    ui_min = 0.5; ui_max = 8.0; ui_step = 0.1;
    ui_units = " px";
    ui_label = "Mid Details Radius";
    ui_tooltip = "Larger values affect broader texture and surface relief; smaller values target fine detail.";
    ui_category = "06 - Primaries Extras";
> = 2.0;

uniform float KB_MidDetailFocus <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 100.0; ui_step = 1.0;
    ui_label = "Mid Details Midtone Focus";
    ui_tooltip = "100 = strongly restricted to midtones. 0 = detail enhancement across the whole tonal range.";
    ui_category = "06 - Primaries Extras";
> = 70.0;

uniform float KB_Sharpness <
    ui_type = "drag";
    ui_min = 0.0; ui_max = 20.0; ui_step = 0.05;
    ui_label = "Sharpness (SUPER JUICED)";
    ui_tooltip = "Luminance-preserving HDR sharpness. 0 is neutral; values above ~5 are intentionally aggressive.";
    ui_category = "07 - Detail / Sharpness";
> = 0.0;

uniform float KB_SharpRadius <
    ui_type = "drag";
    ui_min = 0.35; ui_max = 4.0; ui_step = 0.05;
    ui_units = " px";
    ui_label = "Sharpness Radius";
    ui_tooltip = "0.35-1.0 = crisp micro-sharpening; 1.5-4.0 = stronger edge bite.";
    ui_category = "07 - Detail / Sharpness";
> = 0.75;

uniform float KB_SharpLimit <
    ui_type = "drag";
    ui_min = 0.05; ui_max = 4.0; ui_step = 0.01;
    ui_label = "Sharpness Halo Limit";
    ui_tooltip = "Caps extreme local contrast before sharpening. Higher = more savage / more halo-prone.";
    ui_category = "07 - Detail / Sharpness";
> = 1.0;

uniform float KB_ColorBoost <
    ui_type = "drag";
    ui_min = -100.0; ui_max = 100.0; ui_step = 0.1;
    ui_label = "Color Boost";
    ui_tooltip = "Adaptive saturation: strongest on less-saturated colors.";
    ui_category = "06 - Primaries Extras";
> = 0.0;

uniform float KB_Shadows <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Shadows";
    ui_category = "06 - Primaries Extras";
> = 0.0;

uniform float KB_Highlights <
    ui_type = "drag";
    ui_min = -2.0; ui_max = 2.0; ui_step = 0.001;
    ui_label = "Highlights";
    ui_category = "06 - Primaries Extras";
> = 0.0;

uniform float KB_Saturation <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 100.0; ui_step = 0.1;
    ui_label = "Saturation";
    ui_category = "06 - Primaries Extras";
> = 50.0;

uniform float KB_Hue <
    ui_type = "slider";
    ui_min = 0.0; ui_max = 100.0; ui_step = 0.1;
    ui_label = "Hue";
    ui_tooltip = "50 is neutral. 0..100 spans a full hue rotation.";
    ui_category = "06 - Primaries Extras";
> = 50.0;

uniform bool KB_GamutClamp <
    ui_label = "Clamp negative / invalid gamut";
    ui_tooltip = "Useful for HDR10 PQ output. Leave off for scRGB if you want to preserve negative scRGB values.";
    ui_category = "08 - Safety";
> = true;

// -----------------------------------------------------------------------------
// Color management
// Internal working space: linear-light BT.2020, scaled so 1.0 = reference white.
// -----------------------------------------------------------------------------

static const float KB_PQ_m1 = 0.1593017578125; // 2610 / 16384
static const float KB_PQ_m2 = 78.84375;        // 2523 / 32
static const float KB_PQ_c1 = 0.8359375;       // 3424 / 4096
static const float KB_PQ_c2 = 18.8515625;      // 2413 / 128
static const float KB_PQ_c3 = 18.6875;         // 2392 / 128

float KB_sRGBToLinear1(float x)
{
    x = max(x, 0.0);
    return (x <= 0.04045) ? (x / 12.92) : pow((x + 0.055) / 1.055, 2.4);
}

float KB_LinearToSRGB1(float x)
{
    x = max(x, 0.0);
    return (x <= 0.0031308) ? (12.92 * x) : (1.055 * pow(x, 1.0 / 2.4) - 0.055);
}

float3 KB_sRGBToLinear(float3 x)
{
    return float3(KB_sRGBToLinear1(x.r), KB_sRGBToLinear1(x.g), KB_sRGBToLinear1(x.b));
}

float3 KB_LinearToSRGB(float3 x)
{
    return float3(KB_LinearToSRGB1(x.r), KB_LinearToSRGB1(x.g), KB_LinearToSRGB1(x.b));
}

float KB_PQToLinear1(float N)
{
    N = saturate(N);
    float p = pow(N, 1.0 / KB_PQ_m2);
    float num = max(p - KB_PQ_c1, 0.0);
    float den = max(KB_PQ_c2 - KB_PQ_c3 * p, 1e-6);
    return pow(num / den, 1.0 / KB_PQ_m1); // 0..1 => 0..10000 nits
}

float KB_LinearToPQ1(float L)
{
    L = max(L, 0.0);
    float p = pow(L, KB_PQ_m1);
    return pow((KB_PQ_c1 + KB_PQ_c2 * p) / (1.0 + KB_PQ_c3 * p), KB_PQ_m2);
}

float3 KB_PQToLinear(float3 x)
{
    return float3(KB_PQToLinear1(x.r), KB_PQToLinear1(x.g), KB_PQToLinear1(x.b));
}

float3 KB_LinearToPQ(float3 x)
{
    return float3(KB_LinearToPQ1(x.r), KB_LinearToPQ1(x.g), KB_LinearToPQ1(x.b));
}

float3 KB_709To2020(float3 c)
{
    return float3(
        dot(c, float3(0.6274040, 0.3292820, 0.0433136)),
        dot(c, float3(0.0690970, 0.9195400, 0.0113612)),
        dot(c, float3(0.0163916, 0.0880132, 0.8955950))
    );
}

float3 KB_2020To709(float3 c)
{
    return float3(
        dot(c, float3( 1.6604910, -0.5876411, -0.0728499)),
        dot(c, float3(-0.1245505,  1.1328999, -0.0083494)),
        dot(c, float3(-0.0181508, -0.1005789,  1.1187297))
    );
}

float3 KB_Decode(float3 encoded)
{
    // SDR / sRGB -> linear Rec.709 -> linear BT.2020.
    if (KB_SignalType == 0)
        return KB_709To2020(KB_sRGBToLinear(encoded));

    // scRGB is linear with sRGB/Rec.709 primaries. Nominal scRGB 1.0 = 80 nits.
    if (KB_SignalType == 1)
        return KB_709To2020(encoded * (80.0 / max(KB_HDRReferenceWhite, 1.0)));

    // HDR10 PQ is BT.2020, with ST.2084 normalized to 10,000 nits.
    float3 absNorm = KB_PQToLinear(encoded);
    return absNorm * (10000.0 / max(KB_HDRReferenceWhite, 1.0));
}

float3 KB_Encode(float3 working)
{
    if (KB_GamutClamp || KB_SignalType != 1)
        working = max(working, 0.0);

    if (KB_SignalType == 0)
        return KB_LinearToSRGB(KB_2020To709(working));

    if (KB_SignalType == 1)
        return KB_2020To709(working) * (max(KB_HDRReferenceWhite, 1.0) / 80.0);

    float3 absNorm = working * (max(KB_HDRReferenceWhite, 1.0) / 10000.0);
    return KB_LinearToPQ(absNorm);
}

float KB_Luma2020(float3 c)
{
    return dot(c, float3(0.2627, 0.6780, 0.0593));
}

// Smooth normalized HDR luminance. Reference white maps to 0.5, highlights remain
// addressable rather than being hard-clipped at 1.0.
float KB_RangeCoordinate(float y)
{
    y = max(y, 0.0);
    return y / (1.0 + y);
}

void KB_ZoneWeights(float y, out float ws, out float wm, out float wh)
{
    float z = KB_RangeCoordinate(y);
    float feather = 0.12;

    ws = 1.0 - smoothstep(max(KB_LowRange - feather, 0.0), min(KB_LowRange + feather, 1.0), z);
    wh = smoothstep(max(KB_HighRange - feather, 0.0), min(KB_HighRange + feather, 1.0), z);
    wm = saturate(1.0 - max(ws, wh));
}

float3 KB_ApplyWhiteBalance(float3 c)
{
    float t = KB_Temperature * 0.01;
    float g = KB_Tint * 0.01;

    // Deliberately gentle and exposure-like. Positive Temp warms; positive Tint magentas.
    float3 scale = exp2(float3(0.22 * t + 0.05 * g, -0.10 * g, -0.22 * t + 0.05 * g));
    return c * scale;
}

float3 KB_ApplyContrast(float3 c)
{
    float y = max(KB_Luma2020(c), 1e-6);
    float p = max(KB_Pivot, 1e-5);
    float newY = p * pow(y / p, max(KB_Contrast, 0.001));
    return c * (newY / y);
}

float3 KB_ApplyLogWheels(float3 c)
{
    float y = max(KB_Luma2020(c), 0.0);
    float ws, wm, wh;
    KB_ZoneWeights(y, ws, wm, wh);

    // RGB wheel moves are log/exposure-like so they continue behaving in HDR.
    float3 stops = KB_ShadowRGB * ws + KB_MidtoneRGB * wm + KB_HighlightRGB * wh;
    float levelStops = KB_ShadowLevel * ws + KB_MidtoneLevel * wm + KB_HighlightLevel * wh;

    c *= exp2(stops * 2.0 + levelStops);

    // Offset is global and intentionally linear-light.
    c += KB_OffsetRGB * 0.10;
    c *= exp2(KB_OffsetLevel);

    return c;
}

float3 KB_ApplyShadowHighlight(float3 c)
{
    float y = max(KB_Luma2020(c), 0.0);
    float ws, wm, wh;
    KB_ZoneWeights(y, ws, wm, wh);
    return c * exp2(KB_Shadows * ws + KB_Highlights * wh);
}

float3 KB_ApplySaturationAndBoost(float3 c)
{
    float y = KB_Luma2020(c);
    float3 gray = y.xxx;

    float sat = KB_Saturation / 50.0; // 50 = neutral
    c = lerp(gray, c, sat);

    float maxc = max(c.r, max(c.g, c.b));
    float minc = min(c.r, min(c.g, c.b));
    float chroma = maxc - minc;
    float normalizedChroma = chroma / max(max(abs(y), maxc), 1e-4);

    float boost = KB_ColorBoost * 0.01;
    float adaptive = boost * (1.0 - saturate(normalizedChroma));
    c = lerp(KB_Luma2020(c).xxx, c, 1.0 + adaptive);
    return c;
}

float3 KB_HueRotate(float3 c, float angle)
{
    // Rotate around the neutral gray axis. This is a grading control rather than
    // a colorspace conversion, so preserving energy matters more than exact HSV math.
    float s = sin(angle);
    float co = cos(angle);
    const float invSqrt3 = 0.57735026919;
    float3 k = float3(invSqrt3, invSqrt3, invSqrt3);
    return c * co + cross(k, c) * s + k * dot(k, c) * (1.0 - co);
}

float3 KB_Process(float3 working)
{
    float3 c = working;
    c = KB_ApplyWhiteBalance(c);
    c = KB_ApplyContrast(c);
    c = KB_ApplyLogWheels(c);
    c = KB_ApplyShadowHighlight(c);
    c = KB_ApplySaturationAndBoost(c);

    float hueAngle = (KB_Hue - 50.0) * (6.28318530718 / 100.0);
    c = KB_HueRotate(c, hueAngle);

    return c;
}

float3 KB_SampleWorking(float2 uv)
{
    return KB_Decode(tex2D(ReShade::BackBuffer, uv).rgb);
}

float4 KB_HDRLogWheelsPS(float4 pos : SV_Position, float2 uv : TEXCOORD) : SV_Target
{
    float3 center = KB_SampleWorking(uv);
    float3 graded = KB_Process(center);

    // ---------------------------------------------------------------------
    // JUICED MID DETAILS
    // Broader 8-tap local-contrast extraction with a configurable radius.
    // The result modulates luminance multiplicatively, which keeps hue/chroma
    // far more stable than simply adding gray detail and scales cleanly in HDR.
    // ---------------------------------------------------------------------
    if (abs(KB_MidDetails) > 0.0001)
    {
        float2 px = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * KB_MidDetailRadius;
        float2 pd = px * 0.70710678118;

        float y0 = max(KB_Luma2020(center), 0.0);
        float y1 = max(KB_Luma2020(KB_SampleWorking(uv + float2( px.x,  0.0))), 0.0);
        float y2 = max(KB_Luma2020(KB_SampleWorking(uv + float2(-px.x,  0.0))), 0.0);
        float y3 = max(KB_Luma2020(KB_SampleWorking(uv + float2( 0.0,  px.y))), 0.0);
        float y4 = max(KB_Luma2020(KB_SampleWorking(uv + float2( 0.0, -px.y))), 0.0);
        float y5 = max(KB_Luma2020(KB_SampleWorking(uv + float2( pd.x,  pd.y))), 0.0);
        float y6 = max(KB_Luma2020(KB_SampleWorking(uv + float2(-pd.x,  pd.y))), 0.0);
        float y7 = max(KB_Luma2020(KB_SampleWorking(uv + float2( pd.x, -pd.y))), 0.0);
        float y8 = max(KB_Luma2020(KB_SampleWorking(uv + float2(-pd.x, -pd.y))), 0.0);

        float blurY = (y0 * 2.0 + y1 + y2 + y3 + y4 + y5 + y6 + y7 + y8) / 10.0;
        float detailNorm = (y0 - blurY) / max(blurY, 0.02);
        detailNorm = clamp(detailNorm, -1.5, 1.5);

        float ws, wm, wh;
        KB_ZoneWeights(y0, ws, wm, wh);
        float focus = KB_MidDetailFocus * 0.01;
        float tonalWeight = lerp(1.0, saturate(wm + 0.10 * (ws + wh)), focus);

        // At 10 this is already very visible; 25-50 is intentionally absurd.
        float detailStops = detailNorm * KB_MidDetails * 0.10 * tonalWeight;
        detailStops = clamp(detailStops, -4.0, 4.0);
        graded *= exp2(detailStops);
    }

    // ---------------------------------------------------------------------
    // SUPER JUICED SHARPNESS
    // Tight 4-tap high-pass on HDR luminance. Uses exposure-like modulation
    // so it remains useful above reference white instead of clipping at 1.0.
    // ---------------------------------------------------------------------
    if (KB_Sharpness > 0.0001)
    {
        float2 spx = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) * KB_SharpRadius;
        float sy0 = max(KB_Luma2020(center), 0.0);
        float sy1 = max(KB_Luma2020(KB_SampleWorking(uv + float2( spx.x, 0.0))), 0.0);
        float sy2 = max(KB_Luma2020(KB_SampleWorking(uv + float2(-spx.x, 0.0))), 0.0);
        float sy3 = max(KB_Luma2020(KB_SampleWorking(uv + float2(0.0,  spx.y))), 0.0);
        float sy4 = max(KB_Luma2020(KB_SampleWorking(uv + float2(0.0, -spx.y))), 0.0);

        float sblurY = (sy1 + sy2 + sy3 + sy4) * 0.25;
        float sharpNorm = (sy0 - sblurY) / max(sblurY, 0.02);
        sharpNorm = clamp(sharpNorm, -KB_SharpLimit, KB_SharpLimit);

        // 1.0 = sensible crispness; 5+ = hard bite; 10-20 = deliberately nuclear.
        float sharpStops = sharpNorm * KB_Sharpness * 0.16;
        sharpStops = clamp(sharpStops, -3.0, 3.0);
        graded *= exp2(sharpStops);
    }

    if (KB_GamutClamp || KB_SignalType != 1)
        graded = max(graded, 0.0);

    return float4(KB_Encode(graded), 1.0);
}

technique KB_HDR_LogWheels <
    ui_label = "KB HDR - Primaries Log Wheels";
    ui_tooltip = "Resolve-inspired log grading in linear BT.2020 with JUICED mid-detail and HDR-aware sharpness.";
>
{
    pass
    {
        VertexShader = PostProcessVS;
        PixelShader = KB_HDRLogWheelsPS;
    }
}
