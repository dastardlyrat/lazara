#ifndef OCCULT_API_RM_TYPES_FXH
#define OCCULT_API_RM_TYPES_FXH

struct OCCULT_RM_DepthSample
{
    float raw;
    float linear01;
    float confidence;
    float edge;
    float sky;
    float empty_like;
};

struct OCCULT_RM_Ray
{
    float2 uv0;
    float2 step_uv;
    float z0;
    float step_z;
    float thickness;
    float confidence_min;
    int steps;
};

struct OCCULT_RM_Hit
{
    float hit;
    float miss;
    float2 uv;
    float ray_z;
    float scene_z;
    float delta;
    float step_index;
    float confidence;
    float reason;
};

struct OCCULT_RM_BatchAccum
{
    float value;
    float weight;
    float hit_count;
    float confidence;
};

#endif // OCCULT_API_RM_TYPES_FXH
