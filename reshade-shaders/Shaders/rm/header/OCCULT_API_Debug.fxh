#ifndef OCCULT_API_DEBUG_FXH
#define OCCULT_API_DEBUG_FXH

float3 OCCULT_DebugHeat(float value)
{
    float v = saturate(value);
    return float3(v, v * v, 1.0 - v);
}

float3 OCCULT_DebugHitMiss(bool hitValue, float confidenceValue)
{
    float c = saturate(confidenceValue);
    return hitValue ? float3(0.0, c, 0.0) : float3(c, 0.0, 0.0);
}

float4 OCCULT_DebugRGBA(float3 rgb, float alphaValue)
{
    return float4(saturate(rgb), saturate(alphaValue));
}

#endif // OCCULT_API_DEBUG_FXH
