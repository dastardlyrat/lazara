#ifndef OCCULT_API_RM_SSR_FXH
#define OCCULT_API_RM_SSR_FXH

#include "OCCULT_API_RM_Ray.fxh"
#include "OCCULT_API_RM_Debug.fxh"

#ifndef OCCULT_RM_SSR_DEFAULT_STEPS
#define OCCULT_RM_SSR_DEFAULT_STEPS 20
#endif

#ifndef OCCULT_RM_SSR_STRICT_PASS_COUNT
#define OCCULT_RM_SSR_STRICT_PASS_COUNT 24
#endif

struct OCCULT_RM_SSRBatchColor
{
    float3 rgb;
    float weight;
    float hit_count;
    float confidence;
};

OCCULT_RM_SSRBatchColor OCCULT_RM_InitSSRBatchColor()
{
    OCCULT_RM_SSRBatchColor a;
    a.rgb = float3(0.0, 0.0, 0.0);
    a.weight = 0.0;
    a.hit_count = 0.0;
    a.confidence = 0.0;
    return a;
}

float2 OCCULT_RM_SSR_BaseDirection(float2 uv)
{
    float3 n = OCCULT_RM_NormalFromDepth(uv);
    float2 fromNormal = OCCULT_RM_SafeNormalize2(-n.xy, float2(1.0, 0.0));
    return fromNormal;
}

float2 OCCULT_RM_SSR_TapDirection(float2 uv, int tap, int tapCount, float roughness, float seed)
{
    float2 baseDir = OCCULT_RM_SSR_BaseDirection(uv);
    float2 jitterDir = OCCULT_RM_RingDirection(tap, max(tapCount, 1), seed);
    float mixAmount = saturate(roughness);
    return OCCULT_RM_SafeNormalize2(lerp(baseDir, jitterDir, mixAmount), baseDir);
}

float OCCULT_RM_SSR_DistanceWeight(OCCULT_RM_Hit hit, int steps)
{
    float denom = max((float)steps, 1.0);
    float step01 = saturate(hit.step_index / denom);
    return saturate((1.0 - step01) * hit.confidence * hit.hit);
}

// Legacy four-batch helper retained for compatibility, but production SSR now uses strict single-tap passes.
OCCULT_RM_SSRBatchColor OCCULT_RM_SSRBatch(float2 uv, int batchStart, int activeDirections, int activeSteps, float rayLengthUv, float thickness, float roughness, float seed)
{
    OCCULT_RM_SSRBatchColor accum = OCCULT_RM_InitSSRBatchColor();
    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uv);
    int safeSteps = max(activeSteps, 1);

    [unroll]
    for (int localTap = 0; localTap < OCCULT_PASS_BATCH_DIRECTIONS; ++localTap)
    {
        int tap = batchStart + localTap;
        if (tap < activeDirections && center.confidence > 0.0)
        {
            float2 dir = OCCULT_RM_SSR_TapDirection(uv, tap, activeDirections, roughness, seed);
            float2 startUv = uv + dir * OCCULT_RM_PixelSize() * 2.0;
            OCCULT_RM_Ray ray = OCCULT_RM_MakeScreenRay(startUv, dir, rayLengthUv, center.linear01 + thickness * 2.0, rayLengthUv * 0.75, thickness, 0.08, safeSteps);
            OCCULT_RM_Hit hit = OCCULT_RM_MarchDepth(ray);
            float hitWeight = OCCULT_RM_SSR_DistanceWeight(hit, safeSteps) * center.confidence;
            if (hitWeight > 0.0)
            {
                float3 hitColor = OCCULT_RM_LoadColor(hit.uv).rgb;
                accum.rgb += hitColor * hitWeight;
                accum.weight += hitWeight;
                accum.hit_count += hit.hit;
                accum.confidence += hit.confidence;
            }
        }
    }

    accum.confidence = accum.hit_count > 0.0 ? saturate(accum.confidence / max(accum.hit_count, 1.0)) : 0.0;
    return accum;
}

float4 OCCULT_RM_PackSSRBatch(OCCULT_RM_SSRBatchColor a)
{
    return float4(a.rgb, a.weight);
}

float3 OCCULT_RM_UnpackSSRColor(float4 a0, float4 a1, float4 a2, float4 a3, out float weightOut)
{
    float3 rgbSum = a0.rgb + a1.rgb + a2.rgb + a3.rgb;
    float weightSum = a0.a + a1.a + a2.a + a3.a;
    weightOut = weightSum;
    return rgbSum * OCCULT_SafeRcp(max(weightSum, 0.000001), 0.0);
}

float4 OCCULT_RM_SSRStrictTap(float2 uv, int tap, int activeDirections, int activeSteps, float rayLengthUv, float thickness, float roughness, float seed)
{
    float3 rgb = float3(0.0, 0.0, 0.0);
    float weight = 0.0;
    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uv);
    int safeSteps = max(activeSteps, 1);

    if (tap < activeDirections && center.confidence > 0.0)
    {
        float2 dir = OCCULT_RM_SSR_TapDirection(uv, tap, activeDirections, roughness, seed);
        float2 startUv = uv + dir * OCCULT_RM_PixelSize() * 2.0;
        OCCULT_RM_Ray ray = OCCULT_RM_MakeScreenRay(startUv, dir, rayLengthUv, center.linear01 + thickness * 2.0, rayLengthUv * 0.75, thickness, 0.08, safeSteps);
        OCCULT_RM_Hit hit = OCCULT_RM_MarchDepth(ray);
        weight = OCCULT_RM_SSR_DistanceWeight(hit, safeSteps) * center.confidence;
        if (weight > 0.0)
        {
            rgb = OCCULT_RM_LoadColor(hit.uv).rgb * weight;
        }
    }

    return float4(rgb, weight);
}

#endif // OCCULT_API_RM_SSR_FXH
