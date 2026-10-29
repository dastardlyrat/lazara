#ifndef OCCULT_API_RM_RAY_FXH
#define OCCULT_API_RM_RAY_FXH

#include "OCCULT_API_RM_Types.fxh"
#include "OCCULT_API_RM_Depth.fxh"
#include "OCCULT_API_RM_Sampling.fxh"
#include "OCCULT_API_SafeMath.fxh"

float OCCULT_RM_UVInside(float2 uv)
{
    float2 inside = step(float2(0.0, 0.0), uv) * step(uv, float2(1.0, 1.0));
    return inside.x * inside.y;
}

OCCULT_RM_Ray OCCULT_RM_MakeScreenRay(float2 uv0, float2 directionUv, float lengthUv, float z0, float zSlope, float thickness, float confidenceMin, int steps)
{
    OCCULT_RM_Ray r;
    int safeSteps = max(steps, 1);
    float2 dir = OCCULT_RM_SafeNormalize2(directionUv, float2(1.0, 0.0));
    r.uv0 = OCCULT_RM_ClampUV(uv0);
    r.step_uv = dir * OCCULT_SafeRcp((float)safeSteps, 0.0) * lengthUv;
    r.z0 = saturate(z0);
    r.step_z = zSlope * OCCULT_SafeRcp((float)safeSteps, 0.0);
    r.thickness = max(thickness, 0.0);
    r.confidence_min = saturate(confidenceMin);
    r.steps = safeSteps;
    return r;
}

OCCULT_RM_Hit OCCULT_RM_InitMiss(float2 uv0, float reason)
{
    OCCULT_RM_Hit h;
    h.hit = 0.0;
    h.miss = 1.0;
    h.uv = OCCULT_RM_ClampUV(uv0);
    h.ray_z = 0.0;
    h.scene_z = 0.0;
    h.delta = 0.0;
    h.step_index = 0.0;
    h.confidence = 0.0;
    h.reason = reason;
    return h;
}

OCCULT_RM_Hit OCCULT_RM_MarchDepth(OCCULT_RM_Ray ray)
{
    OCCULT_RM_Hit h = OCCULT_RM_InitMiss(ray.uv0, 1.0);

    [loop]
    for (int i = 1; i <= OCCULT_RM_DEFAULT_STEPS; ++i)
    {
        if (i > ray.steps)
        {
            break;
        }

        float fi = (float)i;
        float2 uv = ray.uv0 + ray.step_uv * fi;
        if (OCCULT_RM_UVInside(uv) <= 0.0)
        {
            h.reason = 2.0;
            break;
        }

        float rayZ = saturate(ray.z0 + ray.step_z * fi);
        OCCULT_RM_DepthSample ds = OCCULT_RM_GetDepth(uv);
        float delta = rayZ - ds.linear01;
        float valid = (ds.confidence >= ray.confidence_min) ? 1.0 : 0.0;
        float crossed = (abs(delta) <= ray.thickness) ? 1.0 : 0.0;
        float passed = (delta > ray.thickness) ? 1.0 : 0.0;

        h.uv = uv;
        h.ray_z = rayZ;
        h.scene_z = ds.linear01;
        h.delta = delta;
        h.step_index = fi;
        h.confidence = ds.confidence;

        if (valid * max(crossed, passed) > 0.0)
        {
            h.hit = 1.0;
            h.miss = 0.0;
            h.reason = 0.0;
            break;
        }

        if (valid <= 0.0)
        {
            h.reason = 3.0;
        }
    }

    return h;
}

float OCCULT_RM_ContactProbe(float2 uv, float2 directionUv, float lengthUv, float thickness, int steps)
{
    float result = 0.0;
    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uv);
    if (center.confidence > 0.0)
    {
        OCCULT_RM_Ray ray = OCCULT_RM_MakeScreenRay(
            uv + OCCULT_RM_SafeNormalize2(directionUv, float2(1.0, 0.0)) * OCCULT_RM_PixelSize() * 1.5,
            directionUv,
            lengthUv,
            center.linear01 + thickness,
            lengthUv,
            thickness,
            0.10,
            steps
        );
        OCCULT_RM_Hit hit = OCCULT_RM_MarchDepth(ray);
        result = saturate(hit.hit * hit.confidence);
    }
    return result;
}

#endif // OCCULT_API_RM_RAY_FXH
