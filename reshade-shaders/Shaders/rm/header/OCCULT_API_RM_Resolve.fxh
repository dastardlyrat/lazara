#ifndef OCCULT_API_RM_RESOLVE_FXH
#define OCCULT_API_RM_RESOLVE_FXH

#include "OCCULT_API_RM_Depth.fxh"
#include "OCCULT_API_SafeMath.fxh"

#ifndef OCCULT_RM_RESOLVE_MIN_WEIGHT
#define OCCULT_RM_RESOLVE_MIN_WEIGHT 0.000001
#endif

#ifndef OCCULT_RM_TAG_AGREEMENT_APPLIED
#define OCCULT_RM_TAG_AGREEMENT_APPLIED 1u
#endif
#ifndef OCCULT_RM_TAG_COVERAGE_APPLIED
#define OCCULT_RM_TAG_COVERAGE_APPLIED 2u
#endif
#ifndef OCCULT_RM_TAG_EDGE_PINCH_APPLIED
#define OCCULT_RM_TAG_EDGE_PINCH_APPLIED 4u
#endif
#ifndef OCCULT_RM_TAG_REUSE_GATE_APPLIED
#define OCCULT_RM_TAG_REUSE_GATE_APPLIED 8u
#endif
#ifndef OCCULT_RM_TAG_AO_APPLIED
#define OCCULT_RM_TAG_AO_APPLIED 16u
#endif
#ifndef OCCULT_RM_TAG_SSR_APPLIED
#define OCCULT_RM_TAG_SSR_APPLIED 32u
#endif
#ifndef OCCULT_RM_TAG_BLOOM_APPLIED
#define OCCULT_RM_TAG_BLOOM_APPLIED 64u
#endif
#ifndef OCCULT_RM_TAG_SSGI_APPLIED
#define OCCULT_RM_TAG_SSGI_APPLIED 128u
#endif

#ifndef OCCULT_RM_TEMPORAL_READINESS_DEFINED
#define OCCULT_RM_TEMPORAL_READINESS_DEFINED
struct OCCULT_RM_TemporalReadiness
{
    float depth_raw;
    float depth_linear01;
    float depth_confidence;
    float depth_edge;
    float depth_sky;
    float depth_empty_like;
    float3 normal;
    float depth_agreement;
    float normal_agreement;
    float luma_agreement;
    float edge_risk;
    float stability;
    float reuse_ready;
    uint applied_tags;
};

uint OCCULT_RM_ApplyTag(uint tags, uint bit)
{
    return tags | bit;
}

float OCCULT_RM_HasTag(uint tags, uint bit)
{
    return ((tags & bit) != 0u) ? 1.0 : 0.0;
}

float3 OCCULT_RM_AppliedTagDebugRGB(uint tags)
{
    return float3(
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_AGREEMENT_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_COVERAGE_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_EDGE_PINCH_APPLIED));
}

float4 OCCULT_RM_AppliedConsumerTagDebugRGBA(uint tags)
{
    return float4(
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_AO_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_SSR_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_BLOOM_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_SSGI_APPLIED));
}

float3 OCCULT_RM_AppliedConsumerSummaryRGB(uint tags)
{
    float ao = OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_AO_APPLIED);
    float ssr = OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_SSR_APPLIED);
    float energy = max(
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_BLOOM_APPLIED),
        OCCULT_RM_HasTag(tags, OCCULT_RM_TAG_SSGI_APPLIED));
    return float3(ao, ssr, energy);
}

uint OCCULT_RM_ApplyConsumerTag(uint tags, uint bit, float applied)
{
    return OCCULT_RM_ApplyTag(tags, bit * (applied > 0.0001 ? 1u : 0u));
}

