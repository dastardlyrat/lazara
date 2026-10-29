#ifndef OCCULT_API_RM_SAMPLING_FXH
#define OCCULT_API_RM_SAMPLING_FXH

#include "OCCULT_API_SafeMath.fxh"
#include "OCCULT_API_PassSampling.fxh"

#define OCCULT_RM_TAU 6.28318530718
#define OCCULT_RM_GOLDEN_ANGLE 2.39996322973

float2 OCCULT_RM_SafeNormalize2(float2 v, float2 fallbackValue)
{
    float len2 = dot(v, v);
    return (len2 > 1.0e-8) ? (v * rsqrt(len2)) : fallbackValue;
}

float2 OCCULT_RM_GoldenDirection(int tapIndex, int tapCount, float seed)
{
    float n = max((float)tapCount, 1.0);
    float f = (float)tapIndex + seed;
    float angleValue = OCCULT_RM_GOLDEN_ANGLE * f;
    float radiusValue = sqrt((f + 0.5) / n);
    return float2(cos(angleValue), sin(angleValue)) * radiusValue;
}

float2 OCCULT_RM_RingDirection(int tapIndex, int tapCount, float seed)
{
    float n = max((float)tapCount, 1.0);
    float angleValue = OCCULT_RM_TAU * ((float)tapIndex + seed) / n;
    return float2(cos(angleValue), sin(angleValue));
}

int OCCULT_RM_BatchStart(int batchIndex)
{
    return OCCULT_BatchStartIndex(batchIndex);
}

int OCCULT_RM_BatchEndExclusive(int batchIndex)
{
    return OCCULT_RM_BatchStart(batchIndex) + OCCULT_PASS_BATCH_DIRECTIONS;
}

#endif // OCCULT_API_RM_SAMPLING_FXH
