#ifndef OCCULT_API_RM_SECONDARY_FXH
#define OCCULT_API_RM_SECONDARY_FXH

#include "OCCULT_API_RM_PrimaryMarch.fxh"
#include "OCCULT_API_RM_TraceTypes.fxh"

#ifndef OCCULT_RM_SDF_SHADOW_STEPS
#define OCCULT_RM_SDF_SHADOW_STEPS 8
#endif

#ifndef OCCULT_RM_SDF_AO_STEPS
#define OCCULT_RM_SDF_AO_STEPS 4
#endif

struct OCCULT_RM_SDFSecondaryResult
{
    float visibility;
    float hit;
    float travel01;
    float minDistance;
    float travel;
    float step_count;
    float confidence;
    float3 p;
    float3 n;
    uint reason;
};

OCCULT_RM_SDFSecondaryResult OCCULT_RM_InitSecondaryResult()
{
    OCCULT_RM_SDFSecondaryResult r;
    r.visibility = 1.0;
    r.hit = 0.0;
    r.travel01 = 0.0;
    r.minDistance = 1.0e6;
    r.travel = 0.0;
    r.step_count = 0.0;
    r.confidence = 1.0;
    r.p = float3(0.0, 0.0, 0.0);
    r.n = float3(0.0, 0.0, -1.0);
    r.reason = OCCULT_RM_TRACE_MISS_MAX_STEPS;
    return r;
}

void OCCULT_RM_BuildHemisphereBasis(float3 n, out float3 t, out float3 b)
{
    float3 safeN = OCCULT_RM_SafeNormalize3(n, float3(0.0, 0.0, -1.0));
    float3 axis = (abs(safeN.z) < 0.90) ? float3(0.0, 0.0, 1.0) : float3(1.0, 0.0, 0.0);
    t = OCCULT_RM_SafeNormalize3(cross(axis, safeN), float3(1.0, 0.0, 0.0));
    b = OCCULT_RM_SafeNormalize3(cross(safeN, t), float3(0.0, 1.0, 0.0));
}

float3 OCCULT_RM_HemisphereDirection4(float3 n, int index)
{
    float3 safeN = OCCULT_RM_SafeNormalize3(n, float3(0.0, 0.0, -1.0));
    float3 t;
    float3 b;
    OCCULT_RM_BuildHemisphereBasis(safeN, t, b);

    float sx = (index == 0 || index == 2) ? 1.0 : -1.0;
    float sy = (index == 0 || index == 1) ? 1.0 : -1.0;
    float3 dir = safeN * 0.72 + (t * sx + b * sy) * 0.35;
    return OCCULT_RM_SafeNormalize3(dir, safeN);
}

OCCULT_RM_SDFSecondaryResult OCCULT_RM_SDFSecondaryTraceSteps(
    float3 origin,
    float3 dir,
    int sceneMode,
    float tMin,
    float tMax,
    float eps,
    float minStep,
    float softness,
    int activeSteps)
{
    OCCULT_RM_SDFSecondaryResult r = OCCULT_RM_InitSecondaryResult();
    float safeEps = max(eps, 0.0002);
    float safeMinStep = max(minStep, 0.0001);
    float safeTMin = max(tMin, safeMinStep);
    float safeTMax = max(tMax, safeTMin + safeMinStep);
    float safeSoftness = max(softness, 0.0);
    int safeSteps = clamp(activeSteps, 1, OCCULT_RM_SDF_SHADOW_STEPS);
    float3 safeDir = OCCULT_RM_SafeNormalize3(dir, float3(0.0, 0.0, 1.0));
    float t = safeTMin;

    [unroll]
    for (int i = 0; i < OCCULT_RM_SDF_SHADOW_STEPS; ++i)
    {
        if (i < safeSteps && t <= safeTMax && r.hit <= 0.0)
        {
            float3 p = origin + safeDir * t;
            float d = OCCULT_RM_SDFSceneBasic(p, sceneMode);
            float hitNow = (d <= safeEps) ? 1.0 : 0.0;
            float softCandidate = saturate(safeSoftness * max(d, 0.0) * OCCULT_SafeRcp(max(t, safeMinStep), 1.0));

            r.step_count = (float)(i + 1);
            r.minDistance = min(r.minDistance, abs(d));
            r.visibility = min(r.visibility, softCandidate);

            if (hitNow > 0.0)
            {
                r.hit = 1.0;
                r.travel = t;
                r.p = p;
            }
            else
            {
                t += max(d, safeMinStep);
            }
        }
    }

    if (r.hit > 0.0)
    {
        r.reason = OCCULT_RM_TRACE_MISS_NONE;
        r.visibility = 0.0;
        r.n = OCCULT_RM_SDFNormalBasic(r.p, sceneMode, max(safeEps * 2.0, 0.0005));
    }
    else
    {
        r.travel = min(t, safeTMax);
        r.p = origin + safeDir * r.travel;
        r.reason = (t > safeTMax) ? OCCULT_RM_TRACE_MISS_MAX_TRAVEL : OCCULT_RM_TRACE_MISS_MAX_STEPS;
        r.visibility = saturate(r.visibility);
    }

    r.travel01 = saturate(r.travel * OCCULT_SafeRcp(safeTMax, 0.0));
    return r;
}