#ifndef OCCULT_RM_REJECT_NONE
#define OCCULT_RM_REJECT_NONE 0u
#endif
#ifndef OCCULT_RM_REJECT_CONFIDENCE
#define OCCULT_RM_REJECT_CONFIDENCE 1u
#endif
#ifndef OCCULT_RM_REJECT_DEPTH
#define OCCULT_RM_REJECT_DEPTH 2u
#endif
#ifndef OCCULT_RM_REJECT_NORMAL
#define OCCULT_RM_REJECT_NORMAL 3u
#endif
#ifndef OCCULT_RM_REJECT_LUMA
#define OCCULT_RM_REJECT_LUMA 4u
#endif
#ifndef OCCULT_RM_REJECT_EDGE
#define OCCULT_RM_REJECT_EDGE 5u
#endif

float OCCULT_RM_RejectReadyMask(float reuseReady, float threshold)
{
    return saturate((reuseReady - threshold) * OCCULT_SafeRcp(max(1.0 - threshold, 0.000001), 0.0));
}

uint OCCULT_RM_ClassifyReuseRejectCode(OCCULT_RM_TemporalReadiness t, float readyThreshold)
{
    float readyMask = OCCULT_RM_RejectReadyMask(t.reuse_ready, readyThreshold);
    float confFail = saturate(1.0 - t.depth_confidence);
    float depthFail = saturate(1.0 - t.depth_agreement);
    float normalFail = saturate(1.0 - t.normal_agreement);
    float lumaFail = saturate(1.0 - t.luma_agreement);
    float edgeFail = saturate(t.edge_risk);
    float failMax = max(confFail, max(depthFail, max(normalFail, max(lumaFail, edgeFail))));

    if (readyMask > 0.0001)
        return OCCULT_RM_REJECT_NONE;
    if (confFail >= failMax)
        return OCCULT_RM_REJECT_CONFIDENCE;
    if (depthFail >= failMax)
        return OCCULT_RM_REJECT_DEPTH;
    if (normalFail >= failMax)
        return OCCULT_RM_REJECT_NORMAL;
    if (lumaFail >= failMax)
        return OCCULT_RM_REJECT_LUMA;
    return OCCULT_RM_REJECT_EDGE;
}

float OCCULT_RM_RejectCodeScalar(uint rejectCode)
{
    return saturate((float)rejectCode * (1.0 / 7.0));
}

float3 OCCULT_RM_RejectCodeColor(uint rejectCode)
{
    if (rejectCode == OCCULT_RM_REJECT_CONFIDENCE) return float3(1.0, 0.1, 0.8);
    if (rejectCode == OCCULT_RM_REJECT_DEPTH)      return float3(0.1, 0.9, 1.0);
    if (rejectCode == OCCULT_RM_REJECT_NORMAL)     return float3(0.2, 1.0, 0.3);
    if (rejectCode == OCCULT_RM_REJECT_LUMA)       return float3(1.0, 0.9, 0.2);
    if (rejectCode == OCCULT_RM_REJECT_EDGE)       return float3(1.0, 0.4, 0.1);
    return OCCULT_RM_ColorHit();
}

float4 OCCULT_RM_DebugRejectCodeBitStripes(uint rejectCode, float2 uv)
{
    float stripe = frac(uv.x * 24.0);
    uint bitMask = (stripe < 0.333333) ? 1u : ((stripe < 0.666667) ? 2u : 4u);
    float bitValue = ((rejectCode & bitMask) != 0u) ? 1.0 : 0.0;
    float3 bitColor =
        (bitMask == 1u) ? float3(1.0, 0.2, 0.2) :
        ((bitMask == 2u) ? float3(0.2, 1.0, 0.3) : float3(0.2, 0.55, 1.0));
    float scanline = lerp(0.70, 1.00, step(0.5, frac(uv.y * 160.0)));
    float3 offColor = bitColor * 0.10;
    float3 onColor = bitColor * scanline;
    return float4(lerp(offColor, onColor, bitValue), 1.0);
}

float OCCULT_RM_TemporalDepthAgreement1(OCCULT_RM_DepthSample center, OCCULT_RM_DepthSample tap, float protect)
{
    float safeProtect = max(protect, 0.000001);
    float agree = saturate(1.0 - abs(center.linear01 - tap.linear01) * OCCULT_SafeRcp(safeProtect, 0.0));
    return agree * step(0.0001, tap.confidence);
}

