#ifndef OCCULT_API_RM_STABILITY_NEIGHBORHOOD_FXH
#define OCCULT_API_RM_STABILITY_NEIGHBORHOOD_FXH

struct OCCULT_RM_StabilityTapAddress
{
    float2 requested_uv;
    float2 resolved_uv;
    float2 footprint_half_uv;
    float requested_in_bounds;
    float resolved_in_bounds;
    float address_valid;
    float independent_evidence;
    float border_coverage;
    float remapped;
    float duplicate_axis_count;
    float address_confidence;
};

struct OCCULT_RM_StabilityAuthority
{
    float depth_linear01;
    float depth_confidence;
    float depth_edge;
    float neighbor_coverage;
    float depth_agreement;
    float normal_profile;
    float luma_agreement;
    float stability;
    float reuse_ready;
};

float OCCULT_RM_StabilityTapInBounds(float2 uv)
{
    return
        step(0.0, uv.x) * step(uv.x, 1.0) *
        step(0.0, uv.y) * step(uv.y, 1.0);
}

float OCCULT_RM_StabilityAxisCoverage(float requested, float footprintHalf)
{
    float coverage = 0.0;
    float halfWidth = abs(footprintHalf);

    if (halfWidth <= 0.000001)
    {
        coverage = step(0.0, requested) * step(requested, 1.0);
    }
    else
    {
        float low = requested - halfWidth;
        float high = requested + halfWidth;
        float overlap = max(0.0, min(high, 1.0) - max(low, 0.0));
        coverage = saturate(overlap / max(2.0 * halfWidth, 0.000001));
    }

    return coverage;
}

OCCULT_RM_StabilityTapAddress OCCULT_RM_BuildStabilityTapAddress(
    float2 requestedUv,
    float2 footprintHalfUv)
{
    OCCULT_RM_StabilityTapAddress address;
    float2 safeFootprint = abs(footprintHalfUv);
    float coverageX = OCCULT_RM_StabilityAxisCoverage(requestedUv.x, safeFootprint.x);
    float coverageY = OCCULT_RM_StabilityAxisCoverage(requestedUv.y, safeFootprint.y);
    float duplicateX = 1.0 - step(0.999999, coverageX);
    float duplicateY = 1.0 - step(0.999999, coverageY);

    address.requested_uv = requestedUv;
    address.resolved_uv = OCCULT_RM_ClampUV(requestedUv);
    address.footprint_half_uv = safeFootprint;
    address.requested_in_bounds = OCCULT_RM_StabilityTapInBounds(requestedUv);
    address.resolved_in_bounds = OCCULT_RM_StabilityTapInBounds(address.resolved_uv);
    address.address_valid = address.resolved_in_bounds;
    address.independent_evidence = address.requested_in_bounds;
    address.border_coverage = saturate(coverageX * coverageY);
    address.remapped = step(
        0.000001,
        max(abs(address.resolved_uv.x - requestedUv.x), abs(address.resolved_uv.y - requestedUv.y)));
    address.duplicate_axis_count = duplicateX + duplicateY;
    address.address_confidence = saturate(
        address.address_valid *
        address.independent_evidence *
        address.border_coverage);
    return address;
}

OCCULT_RM_DepthSample OCCULT_RM_LoadLeanTapDepth(float2 uv)
{
    OCCULT_RM_DepthSample o;
    float2 safeUv = OCCULT_RM_ClampUV(uv);

    o.raw = OCCULT_RM_LoadDepthRaw(safeUv);
    o.linear01 = OCCULT_RM_LinearDepth01FromRaw(o.raw);
    o.sky = (o.linear01 >= OCCULT_RM_DepthSkyThreshold) ? 1.0 : 0.0;
    o.confidence = (OCCULT_RM_HasDepth ? 1.0 : 0.0) * (1.0 - o.sky);
    o.edge = 0.0;
    o.empty_like = 0.0;
    return o;
}

OCCULT_RM_DepthSample OCCULT_RM_MakeDeniedLeanTapDepth()
{
    OCCULT_RM_DepthSample o;
    o.raw = 0.0;
    o.linear01 = 0.0;
    o.confidence = 0.0;
    o.edge = 0.0;
    o.sky = 1.0;
    o.empty_like = 1.0;
    return o;
}

