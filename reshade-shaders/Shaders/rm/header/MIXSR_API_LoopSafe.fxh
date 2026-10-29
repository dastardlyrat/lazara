#ifndef MIXSR_API_LOOP_SAFE_FXH
#define MIXSR_API_LOOP_SAFE_FXH 1

// Shared loop-safety helpers for miXSR / ReShade FX.
// Purpose: keep compiler-hostile integer modulo/division and sign-unsafe power
// out of hot sampling / ray-march loops where practical.

float MIXSR_FloatModNoWarn(float a, float b)
{
    float bb = max(abs(b), 1.0e-6);
    return a - bb * floor(a / bb);
}

float2 MIXSR_Float2ModNoWarn(float2 a, float2 b)
{
    float2 bb = max(abs(b), float2(1.0e-6, 1.0e-6));
    return a - bb * floor(a / bb);
}

float3 MIXSR_Float3ModNoWarn(float3 a, float3 b)
{
    float3 bb = max(abs(b), float3(1.0e-6, 1.0e-6, 1.0e-6));
    return a - bb * floor(a / bb);
}

int MIXSR_IntModNoWarn(int a, int b)
{
    float aa = (float)max(0, a);
    float bb = max(1.0, (float)max(1, b));
    return (int)(aa - bb * floor(aa / bb));
}

uint MIXSR_UIntModNoWarn(uint a, uint b)
{
    float aa = (float)a;
    float bb = max(1.0, (float)max(1u, b));
    return (uint)(aa - bb * floor(aa / bb));
}

float MIXSR_SafePowNonNegative(float baseValue, float exponentValue)
{
    return pow(max(baseValue, 0.0), exponentValue);
}

float3 MIXSR_RM_LoopMissColor(float2 uv)
{
    float2 grid = abs(frac(uv * 24.0) - 0.5);
    float line = 1.0 - step(0.035, min(grid.x, grid.y));
    return lerp(float3(0.015, 0.015, 0.020), float3(0.25, 0.08, 0.05), line);
}

#endif // MIXSR_API_LOOP_SAFE_FXH
