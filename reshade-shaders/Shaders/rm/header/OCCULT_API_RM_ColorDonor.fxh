#ifndef OCCULT_API_RM_COLOR_DONOR_FXH
#define OCCULT_API_RM_COLOR_DONOR_FXH

#include "OCCULT_API_SafeMath.fxh"
#include "OCCULT_API_RM_Debug.fxh"

float OCCULT_RM_ReadinessWeight(float reuseReady, float threshold)
{
    float safeThreshold = max(threshold, 0.000001);
    float hardReady = saturate((reuseReady - threshold) * OCCULT_SafeRcp(max(1.0 - threshold, 0.000001), 0.0));
    float softReady = saturate(reuseReady * OCCULT_SafeRcp(safeThreshold, 0.0)) * 0.5;
    return saturate(max(hardReady, softReady));
}

float OCCULT_RM_NormalCompatibility(float3 centerNormal, float3 tapNormal, float dotFloor)
{
    float safeFloor = min(max(dotFloor, 0.0), 0.999);
    float normalDot = saturate(dot(centerNormal, tapNormal));
    return saturate((normalDot - safeFloor) * OCCULT_SafeRcp(max(1.0 - safeFloor, 0.000001), 0.0));
}

float OCCULT_RM_SoftNormalPreference(float normalGate)
{
    return lerp(0.30, 1.0, saturate(normalGate));
}

float OCCULT_RM_SoftStructure(float tapReady, float normalGate, float depthAgreement)
{
    float structureMean = saturate((tapReady + normalGate + depthAgreement) * (1.0 / 3.0));
    float structureFloor = max(max(tapReady, normalGate), depthAgreement);
    return saturate(max(structureMean, structureFloor * 0.75));
}

float OCCULT_RM_DonorNeighborhoodWeight(float centerReady, float tapReady, float normalGate, float depthAgreement)
{
    float softNormal = OCCULT_RM_SoftNormalPreference(normalGate);
    float structure = OCCULT_RM_SoftStructure(tapReady, softNormal, depthAgreement);
    return saturate(centerReady * structure);
}

float OCCULT_RM_Chroma(float3 color)
{
    return max(abs(color.r - color.g), max(abs(color.g - color.b), abs(color.b - color.r)));
}

float3 OCCULT_RM_ChromaVector(float3 color)
{
    float luma = OCCULT_RM_Luma(color);
    return color - luma.xxx;
}

float OCCULT_RM_ChromaKeep(float chroma, float chromaFloor)
{
    float safeFloor = saturate(chromaFloor);
    return saturate((chroma - safeFloor) * OCCULT_SafeRcp(max(1.0 - safeFloor, 0.000001), 0.0));
}

float OCCULT_RM_ChromaKeepScaled(float chroma, float chromaFloor, float chromaGain)
{
    return saturate(OCCULT_RM_ChromaKeep(chroma, chromaFloor) * max(chromaGain * 0.35, 0.0));
}

float OCCULT_RM_HueKeep(float chromaKeep, float hueFloor)
{
    float safeFloor = saturate(hueFloor);
    float softKeep = saturate(chromaKeep * 0.55 + 0.20);
    return saturate(max(chromaKeep, lerp(softKeep, safeFloor, safeFloor)));
}

float OCCULT_RM_DonorScore(float tapChroma, float donorDelta, float basisWeight, float structure, float chromaKeep, float centerReady)
{
    float chromaBias = lerp(0.30, 1.0, saturate(chromaKeep));
    float readinessBias = saturate(centerReady * 0.75 + 0.25);
    return max((tapChroma * 2.0 + donorDelta) * basisWeight * structure * chromaBias * readinessBias, 0.0);
}

float OCCULT_RM_DonorMask(float structure, float maskBoost)
{
    return saturate(structure * max(maskBoost, 0.0));
}

float OCCULT_RM_DonorHeat(float donorScore)
{
    return saturate(donorScore * 1.5);
}

float OCCULT_RM_DonorInfluence(float weight, float donorMask, float applyStrength)
{
    float safeWeight = saturate(weight);
    float safeMask = saturate(donorMask);
    float safeStrength = max(applyStrength, 0.0);
    float weightDriven = safeWeight * safeMask;
    float maskFloor = safeMask * (0.18 + safeStrength * 0.10);
    float blended = max(weightDriven, maskFloor);
    return saturate(blended * (0.35 + safeStrength * 0.65));
}

float3 OCCULT_RM_PreserveDonorChroma(float3 donorColor, float donorInfluence, float donorChroma, float chromaFloor, float hueFloor, float applyStrength)
{
    float3 safeColor = saturate(donorColor);
    float donorLuma = OCCULT_RM_Luma(safeColor);
    float3 donorChromaVec = safeColor - donorLuma.xxx;
    float chromaKeep = OCCULT_RM_ChromaKeep(donorChroma, chromaFloor);
    float chromaFloorWeight = max(donorInfluence * 0.35, chromaKeep * (0.30 + saturate(hueFloor) * 0.35));
    float chromaAmp = (0.55 + saturate(hueFloor) * 0.75) * (1.0 + max(applyStrength, 0.0) * 1.85);
    return donorChromaVec * chromaAmp * max(donorInfluence, chromaFloorWeight);
}

#endif // OCCULT_API_RM_COLOR_DONOR_FXH