float OCCULT_RM_StabilityTapAvailability(
    OCCULT_RM_StabilityTapAddress address,
    OCCULT_RM_DepthSample tapDepth)
{
    return address.address_confidence * step(0.0001, tapDepth.confidence);
}

OCCULT_RM_StabilityAuthority OCCULT_RM_EvaluateStabilityAuthorityFast(
    float2 uv,
    float centerLuma,
    float depthProtect,
    float lumaProtect)
{
    OCCULT_RM_StabilityAuthority o;
    float2 uvSafe = OCCULT_RM_ClampUV(uv);
    OCCULT_RM_DepthSample centerDepth = OCCULT_RM_LoadLeanTapDepth(uvSafe);
    o.depth_linear01 = centerDepth.linear01;
    o.depth_edge = 0.0;
    o.depth_confidence = centerDepth.confidence;
    o.neighbor_coverage = 0.0;
    o.depth_agreement = 0.0;
    o.normal_profile = 0.0;
    o.luma_agreement = 0.0;
    o.stability = 0.0;
    o.reuse_ready = 0.0;

    if (centerDepth.confidence <= 0.0001)
        return o;

    float2 px = OCCULT_RM_PixelSize();
    float2 footprintHalfUv = px * 0.5;
    OCCULT_RM_StabilityTapAddress aL = OCCULT_RM_BuildStabilityTapAddress(uvSafe - float2(px.x, 0.0), footprintHalfUv);
    OCCULT_RM_StabilityTapAddress aR = OCCULT_RM_BuildStabilityTapAddress(uvSafe + float2(px.x, 0.0), footprintHalfUv);
    OCCULT_RM_StabilityTapAddress aU = OCCULT_RM_BuildStabilityTapAddress(uvSafe - float2(0.0, px.y), footprintHalfUv);
    OCCULT_RM_StabilityTapAddress aD = OCCULT_RM_BuildStabilityTapAddress(uvSafe + float2(0.0, px.y), footprintHalfUv);
    OCCULT_RM_DepthSample dL;
    OCCULT_RM_DepthSample dR;
    OCCULT_RM_DepthSample dU;
    OCCULT_RM_DepthSample dD;
    float lL = centerLuma;
    float lR = centerLuma;
    float lU = centerLuma;
    float lD = centerLuma;
    float tapAvailL = 0.0;
    float tapAvailR = 0.0;
    float tapAvailU = 0.0;
    float tapAvailD = 0.0;
    float activeTapWeight;
    float activeTapNorm;
    float neighborCoverage;
    float edgeRaw;
    float normalProxy;
    float agreementMean;

    dL = OCCULT_RM_MakeDeniedLeanTapDepth();
    dR = OCCULT_RM_MakeDeniedLeanTapDepth();
    dU = OCCULT_RM_MakeDeniedLeanTapDepth();
    dD = OCCULT_RM_MakeDeniedLeanTapDepth();

    if (aL.address_confidence > 0.0001)
    {
        dL = OCCULT_RM_LoadLeanTapDepth(aL.resolved_uv);
        tapAvailL = OCCULT_RM_StabilityTapAvailability(aL, dL);
    }
    if (aR.address_confidence > 0.0001)
    {
        dR = OCCULT_RM_LoadLeanTapDepth(aR.resolved_uv);
        tapAvailR = OCCULT_RM_StabilityTapAvailability(aR, dR);
    }
    if (aU.address_confidence > 0.0001)
    {
        dU = OCCULT_RM_LoadLeanTapDepth(aU.resolved_uv);
        tapAvailU = OCCULT_RM_StabilityTapAvailability(aU, dU);
    }
    if (aD.address_confidence > 0.0001)
    {
        dD = OCCULT_RM_LoadLeanTapDepth(aD.resolved_uv);
        tapAvailD = OCCULT_RM_StabilityTapAvailability(aD, dD);
    }

    activeTapWeight = tapAvailL + tapAvailR + tapAvailU + tapAvailD;
    activeTapNorm = max(activeTapWeight, 1.0);
    neighborCoverage = saturate(activeTapWeight * 0.25);
    o.neighbor_coverage = neighborCoverage;
    edgeRaw = max(
        max(abs(o.depth_linear01 - dL.linear01) * tapAvailL, abs(o.depth_linear01 - dR.linear01) * tapAvailR),
        max(abs(o.depth_linear01 - dU.linear01) * tapAvailU, abs(o.depth_linear01 - dD.linear01) * tapAvailD));
    o.depth_edge = saturate(edgeRaw * OCCULT_SafeRcp(max(OCCULT_RM_DepthEdgeScale, 0.000001), 0.0));
    o.depth_confidence = saturate(centerDepth.confidence * (1.0 - o.depth_edge));

    if ((o.depth_confidence <= 0.0001) || (activeTapWeight <= 0.0001))
        return o;

    if (tapAvailL > 0.0001) lL = OCCULT_RM_Luma(OCCULT_RM_LoadColor(aL.resolved_uv).rgb);
    if (tapAvailR > 0.0001) lR = OCCULT_RM_Luma(OCCULT_RM_LoadColor(aR.resolved_uv).rgb);
    if (tapAvailU > 0.0001) lU = OCCULT_RM_Luma(OCCULT_RM_LoadColor(aU.resolved_uv).rgb);
    if (tapAvailD > 0.0001) lD = OCCULT_RM_Luma(OCCULT_RM_LoadColor(aD.resolved_uv).rgb);

    o.depth_agreement = saturate((
        OCCULT_RM_ResolveDepthAgreement(o.depth_linear01, dL.linear01, depthProtect) * tapAvailL +
        OCCULT_RM_ResolveDepthAgreement(o.depth_linear01, dR.linear01, depthProtect) * tapAvailR +
        OCCULT_RM_ResolveDepthAgreement(o.depth_linear01, dU.linear01, depthProtect) * tapAvailU +
        OCCULT_RM_ResolveDepthAgreement(o.depth_linear01, dD.linear01, depthProtect) * tapAvailD)
        * OCCULT_SafeRcp(activeTapNorm, 0.0));
    o.luma_agreement = saturate((
        OCCULT_RM_TemporalLumaAgreement1(centerLuma, lL, dL, lumaProtect) * tapAvailL +
        OCCULT_RM_TemporalLumaAgreement1(centerLuma, lR, dR, lumaProtect) * tapAvailR +
        OCCULT_RM_TemporalLumaAgreement1(centerLuma, lU, dU, lumaProtect) * tapAvailU +
        OCCULT_RM_TemporalLumaAgreement1(centerLuma, lD, dD, lumaProtect) * tapAvailD)
        * OCCULT_SafeRcp(activeTapNorm, 0.0));
    normalProxy = saturate(max(1.0 - o.depth_edge, o.depth_agreement * 0.85));
    o.normal_profile = OCCULT_RM_SoftNormalPreference(normalProxy);
    agreementMean = saturate((o.depth_agreement + normalProxy + o.luma_agreement) * 0.333333);
    o.stability = saturate(agreementMean * saturate((o.depth_confidence + neighborCoverage) * 0.5));
    o.reuse_ready = saturate(o.stability * saturate(1.0 - o.depth_edge));
    return o;
}

