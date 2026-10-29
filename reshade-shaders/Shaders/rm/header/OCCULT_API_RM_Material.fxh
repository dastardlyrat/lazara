#ifndef OCCULT_API_RM_MATERIAL_FXH
#define OCCULT_API_RM_MATERIAL_FXH

#include "OCCULT_API_RM_PrimaryMarch.fxh"
#include "OCCULT_API_RM_IO.fxh"
#include "OCCULT_API_RM_Depth.fxh"

struct OCCULT_RM_PostHitMaterial
{
    float valid;
    float hit;
    float2 uv;
    float3 color;
    float luma;
    float edge;
    float confidence;
};

OCCULT_RM_PostHitMaterial OCCULT_RM_InitPostHitMaterial(float2 uv)
{
    OCCULT_RM_PostHitMaterial m;
    m.valid = 0.0;
    m.hit = 0.0;
    m.uv = OCCULT_RM_ClampUV(uv);
    m.color = float3(0.0, 0.0, 0.0);
    m.luma = 0.0;
    m.edge = 1.0;
    m.confidence = 0.0;
    return m;
}

float2 OCCULT_RM_PostHitUVFromSDF(float2 baseUV, OCCULT_RM_SDFHit hit, float projectionScale, float normalSlide)
{
    float aspect = BUFFER_WIDTH * OCCULT_SafeRcp(max((float)BUFFER_HEIGHT, 1.0), 1.0);
    float2 projected = float2(hit.p.x / max(aspect, 0.000001), -hit.p.y) * projectionScale;
    float2 normalOffset = hit.n.xy * normalSlide;
    return OCCULT_RM_ClampUV(baseUV + projected + normalOffset);
}

float3 OCCULT_RM_LoadColorExplicitLOD(float2 uv, float lodLevel)
{
    return tex2Dlod(OCCULT_RM_ColorSampler, float4(OCCULT_RM_ClampUV(uv), 0.0, max(lodLevel, 0.0))).rgb;
}

OCCULT_RM_PostHitMaterial OCCULT_RM_FetchPostHitMaterialLOD(float2 baseUV, OCCULT_RM_SDFHit hit, float projectionScale, float normalSlide, float lodLevel)
{
    OCCULT_RM_PostHitMaterial m = OCCULT_RM_InitPostHitMaterial(baseUV);
    m.hit = saturate(hit.hit);

    float2 hitUV = OCCULT_RM_PostHitUVFromSDF(baseUV, hit, projectionScale, normalSlide);
    float3 color = OCCULT_RM_LoadColorExplicitLOD(hitUV, lodLevel);
    OCCULT_RM_DepthSample d = OCCULT_RM_GetDepth(hitUV);

    m.valid = saturate(hit.hit * hit.confidence * d.confidence);
    m.uv = hitUV;
    m.color = color;
    m.luma = OCCULT_RM_Luma(color);
    m.edge = d.edge;
    m.confidence = saturate(hit.confidence * d.confidence * (1.0 - d.edge));
    return m;
}

float3 OCCULT_RM_EncodePostHitMaterial(OCCULT_RM_PostHitMaterial m, OCCULT_RM_SDFHit hit, float3 sourceColor, float debugBlend, float materialBlend)
{
    float stepHeat = saturate(hit.step_index * OCCULT_SafeRcp(max((float)OCCULT_RM_SDF_MAX_STEPS, 1.0), 0.0));
    float3 missDebug = OCCULT_RM_EncodeSDFHit(hit, OCCULT_RM_SDF_MAX_STEPS);
    float3 uvDebug = float3(m.uv.x, m.uv.y, saturate(m.luma));
    float3 materialDebug = lerp(uvDebug, m.color, saturate(materialBlend));
    materialDebug = lerp(materialDebug, OCCULT_DebugHeat(stepHeat), saturate(m.edge) * 0.35);
    materialDebug = lerp(float3(1.0, 0.0, 1.0), materialDebug, saturate(m.confidence));
    float3 hitOut = lerp(materialDebug, m.color, saturate(materialBlend));
    float3 outColor = lerp(missDebug, hitOut, saturate(m.valid));
    outColor = lerp(outColor, sourceColor, saturate(debugBlend));
    return saturate(outColor);
}

#endif // OCCULT_API_RM_MATERIAL_FXH
