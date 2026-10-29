#ifndef OCCULT_API_RM_PRIMARY_MARCH_FXH
#define OCCULT_API_RM_PRIMARY_MARCH_FXH

#include "OCCULT_API_RM_Bounds.fxh"
#include "OCCULT_API_RM_Debug.fxh"

#ifndef OCCULT_RM_SDF_MAX_STEPS
#define OCCULT_RM_SDF_MAX_STEPS 48
#endif

struct OCCULT_RM_SDFHit
{
    float hit;
    float miss;
    float t;
    float d;
    float step_index;
    float confidence;
    float reason;
    float3 p;
    float3 n;
};

OCCULT_RM_SDFHit OCCULT_RM_InitSDFMiss(OCCULT_RM_SDFRay ray, float reason)
{
    OCCULT_RM_SDFHit h;
    h.hit = 0.0;
    h.miss = 1.0;
    h.t = ray.tMin;
    h.d = 1.0e6;
    h.step_index = 0.0;
    h.confidence = ray.valid;
    h.reason = reason;
    h.p = ray.origin + ray.direction * ray.tMin;
    h.n = float3(0.0, 0.0, -1.0);
    return h;
}

float OCCULT_RM_SDFHitEps(float t, float epsAbs, float epsRel)
{
    return max(max(epsAbs, 0.000001), max(epsRel, 0.0) * max(t, 0.0));
}

OCCULT_RM_SDFHit OCCULT_RM_MarchSDFPrimary(OCCULT_RM_SDFRay ray, int sceneMode, int activeSteps, float epsAbs, float epsRel, float minStep)
{
    OCCULT_RM_SDFHit h = OCCULT_RM_InitSDFMiss(ray, 1.0);
    float t = ray.tMin;
    int safeSteps = max(activeSteps, 1);
    float safeMinStep = max(minStep, 0.00001);

    if (ray.valid <= 0.0)
    {
        h.reason = 4.0;
        h.confidence = 0.0;
        return h;
    }

    [loop]
    for (int i = 0; i < OCCULT_RM_SDF_MAX_STEPS; ++i)
    {
        if (i >= safeSteps)
        {
            break;
        }

        if (t > ray.tMax)
        {
            h.reason = 2.0;
            break;
        }

        float3 p = ray.origin + ray.direction * t;
        float d = OCCULT_RM_SDFSceneBasic(p, sceneMode);
        float eps = OCCULT_RM_SDFHitEps(t, epsAbs, epsRel);

        h.t = t;
        h.d = d;
        h.step_index = (float)(i + 1);
        h.p = p;
        h.confidence = ray.valid;

        if (d <= eps)
        {
            h.hit = 1.0;
            h.miss = 0.0;
            h.reason = 0.0;
            h.n = OCCULT_RM_SDFNormalBasic(p, sceneMode, max(epsAbs * 2.0, 0.0005));
            return h;
        }

        t += max(d, safeMinStep);
    }

    h.p = ray.origin + ray.direction * min(t, ray.tMax);
    h.n = OCCULT_RM_SDFNormalBasic(h.p, sceneMode, max(epsAbs * 2.0, 0.0005));
    return h;
}

float3 OCCULT_RM_EncodeSDFHit(OCCULT_RM_SDFHit h, int activeSteps)
{
    float stepHeat = saturate(h.step_index * OCCULT_SafeRcp(max((float)activeSteps, 1.0), 0.0));
    float3 missColor = lerp(float3(0.04, 0.08, 0.25), float3(1.0, 0.28, 0.04), saturate(h.reason * 0.20));
    float3 lit = saturate(OCCULT_RM_EncodeNormal(h.n) * 0.65 + OCCULT_DebugHeat(stepHeat) * 0.35);
    float3 outColor = lerp(missColor, lit, h.hit);
    outColor = lerp(float3(1.0, 0.0, 1.0), outColor, saturate(h.confidence));
    return saturate(outColor);
}

float3 OCCULT_RM_EncodeAABBClip(OCCULT_RM_AABBClip clip, OCCULT_RM_SDFRay ray)
{
    float span = saturate((clip.tMax - clip.tMin) * OCCULT_SafeRcp(max(ray.tMax - ray.tMin, 0.000001), 0.0));
    float nearHeat = saturate(clip.tMin * OCCULT_SafeRcp(max(ray.tMax, 0.000001), 0.0));
    float3 validColor = lerp(float3(0.0, 0.25, 1.0), float3(0.1, 1.0, 0.25), span);
    validColor = lerp(validColor, float3(1.0, 0.85, 0.1), nearHeat * 0.35);
    return lerp(float3(1.0, 0.0, 1.0), validColor, clip.valid);
}

#endif // OCCULT_API_RM_PRIMARY_MARCH_FXH
