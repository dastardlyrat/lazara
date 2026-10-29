#ifndef OCCULT_API_RM_PASS_SAMPLING_FXH
#define OCCULT_API_RM_PASS_SAMPLING_FXH

#include "OCCULT_API_RM_Ray.fxh"
#include "OCCULT_API_RM_Sampling.fxh"

OCCULT_RM_BatchAccum OCCULT_RM_InitBatchAccum()
{
    OCCULT_RM_BatchAccum a;
    a.value = 0.0;
    a.weight = 0.0;
    a.hit_count = 0.0;
    a.confidence = 0.0;
    return a;
}

OCCULT_RM_BatchAccum OCCULT_RM_ContactBatch(float2 uv, int batchStart, int activeDirections, int activeSteps, float radiusUv, float thickness, float seed)
{
    OCCULT_RM_BatchAccum accum = OCCULT_RM_InitBatchAccum();
    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uv);

    [unroll]
    for (int localTap = 0; localTap < OCCULT_PASS_BATCH_DIRECTIONS; ++localTap)
    {
        int tap = batchStart + localTap;
        if (tap < activeDirections && center.confidence > 0.0)
        {
            float2 dir = OCCULT_RM_RingDirection(tap, activeDirections, seed);
            float contact = OCCULT_RM_ContactProbe(uv, dir, radiusUv, thickness, activeSteps);
            accum.value += contact;
            accum.weight += 1.0;
            accum.hit_count += contact > 0.0 ? 1.0 : 0.0;
            accum.confidence += center.confidence;
        }
    }

    accum.confidence = accum.weight > 0.0 ? saturate(accum.confidence / accum.weight) : 0.0;
    return accum;
}

OCCULT_RM_BatchAccum OCCULT_RM_AOBatch(float2 uv, int batchStart, int activeDirections, float radiusUv, float thickness, float seed)
{
    OCCULT_RM_BatchAccum accum = OCCULT_RM_InitBatchAccum();
    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uv);

    [unroll]
    for (int localTap = 0; localTap < OCCULT_PASS_BATCH_DIRECTIONS; ++localTap)
    {
        int tap = batchStart + localTap;
        if (tap < activeDirections && center.confidence > 0.0)
        {
            float2 offsetUv = OCCULT_RM_GoldenDirection(tap, activeDirections, seed) * radiusUv;
            OCCULT_RM_DepthSample sampleDepth = OCCULT_RM_GetDepth(uv + offsetUv);
            float dz = sampleDepth.linear01 - center.linear01;
            float occluder = (dz < -thickness) ? 1.0 : 0.0;
            float w = sampleDepth.confidence;
            accum.value += occluder * w;
            accum.weight += w;
            accum.hit_count += occluder * w;
            accum.confidence += sampleDepth.confidence;
        }
    }

    accum.confidence = accum.weight > 0.0 ? saturate(accum.confidence / accum.weight) : 0.0;
    return accum;
}

float4 OCCULT_RM_PackBatch(OCCULT_RM_BatchAccum a)
{
    return float4(a.value, a.weight, a.hit_count, a.confidence);
}

float OCCULT_RM_UnpackNormalized(float4 a0, float4 a1, float4 a2, float4 a3)
{
    float valueSum = a0.r + a1.r + a2.r + a3.r;
    float weightSum = max(a0.g + a1.g + a2.g + a3.g, 0.000001);
    return saturate(valueSum / weightSum);
}

float OCCULT_RM_UnpackConfidence(float4 a0, float4 a1, float4 a2, float4 a3)
{
    float w = step(0.000001, a0.g) + step(0.000001, a1.g) + step(0.000001, a2.g) + step(0.000001, a3.g);
    float c = a0.a + a1.a + a2.a + a3.a;
    return w > 0.0 ? saturate(c / max(w, 1.0)) : 0.0;
}

#endif // OCCULT_API_RM_PASS_SAMPLING_FXH
