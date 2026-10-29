#ifndef OCCULT_API_RM_BOUNDS_FXH
#define OCCULT_API_RM_BOUNDS_FXH

#include "OCCULT_API_RM_IO.fxh"
#include "OCCULT_API_RM_Depth.fxh"
#include "OCCULT_API_RM_SDF.fxh"

struct OCCULT_RM_SDFRay
{
    float3 origin;
    float3 direction;
    float tMin;
    float tMax;
    float valid;
};

struct OCCULT_RM_AABBClip
{
    float tMin;
    float tMax;
    float valid;
};

float OCCULT_RM_SignNonZero(float v)
{
    return (v < 0.0) ? -1.0 : 1.0;
}

float3 OCCULT_RM_InvDirectionSafe(float3 d)
{
    return float3(
        OCCULT_RM_SignNonZero(d.x) * OCCULT_SafeRcp(max(abs(d.x), 0.000001), 0.0),
        OCCULT_RM_SignNonZero(d.y) * OCCULT_SafeRcp(max(abs(d.y), 0.000001), 0.0),
        OCCULT_RM_SignNonZero(d.z) * OCCULT_SafeRcp(max(abs(d.z), 0.000001), 0.0)
    );
}

OCCULT_RM_SDFRay OCCULT_RM_MakeSDFCameraRay(float2 uv, float fovScale, float tMin, float tMax)
{
    OCCULT_RM_SDFRay r;
    float2 ndc = uv * 2.0 - 1.0;
    float aspect = max((float)BUFFER_WIDTH * (float)BUFFER_RCP_HEIGHT, 0.000001);
    float2 film = float2(ndc.x * aspect, -ndc.y) * max(fovScale, 0.000001);
    r.origin = float3(0.0, 0.0, 0.0);
    r.direction = OCCULT_RM_SafeNormalize3(float3(film, 1.0), float3(0.0, 0.0, 1.0));
    r.tMin = max(tMin, 0.0);
    r.tMax = max(tMax, r.tMin + 0.0001);
    r.valid = 1.0;
    return r;
}

OCCULT_RM_AABBClip OCCULT_RM_ClipRayAABB(OCCULT_RM_SDFRay ray, float3 bMin, float3 bMax)
{
    OCCULT_RM_AABBClip c;
    c.tMin = ray.tMin;
    c.tMax = ray.tMax;
    c.valid = 0.0;

    float3 invD = OCCULT_RM_InvDirectionSafe(ray.direction);
    float3 t0 = (bMin - ray.origin) * invD;
    float3 t1 = (bMax - ray.origin) * invD;
    float3 ta = min(t0, t1);
    float3 tb = max(t0, t1);

    float nearT = max(max(ta.x, ta.y), ta.z);
    float farT = min(min(tb.x, tb.y), tb.z);

    c.tMin = max(ray.tMin, nearT);
    c.tMax = min(ray.tMax, farT);
    c.valid = (c.tMax >= max(c.tMin, 0.0)) ? 1.0 : 0.0;
    return c;
}

float OCCULT_RM_DepthClipT(float2 uv, float nearT, float farT)
{
    OCCULT_RM_DepthSample d = OCCULT_RM_GetDepth(uv);
    float sceneT = lerp(nearT, farT, saturate(d.linear01));
    return lerp(farT, sceneT, d.confidence);
}

OCCULT_RM_SDFRay OCCULT_RM_ApplyAABBClip(OCCULT_RM_SDFRay ray, OCCULT_RM_AABBClip clip)
{
    OCCULT_RM_SDFRay r = ray;
    r.tMin = clip.tMin;
    r.tMax = clip.tMax;
    r.valid = ray.valid * clip.valid;
    return r;
}

OCCULT_RM_SDFRay OCCULT_RM_ApplyDepthClip(float2 uv, OCCULT_RM_SDFRay ray, float nearT, float farT)
{
    OCCULT_RM_SDFRay r = ray;
    float depthT = OCCULT_RM_DepthClipT(uv, nearT, farT);
    r.tMax = min(r.tMax, depthT);
    r.valid = r.valid * ((r.tMax > r.tMin) ? 1.0 : 0.0);
    return r;
}

#endif // OCCULT_API_RM_BOUNDS_FXH
