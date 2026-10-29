#ifndef MIXSR_API_DEBUG_VISIBILITY_FXH
#define MIXSR_API_DEBUG_VISIBILITY_FXH 1

#include "MIXSR_API_LoopSafe.fxh"

float MIXSR_DebugVisibilityScalar(float value, float exposure, float bias, float contrast, float gammaValue, float floorValue)
{
    float v = saturate(value * max(exposure, 0.0) + bias);
    v = saturate((v - 0.5) * max(contrast, 0.0) + 0.5);
    v = MIXSR_SafePowNonNegative(v, max(gammaValue, 0.0001));
    return max(v, saturate(floorValue));
}

float3 MIXSR_DebugVisibilityColor(float3 color, float exposure, float bias, float contrast, float gammaValue, float floorValue)
{
    float3 c = saturate(color * max(exposure, 0.0) + bias.xxx);
    c = saturate((c - 0.5.xxx) * max(contrast, 0.0) + 0.5.xxx);
    c = float3(
        MIXSR_SafePowNonNegative(c.r, max(gammaValue, 0.0001)),
        MIXSR_SafePowNonNegative(c.g, max(gammaValue, 0.0001)),
        MIXSR_SafePowNonNegative(c.b, max(gammaValue, 0.0001))
    );
    return max(c, saturate(floorValue).xxx);
}

float3 MIXSR_DebugVisibilityHeat(float v)
{
    float x = saturate(v);
    float3 cold = float3(0.02, 0.05, 0.35);
    float3 mid  = float3(0.05, 0.95, 0.20);
    float3 hot  = float3(1.00, 0.18, 0.02);
    float3 lo = lerp(cold, mid, saturate(x * 2.0));
    float3 hi = lerp(mid, hot, saturate((x - 0.5) * 2.0));
    return (x < 0.5) ? lo : hi;
}

float3 MIXSR_DebugVisibilityPost(
    float3 color,
    int postMode,
    float exposure,
    float bias,
    float contrast,
    float gammaValue,
    float floorValue,
    float thresholdValue)
{
    float3 adjusted = MIXSR_DebugVisibilityColor(color, exposure, bias, contrast, gammaValue, floorValue);
    float luma = dot(adjusted, float3(0.2126, 0.7152, 0.0722));
    float mask = (luma >= saturate(thresholdValue)) ? 1.0 : 0.0;
    float3 result = adjusted;

    if (postMode == 1)
    {
        result = max(adjusted, saturate(floorValue).xxx);
    }
    else if (postMode == 2)
    {
        result = MIXSR_DebugVisibilityHeat(luma);
    }
    else if (postMode == 3)
    {
        result = mask.xxx;
    }
    else if (postMode == 4)
    {
        result = 1.0.xxx - adjusted;
    }
    return result;
}

#endif // MIXSR_API_DEBUG_VISIBILITY_FXH
