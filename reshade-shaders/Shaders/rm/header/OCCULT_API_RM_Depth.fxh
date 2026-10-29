#ifndef OCCULT_API_RM_DEPTH_FXH
#define OCCULT_API_RM_DEPTH_FXH

#include "OCCULT_API_RM_Types.fxh"
#include "OCCULT_API_RM_IO.fxh"
#include "OCCULT_API_SafeMath.fxh"

// Runtime depth controls for RM 00+ diagnostics.
// Include guards remain compile-time; depth confidence thresholds are now UI-tunable.
uniform int OCCULT_RM_DepthReverseMode
<
    ui_type = "combo";
    ui_label = "RM Depth Reverse Mode";
    ui_items = "Use ReShade Setting\0Force Normal\0Force Reversed\0";
    ui_tooltip = "Runtime override for depth orientation. Use ReShade Setting follows RESHADE_DEPTH_INPUT_IS_REVERSED; Force Normal/Reversed helps diagnose inverted depth without recompiling.";
> = 0;

uniform float OCCULT_RM_DepthSkyThreshold
<
    ui_type = "slider";
    ui_label = "RM Sky Depth Threshold";
    ui_min = 0.800; ui_max = 1.000; ui_step = 0.001;
    ui_tooltip = "Linear-depth threshold treated as sky/far plane. Lower it if far scene geometry is being trusted as depth; raise it if sky is leaking into RM effects.";
> = 0.985;

uniform float OCCULT_RM_DepthEdgeScale
<
    ui_type = "slider";
    ui_label = "RM Depth Edge Scale";
    ui_min = 0.0001; ui_max = 0.0500; ui_step = 0.0001;
    ui_tooltip = "Normalizes local depth discontinuity into the edge-reject mask. Lower values make more pixels count as edges; higher values tolerate stronger depth jumps.";
> = 0.0060;

uniform float OCCULT_RM_EmptyDepthSpreadEpsilon
<
    ui_type = "slider";
    ui_label = "RM Empty Depth Spread Epsilon";
    ui_min = 0.000001; ui_max = 0.001000; ui_step = 0.000001;
    ui_tooltip = "Five-tap raw-depth spread below this is considered flat/empty-like. Increase if a flat depth buffer is not being rejected; decrease if valid flat surfaces are rejected.";
> = 0.000001;

uniform float OCCULT_RM_EmptyDepthNearThreshold
<
    ui_type = "slider";
    ui_label = "RM Empty Near Threshold";
    ui_min = 0.000000; ui_max = 0.050000; ui_step = 0.000100;
    ui_tooltip = "Average raw depth at or below this value is treated as near-empty when the buffer is flat. Use to catch games that clear depth to near zero.";
> = 0.000001;

uniform float OCCULT_RM_EmptyDepthFarThreshold
<
    ui_type = "slider";
    ui_label = "RM Empty Far Threshold";
    ui_min = 0.950000; ui_max = 1.000000; ui_step = 0.000100;
    ui_tooltip = "Average raw depth at or above this value is treated as far-empty when the buffer is flat. Lower if sky/far clear values are not being rejected.";
> = 0.999999;

float OCCULT_RM_DepthUseReversedForMode(int depthMode)
{
    float useReversed = 0.0;
#if RESHADE_DEPTH_INPUT_IS_REVERSED
    useReversed = 1.0;
#endif
    int mode = depthMode;
    // mode 0 follows the per-effect RM Depth Reverse Mode uniform.
    mode = (mode == 0) ? OCCULT_RM_DepthReverseMode : mode;
    useReversed = (mode == 1) ? 0.0 : useReversed;
    useReversed = (mode == 2) ? 1.0 : useReversed;
    return saturate(useReversed);
}

float OCCULT_RM_ConfiguredDepthMode(float rawDepth, int depthMode)
{
    float d = saturate(rawDepth);
    float useReversed = OCCULT_RM_DepthUseReversedForMode(depthMode);
    d = lerp(d, 1.0 - d, useReversed);
    return saturate(d);
}

float OCCULT_RM_ConfiguredDepth(float rawDepth)
{
    return OCCULT_RM_ConfiguredDepthMode(rawDepth, 0);
}

float OCCULT_RM_LinearDepth01FromRawMode(float rawDepth, int depthMode)
{
    float d = OCCULT_RM_ConfiguredDepthMode(rawDepth, depthMode);
    float farPlane = max((float)RESHADE_DEPTH_LINEARIZATION_FAR_PLANE, 1.0);
    float denom = d * (1.0 - farPlane) + farPlane;
    return saturate(OCCULT_SafeRcp(denom, 0.0));
}

float OCCULT_RM_LinearDepth01FromRaw(float rawDepth)
{
    return OCCULT_RM_LinearDepth01FromRawMode(rawDepth, 0);
}

float OCCULT_RM_LinearDepth01Mode(float2 uv, int depthMode)
{
    return OCCULT_RM_LinearDepth01FromRawMode(OCCULT_RM_LoadDepthRaw(uv), depthMode);
}