float OCCULT_RM_TemporalNormalAgreement1(float3 centerNormal, float3 tapNormal, OCCULT_RM_DepthSample tap)
{
    float agree = saturate(dot(centerNormal, tapNormal));
    return agree * step(0.0001, tap.confidence);
}

float OCCULT_RM_TemporalLumaAgreement1(float centerLuma, float tapLuma, OCCULT_RM_DepthSample tap, float protect)
{
    float safeProtect = max(protect, 0.000001);
    float agree = saturate(1.0 - abs(centerLuma - tapLuma) * OCCULT_SafeRcp(safeProtect, 0.0));
    return agree * step(0.0001, tap.confidence);
}

OCCULT_RM_TemporalReadiness OCCULT_RM_EvaluateTemporalReadiness(float2 uv, float depthProtect, float lumaProtect)
{
    OCCULT_RM_TemporalReadiness o;
    float2 uvSafe = OCCULT_RM_ClampUV(uv);
    float2 px = OCCULT_RM_PixelSize();

    float2 uvL = OCCULT_RM_ClampUV(uvSafe - float2(px.x, 0.0));
    float2 uvR = OCCULT_RM_ClampUV(uvSafe + float2(px.x, 0.0));
    float2 uvU = OCCULT_RM_ClampUV(uvSafe - float2(0.0, px.y));
    float2 uvD = OCCULT_RM_ClampUV(uvSafe + float2(0.0, px.y));

    OCCULT_RM_DepthSample center = OCCULT_RM_GetDepth(uvSafe);
    OCCULT_RM_DepthSample dL = OCCULT_RM_GetDepth(uvL);
    OCCULT_RM_DepthSample dR = OCCULT_RM_GetDepth(uvR);
    OCCULT_RM_DepthSample dU = OCCULT_RM_GetDepth(uvU);
    OCCULT_RM_DepthSample dD = OCCULT_RM_GetDepth(uvD);

    o.depth_raw = center.raw;
    o.depth_linear01 = center.linear01;
    o.depth_confidence = center.confidence;
    o.depth_edge = center.edge;
    o.depth_sky = center.sky;
    o.depth_empty_like = center.empty_like;

    o.normal = OCCULT_RM_NormalFromDepth(uvSafe);
    float3 nL = OCCULT_RM_NormalFromDepth(uvL);
    float3 nR = OCCULT_RM_NormalFromDepth(uvR);
    float3 nU = OCCULT_RM_NormalFromDepth(uvU);
    float3 nD = OCCULT_RM_NormalFromDepth(uvD);

    float l0 = OCCULT_RM_Luma(OCCULT_RM_LoadColor(uvSafe).rgb);
    float lL = OCCULT_RM_Luma(OCCULT_RM_LoadColor(uvL).rgb);
    float lR = OCCULT_RM_Luma(OCCULT_RM_LoadColor(uvR).rgb);
    float lU = OCCULT_RM_Luma(OCCULT_RM_LoadColor(uvU).rgb);
    float lD = OCCULT_RM_Luma(OCCULT_RM_LoadColor(uvD).rgb);

    float depthSum =
        OCCULT_RM_TemporalDepthAgreement1(center, dL, depthProtect) +
        OCCULT_RM_TemporalDepthAgreement1(center, dR, depthProtect) +
        OCCULT_RM_TemporalDepthAgreement1(center, dU, depthProtect) +
        OCCULT_RM_TemporalDepthAgreement1(center, dD, depthProtect);

    float normalSum =
        OCCULT_RM_TemporalNormalAgreement1(o.normal, nL, dL) +
        OCCULT_RM_TemporalNormalAgreement1(o.normal, nR, dR) +
        OCCULT_RM_TemporalNormalAgreement1(o.normal, nU, dU) +
        OCCULT_RM_TemporalNormalAgreement1(o.normal, nD, dD);

    float lumaSum =
        OCCULT_RM_TemporalLumaAgreement1(l0, lL, dL, lumaProtect) +
        OCCULT_RM_TemporalLumaAgreement1(l0, lR, dR, lumaProtect) +
        OCCULT_RM_TemporalLumaAgreement1(l0, lU, dU, lumaProtect) +
        OCCULT_RM_TemporalLumaAgreement1(l0, lD, dD, lumaProtect);

    float activeTapCount =
        step(0.0001, dL.confidence) +
        step(0.0001, dR.confidence) +
        step(0.0001, dU.confidence) +
        step(0.0001, dD.confidence);
    float activeTapNorm = max(activeTapCount, 1.0);
    float neighborCoverage = saturate((dL.confidence + dR.confidence + dU.confidence + dD.confidence) * 0.25);
    float agreementMean;
    uint appliedTags = 0u;

    o.depth_agreement = saturate(depthSum * OCCULT_SafeRcp(activeTapNorm, 0.0));
    o.normal_agreement = saturate(normalSum * OCCULT_SafeRcp(activeTapNorm, 0.0));
    o.luma_agreement = saturate(lumaSum * OCCULT_SafeRcp(activeTapNorm, 0.0));
    agreementMean = saturate((o.depth_agreement + o.normal_agreement + o.luma_agreement) * 0.333333);
    appliedTags = OCCULT_RM_ApplyTag(appliedTags, OCCULT_RM_TAG_AGREEMENT_APPLIED * (agreementMean < 0.9999 ? 1u : 0u));
    appliedTags = OCCULT_RM_ApplyTag(appliedTags, OCCULT_RM_TAG_COVERAGE_APPLIED * (((o.depth_confidence < 0.9999) || (neighborCoverage < 0.9999)) ? 1u : 0u));
    o.edge_risk = saturate(o.depth_edge);
    appliedTags = OCCULT_RM_ApplyTag(appliedTags, OCCULT_RM_TAG_EDGE_PINCH_APPLIED * (o.edge_risk > 0.0001 ? 1u : 0u));
    o.stability = saturate(agreementMean * saturate((o.depth_confidence + neighborCoverage) * 0.5));
    o.reuse_ready = saturate(o.stability * saturate(1.0 - o.edge_risk));
    appliedTags = OCCULT_RM_ApplyTag(appliedTags, OCCULT_RM_TAG_REUSE_GATE_APPLIED * (o.reuse_ready + 0.0001 < o.stability ? 1u : 0u));
    o.applied_tags = appliedTags;
    return o;
}
#endif

