#ifndef OCCULT_API_RM_SDF_FXH
#define OCCULT_API_RM_SDF_FXH

#include "OCCULT_API_SafeMath.fxh"

#ifndef OCCULT_RM_SDF_EPS_DEFAULT
#define OCCULT_RM_SDF_EPS_DEFAULT 0.001
#endif

float3 OCCULT_RM_SafeNormalize3(float3 v, float3 fallbackValue)
{
    float len2 = dot(v, v);
    return (len2 > 1.0e-8) ? (v * rsqrt(len2)) : fallbackValue;
}

float OCCULT_RM_SDFSphere(float3 p, float r)
{
    return length(p) - r;
}

float OCCULT_RM_SDFPlane(float3 p, float3 nUnit, float h)
{
    return dot(p, nUnit) + h;
}

float OCCULT_RM_SDFBox(float3 p, float3 b)
{
    float3 q = abs(p) - b;
    return length(max(q, float3(0.0, 0.0, 0.0))) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float OCCULT_RM_SDFRoundBox(float3 p, float3 b, float r)
{
    float3 q = abs(p) - b;
    return length(max(q, float3(0.0, 0.0, 0.0))) + min(max(q.x, max(q.y, q.z)), 0.0) - r;
}

float OCCULT_RM_SDFCapsule(float3 p, float3 a, float3 b, float r)
{
    float3 pa = p - a;
    float3 ba = b - a;
    float baLen2 = max(dot(ba, ba), 1.0e-8);
    float h = saturate(dot(pa, ba) * OCCULT_SafeRcp(baLen2, 0.0));
    return length(pa - ba * h) - r;
}

float OCCULT_RM_SDFTorus(float3 p, float2 t)
{
    float2 q = float2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}

float OCCULT_RM_SDFCappedCylinderY(float3 p, float h, float r)
{
    float2 q = abs(float2(length(p.xz), p.y)) - float2(r, h);
    return min(max(q.x, q.y), 0.0) + length(max(q, float2(0.0, 0.0)));
}

float OCCULT_RM_SDFUnion(float a, float b) { return min(a, b); }
float OCCULT_RM_SDFIntersect(float a, float b) { return max(a, b); }
float OCCULT_RM_SDFSubtract(float a, float b) { return max(a, -b); }

float OCCULT_RM_SDFSmoothUnion(float a, float b, float k)
{
    float safeK = max(k, 0.000001);
    float h = saturate(0.5 + 0.5 * (b - a) * OCCULT_SafeRcp(safeK, 0.0));
    return lerp(b, a, h) - safeK * h * (1.0 - h);
}

float OCCULT_RM_SDFShell(float d, float thickness)
{
    return abs(d) - max(thickness, 0.0);
}

float3 OCCULT_RM_SDFTranslate(float3 p, float3 t)
{
    return p - t;
}

float3 OCCULT_RM_SDFMirrorX(float3 p)
{
    return float3(abs(p.x), p.y, p.z);
}

float3 OCCULT_RM_SDFRepeatFloat(float3 p, float3 cell)
{
    float3 safeCell = max(abs(cell), float3(0.000001, 0.000001, 0.000001));
    float3 q = p + 0.5 * safeCell;
    return q - safeCell * floor(q / safeCell) - 0.5 * safeCell;
}

float OCCULT_RM_SDFSceneBasic(float3 p, int sceneMode)
{
    float d = OCCULT_RM_SDFSphere(p - float3(0.0, 0.0, 2.25), 0.55);

    if (sceneMode == 1)
    {
        d = OCCULT_RM_SDFRoundBox(p - float3(0.0, 0.0, 2.25), float3(0.45, 0.45, 0.45), 0.08);
    }
    else if (sceneMode == 2)
    {
        d = OCCULT_RM_SDFTorus(p - float3(0.0, 0.0, 2.25), float2(0.42, 0.13));
    }
    else if (sceneMode == 3)
    {
        d = OCCULT_RM_SDFCapsule(p, float3(-0.35, -0.20, 2.05), float3(0.35, 0.25, 2.45), 0.18);
    }
    else if (sceneMode == 4)
    {
        float sphereD = OCCULT_RM_SDFSphere(p - float3(-0.22, 0.0, 2.20), 0.42);
        float boxD = OCCULT_RM_SDFRoundBox(p - float3(0.25, 0.0, 2.30), float3(0.32, 0.32, 0.32), 0.06);
        d = OCCULT_RM_SDFSmoothUnion(sphereD, boxD, 0.22);
    }

    return d;
}

float3 OCCULT_RM_SDFNormalBasic(float3 p, int sceneMode, float eps)
{
    float e = max(eps, 0.0001);
    float dx = OCCULT_RM_SDFSceneBasic(p + float3(e, 0.0, 0.0), sceneMode) - OCCULT_RM_SDFSceneBasic(p - float3(e, 0.0, 0.0), sceneMode);
    float dy = OCCULT_RM_SDFSceneBasic(p + float3(0.0, e, 0.0), sceneMode) - OCCULT_RM_SDFSceneBasic(p - float3(0.0, e, 0.0), sceneMode);
    float dz = OCCULT_RM_SDFSceneBasic(p + float3(0.0, 0.0, e), sceneMode) - OCCULT_RM_SDFSceneBasic(p - float3(0.0, 0.0, e), sceneMode);
    return OCCULT_RM_SafeNormalize3(float3(dx, dy, dz), float3(0.0, 0.0, -1.0));
}

#endif // OCCULT_API_RM_SDF_FXH