float OCCULT_RM_StabilityCenterAuthority(
    float reuseReady,
    float depthConfidence,
    float readyStart,
    float readyFull)
{
    float safeFull = max(readyFull, readyStart + 0.001);
    float width = max(safeFull - readyStart, 0.000001);
    float t = saturate((reuseReady - readyStart) * OCCULT_SafeRcp(width, 0.0));
    float smoothReady = t * t * (3.0 - 2.0 * t);
    return saturate(
        smoothReady *
        max(depthConfidence, 0.0));
}

float OCCULT_RM_StabilityCenterNormalProfile(
    OCCULT_RM_StabilityAuthority center)
{
    return center.normal_profile;
}

float OCCULT_RM_StabilityTapSupport(
    OCCULT_RM_StabilityAuthority center,
    float centerLuma,
    float tapLuma,
    OCCULT_RM_DepthSample tapDepth,
    float addressConfidence,
    float depthProtect,
    float lumaProtect)
{
    float depthAgreement = OCCULT_RM_ResolveDepthAgreement(
        center.depth_linear01,
        tapDepth.linear01,
        depthProtect);
    float normalAgreement = OCCULT_RM_StabilityCenterNormalProfile(center);
    float lumaAgreement = OCCULT_RM_TemporalLumaAgreement1(
        centerLuma,
        tapLuma,
        tapDepth,
        lumaProtect);
    return saturate(
        addressConfidence *
        tapDepth.confidence *
        depthAgreement *
        normalAgreement *
        lumaAgreement);
}

#endif // OCCULT_API_RM_STABILITY_NEIGHBORHOOD_FXH
