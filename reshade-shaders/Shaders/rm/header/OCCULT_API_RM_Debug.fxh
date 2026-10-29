#ifndef OCCULT_API_RM_DEBUG_FXH
#define OCCULT_API_RM_DEBUG_FXH

#include "OCCULT_API_RM_Types.fxh"
#include "OCCULT_API_Debug.fxh"

float3 OCCULT_RM_ColorInvalid() { return float3(1.0, 0.0, 1.0); }
float3 OCCULT_RM_ColorMiss()    { return float3(0.05, 0.15, 0.95); }
float3 OCCULT_RM_ColorHit()     { return float3(0.10, 1.00, 0.25); }
float3 OCCULT_RM_ColorEdge()    { return float3(1.00, 0.25, 0.05); }
float3 OCCULT_RM_ColorSky()     { return float3(0.20, 0.45, 1.00); }

float3 OCCULT_RM_EncodeDepth(OCCULT_RM_DepthSample d)
{
    float3 baseColor = d.linear01.xxx;
    float3 outColor = lerp(OCCULT_RM_ColorInvalid(), baseColor, d.confidence);
    outColor = lerp(outColor, OCCULT_RM_ColorEdge(), saturate(d.edge) * 0.60);
    outColor = lerp(outColor, OCCULT_RM_ColorSky(), saturate(d.sky) * 0.50);
    return saturate(outColor);
}

float3 OCCULT_RM_EncodeHit(OCCULT_RM_Hit h)
{
    float stepHeat = saturate(h.step_index / max((float)OCCULT_RM_DEFAULT_STEPS, 1.0));
    float3 missColor = lerp(OCCULT_RM_ColorMiss(), OCCULT_RM_ColorEdge(), saturate(h.reason * 0.25));
    float3 hitColor = lerp(OCCULT_RM_ColorHit(), OCCULT_DebugHeat(stepHeat), 0.35);
    float3 outColor = lerp(missColor, hitColor, h.hit);
    outColor = lerp(outColor, OCCULT_RM_ColorInvalid(), 1.0 - saturate(h.confidence));
    return saturate(outColor);
}

float3 OCCULT_RM_EncodeNormal(float3 n)
{
    return saturate(n * 0.5 + 0.5);
}

#endif // OCCULT_API_RM_DEBUG_FXH