float OCCULT_RM_LinearDepth01(float2 uv)
{
    return OCCULT_RM_LinearDepth01Mode(uv, 0);
}

float OCCULT_RM_DepthEdgeMode(float2 uv, int depthMode)
{
    float2 px = OCCULT_RM_PixelSize();
    float c = OCCULT_RM_LinearDepth01Mode(uv, depthMode);
    float l = OCCULT_RM_LinearDepth01Mode(uv - float2(px.x, 0.0), depthMode);
    float r = OCCULT_RM_LinearDepth01Mode(uv + float2(px.x, 0.0), depthMode);
    float u = OCCULT_RM_LinearDepth01Mode(uv - float2(0.0, px.y), depthMode);
    float d = OCCULT_RM_LinearDepth01Mode(uv + float2(0.0, px.y), depthMode);
    float e = max(max(abs(c - l), abs(c - r)), max(abs(c - u), abs(c - d)));
    return saturate(e / max(OCCULT_RM_DepthEdgeScale, 0.000001));
}

float OCCULT_RM_DepthEdge(float2 uv)
{
    return OCCULT_RM_DepthEdgeMode(uv, 0);
}

float OCCULT_RM_EmptyLikeDepth(float2 uv)
{
    float2 px = OCCULT_RM_PixelSize();
    float c0 = OCCULT_RM_LoadDepthRaw(uv);
    float c1 = OCCULT_RM_LoadDepthRaw(uv + float2(px.x, 0.0));
    float c2 = OCCULT_RM_LoadDepthRaw(uv - float2(px.x, 0.0));
    float c3 = OCCULT_RM_LoadDepthRaw(uv + float2(0.0, px.y));
    float c4 = OCCULT_RM_LoadDepthRaw(uv - float2(0.0, px.y));
    float avg = (c0 + c1 + c2 + c3 + c4) * 0.2;
    float spread = max(max(abs(c0 - c1), abs(c0 - c2)), max(abs(c0 - c3), abs(c0 - c4)));
    float flat = (spread < max(OCCULT_RM_EmptyDepthSpreadEpsilon, 0.0000001)) ? 1.0 : 0.0;
    float nearFlat = (avg <= OCCULT_RM_EmptyDepthNearThreshold) ? 1.0 : 0.0;
    float farFlat = (avg >= OCCULT_RM_EmptyDepthFarThreshold) ? 1.0 : 0.0;
    return saturate(flat * max(nearFlat, farFlat));
}

OCCULT_RM_DepthSample OCCULT_RM_GetDepthMode(float2 uv, int depthMode)
{
    OCCULT_RM_DepthSample o;
    o.raw = 0.0;
    o.linear01 = 0.0;
    o.confidence = 0.0;
    o.edge = 1.0;
    o.sky = 0.0;
    o.empty_like = 1.0;

    float2 suv = OCCULT_RM_ClampUV(uv);
    o.raw = OCCULT_RM_LoadDepthRaw(suv);
    o.linear01 = OCCULT_RM_LinearDepth01FromRawMode(o.raw, depthMode);
    o.edge = OCCULT_RM_DepthEdgeMode(suv, depthMode);
    o.sky = (o.linear01 >= OCCULT_RM_DepthSkyThreshold) ? 1.0 : 0.0;
    o.empty_like = OCCULT_RM_EmptyLikeDepth(suv);

    float hasDepth = OCCULT_RM_HasDepth ? 1.0 : 0.0;
    o.confidence = saturate(hasDepth * (1.0 - o.edge) * (1.0 - o.sky) * (1.0 - o.empty_like));
    return o;
}

OCCULT_RM_DepthSample OCCULT_RM_GetDepth(float2 uv)
{
    return OCCULT_RM_GetDepthMode(uv, 0);
}

float3 OCCULT_RM_NormalFromDepthMode(float2 uv, int depthMode)
{
    float2 px = OCCULT_RM_PixelSize();
    float zx1 = OCCULT_RM_LinearDepth01Mode(uv + float2(px.x, 0.0), depthMode);
    float zx0 = OCCULT_RM_LinearDepth01Mode(uv - float2(px.x, 0.0), depthMode);
    float zy1 = OCCULT_RM_LinearDepth01Mode(uv + float2(0.0, px.y), depthMode);
    float zy0 = OCCULT_RM_LinearDepth01Mode(uv - float2(0.0, px.y), depthMode);
    float3 dx = float3(2.0 * px.x, 0.0, zx1 - zx0);
    float3 dy = float3(0.0, 2.0 * px.y, zy1 - zy0);
    float3 n = cross(dx, dy);
    float len2 = max(dot(n, n), 1.0e-8);
    return n * rsqrt(len2);
}

float3 OCCULT_RM_NormalFromDepth(float2 uv)
{
    return OCCULT_RM_NormalFromDepthMode(uv, 0);
}

#endif // OCCULT_API_RM_DEPTH_FXH