float OCCULT_RM_ResolveDepthAgreement(float centerDepth, float tapDepth, float edgeProtect)
{
    float protect = max(edgeProtect, 0.000001);
    return saturate(1.0 - abs(centerDepth - tapDepth) / protect);
}

float OCCULT_RM_ResolveSampleWeight(float centerDepth, float tapDepth, float packedWeight, float edgeProtect)
{
    float depthAgree = OCCULT_RM_ResolveDepthAgreement(centerDepth, tapDepth, edgeProtect);
    return saturate(max(packedWeight, 0.0) * depthAgree);
}

float3 OCCULT_RM_ResolveNormalize(float3 rgbWeighted, float weight)
{
    return rgbWeighted * OCCULT_SafeRcp(max(weight, OCCULT_RM_RESOLVE_MIN_WEIGHT), 0.0);
}

float4 OCCULT_RM_ResolvePack(float3 rgbNormalized, float weight)
{
    return float4(saturate(rgbNormalized), saturate(weight));
}

float4 OCCULT_RM_ResolveCombine5(float4 c0, float4 c1, float4 c2, float4 c3, float4 c4, float w0, float w1, float w2, float w3, float w4)
{
    float total = max(w0 + w1 + w2 + w3 + w4, OCCULT_RM_RESOLVE_MIN_WEIGHT);
    float3 rgb = (c0.rgb * w0 + c1.rgb * w1 + c2.rgb * w2 + c3.rgb * w3 + c4.rgb * w4) * OCCULT_SafeRcp(total, 0.0);
    float alpha = saturate((c0.a * w0 + c1.a * w1 + c2.a * w2 + c3.a * w3 + c4.a * w4) * OCCULT_SafeRcp(total, 0.0));
    return float4(saturate(rgb), alpha);
}

#endif // OCCULT_API_RM_RESOLVE_FXH