OCCULT_RM_SDFSecondaryResult OCCULT_RM_SDFSecondaryTrace(float3 origin, float3 dir, int sceneMode, float tMin, float tMax, float eps, float minStep, float softness)
{
    OCCULT_RM_SDFSecondaryResult r = OCCULT_RM_InitSecondaryResult();
    float safeEps = max(eps, 0.0002);
    float safeMinStep = max(minStep, 0.0001);
    float safeTMin = max(tMin, safeMinStep);
    float safeTMax = max(tMax, safeTMin + safeMinStep);
    float safeSoftness = max(softness, 0.0);
    float3 safeDir = OCCULT_RM_SafeNormalize3(dir, float3(0.0, 0.0, 1.0));
    float t = safeTMin;

    // Compatibility path: preserve the original fixed-eight implementation.
    [unroll]
    for (int i = 0; i < OCCULT_RM_SDF_SHADOW_STEPS; ++i)
    {
        float active = (t <= safeTMax && r.hit <= 0.0) ? 1.0 : 0.0;
        float3 p = origin + safeDir * t;
        float d = OCCULT_RM_SDFSceneBasic(p, sceneMode);
        float hitNow = (d <= safeEps && active > 0.0) ? 1.0 : 0.0;
        float softCandidate = saturate(safeSoftness * max(d, 0.0) * OCCULT_SafeRcp(max(t, safeMinStep), 1.0));

        r.minDistance = min(r.minDistance, abs(d));
        r.hit = max(r.hit, hitNow);
        r.visibility = min(r.visibility, lerp(1.0, softCandidate, active));
        t += max(d, safeMinStep) * active + (safeTMax + safeMinStep) * (1.0 - active);
    }

    r.visibility = saturate(lerp(r.visibility, 0.0, r.hit));
    r.travel01 = saturate(t * OCCULT_SafeRcp(safeTMax, 0.0));
    r.reason = (r.hit > 0.0) ? OCCULT_RM_TRACE_MISS_NONE : OCCULT_RM_TRACE_MISS_MAX_TRAVEL;
    return r;
}

float OCCULT_RM_SDFSecondaryVisibility(float3 origin, float3 dir, int sceneMode, float tMin, float tMax, float eps, float minStep)
{
    OCCULT_RM_SDFSecondaryResult r = OCCULT_RM_SDFSecondaryTrace(origin, dir, sceneMode, tMin, tMax, eps, minStep, 12.0);
    return r.visibility;
}

float OCCULT_RM_SDFSoftShadow8(float3 p, float3 n, float3 lightDir, int sceneMode, float normalBias, float tMax, float eps, float minStep)
{
    float3 safeN = OCCULT_RM_SafeNormalize3(n, float3(0.0, 0.0, -1.0));
    float3 safeL = OCCULT_RM_SafeNormalize3(lightDir, float3(0.35, 0.55, -0.76));
    float bias = max(normalBias, 0.0005);
    float ndl = saturate(dot(safeN, safeL));
    OCCULT_RM_SDFSecondaryResult trace = OCCULT_RM_SDFSecondaryTrace(p + safeN * bias, safeL, sceneMode, max(minStep, 0.0005), tMax, eps, minStep, 10.0);
    float lit = lerp(0.18, 1.0, trace.visibility);
    return saturate(lit * ndl + 0.08 * (1.0 - ndl));
}

float OCCULT_RM_SDFAOProbe(float3 p, float3 n, float3 dir, int sceneMode, float normalBias, float tMax, float eps, float minStep)
{
    float3 safeN = OCCULT_RM_SafeNormalize3(n, float3(0.0, 0.0, -1.0));
    float3 safeD = OCCULT_RM_SafeNormalize3(dir, safeN);
    float hemi = saturate(dot(safeD, safeN));
    float bias = max(normalBias, 0.0005);
    OCCULT_RM_SDFSecondaryResult trace = OCCULT_RM_SDFSecondaryTrace(p + safeN * bias, safeD, sceneMode, max(minStep, 0.0005), tMax, eps, minStep, 8.0);
    return saturate(lerp(1.0, trace.visibility, hemi));
}

float OCCULT_RM_SDFAO4(float3 p, float3 n, int sceneMode, float normalBias, float tMax, float eps, float minStep)
{
    float3 safeN = OCCULT_RM_SafeNormalize3(n, float3(0.0, 0.0, -1.0));
    float a0 = OCCULT_RM_SDFAOProbe(p, safeN, OCCULT_RM_HemisphereDirection4(safeN, 0), sceneMode, normalBias, tMax, eps, minStep);
    float a1 = OCCULT_RM_SDFAOProbe(p, safeN, OCCULT_RM_HemisphereDirection4(safeN, 1), sceneMode, normalBias, tMax, eps, minStep);
    float a2 = OCCULT_RM_SDFAOProbe(p, safeN, OCCULT_RM_HemisphereDirection4(safeN, 2), sceneMode, normalBias, tMax, eps, minStep);
    float a3 = OCCULT_RM_SDFAOProbe(p, safeN, OCCULT_RM_HemisphereDirection4(safeN, 3), sceneMode, normalBias, tMax, eps, minStep);
    return saturate((a0 + a1 + a2 + a3) * 0.25);
}

float3 OCCULT_RM_EncodeSecondaryLight(float3 sourceColor, OCCULT_RM_SDFHit hit, float shadow, float ao, float sourceBlend, float debugBlend)
{
    float3 nColor = OCCULT_RM_EncodeNormal(hit.n);
    float shade = saturate(lerp(0.30, 1.10, shadow) * lerp(0.45, 1.05, ao));
    float3 lit = saturate(nColor * shade);
    float3 debug = float3(shadow, ao, hit.hit);
    float3 outColor = lerp(lit, debug, saturate(debugBlend));
    outColor = lerp(outColor, sourceColor, saturate(sourceBlend));
    outColor = lerp(sourceColor, outColor, hit.hit);
    outColor = lerp(float3(1.0, 0.0, 1.0), outColor, saturate(hit.confidence));
    return saturate(outColor);
}

#endif // OCCULT_API_RM_SECONDARY_FXH
