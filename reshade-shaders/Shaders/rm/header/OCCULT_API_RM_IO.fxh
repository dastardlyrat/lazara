#ifndef OCCULT_API_RM_IO_FXH
#define OCCULT_API_RM_IO_FXH

texture2D OCCULT_RM_ColorTex : COLOR;
texture2D OCCULT_RM_DepthTex : DEPTH;

sampler2D OCCULT_RM_ColorSampler
{
    Texture = OCCULT_RM_ColorTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
};

sampler2D OCCULT_RM_DepthSampler
{
    Texture = OCCULT_RM_DepthTex;
    AddressU = CLAMP;
    AddressV = CLAMP;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

uniform bool OCCULT_RM_HasDepth < source = "bufready_depth"; >;

float2 OCCULT_RM_PixelSize()
{
    return float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);
}

float2 OCCULT_RM_ClampUV(float2 uv)
{
    return clamp(uv, float2(0.0, 0.0), float2(1.0, 1.0));
}

float4 OCCULT_RM_LoadColor(float2 uv)
{
    return tex2Dlod(OCCULT_RM_ColorSampler, float4(OCCULT_RM_ClampUV(uv), 0.0, 0.0));
}

float OCCULT_RM_LoadDepthRaw(float2 uv)
{
    return tex2Dlod(OCCULT_RM_DepthSampler, float4(OCCULT_RM_ClampUV(uv), 0.0, 0.0)).r;
}

float OCCULT_RM_Luma(float3 rgb)
{
    return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

#endif // OCCULT_API_RM_IO_FXH
