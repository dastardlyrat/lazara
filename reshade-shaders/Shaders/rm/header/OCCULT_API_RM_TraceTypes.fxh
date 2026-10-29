#ifndef OCCULT_API_RM_TRACE_TYPES_FXH
#define OCCULT_API_RM_TRACE_TYPES_FXH

#define OCCULT_RM_TRACE_API_VERSION 4

#define OCCULT_RM_TRACE_DOMAIN_SCREEN_DEPTH 0u
#define OCCULT_RM_TRACE_DOMAIN_SDF          1u

#define OCCULT_RM_TRACE_FAMILY_LOCAL       0u
#define OCCULT_RM_TRACE_FAMILY_REFLECTION  1u
#define OCCULT_RM_TRACE_FAMILY_ENERGY      2u
#define OCCULT_RM_TRACE_FAMILY_BOUNCE      3u
#define OCCULT_RM_TRACE_FAMILY_CUSTOM      4u

#define OCCULT_RM_TRACE_INTENT_PRIMARY      0u
#define OCCULT_RM_TRACE_INTENT_SECONDARY    1u
#define OCCULT_RM_TRACE_INTENT_CONTACT      2u
#define OCCULT_RM_TRACE_INTENT_REFLECTION   3u
#define OCCULT_RM_TRACE_INTENT_ENERGY       4u
#define OCCULT_RM_TRACE_INTENT_COLOR_DONOR  5u
#define OCCULT_RM_TRACE_INTENT_COLOR_BOUNCE 6u
#define OCCULT_RM_TRACE_INTENT_CUSTOM       7u

#define OCCULT_RM_TRACE_MISS_NONE               0u
#define OCCULT_RM_TRACE_MISS_INVALID_CONFIDENCE 1u
#define OCCULT_RM_TRACE_MISS_LEFT_DOMAIN        2u
#define OCCULT_RM_TRACE_MISS_MAX_STEPS          3u
#define OCCULT_RM_TRACE_MISS_NO_INTERSECTION    4u
#define OCCULT_RM_TRACE_MISS_MAX_TRAVEL         5u
#define OCCULT_RM_TRACE_MISS_INVALID_RAY        6u
#define OCCULT_RM_TRACE_MISS_DEPENDENCY         7u
#define OCCULT_RM_TRACE_MISS_SELF_INTERSECTION  8u
#define OCCULT_RM_TRACE_MISS_STARTED_BEHIND     9u
#define OCCULT_RM_TRACE_MISS_NO_VALID_CROSSING 10u

// Non-terminal traversal events. These flags preserve provenance without
// replacing the terminal miss_reason field. Multiple bits may be present.
#define OCCULT_RM_TRACE_REJECT_NONE                         0u
#define OCCULT_RM_TRACE_REJECT_INVALID_SAMPLE_ENCOUNTERED   1u
#define OCCULT_RM_TRACE_REJECT_SELF_INTERSECTION_REJECTED   2u
#define OCCULT_RM_TRACE_REJECT_STARTED_ON_SURFACE           4u
#define OCCULT_RM_TRACE_REJECT_STARTED_BEHIND                8u
#define OCCULT_RM_TRACE_REJECT_BEFORE_MINIMUM_STEP          16u

struct OCCULT_RM_TracePolicy
{
    uint family;
    uint intent;
    int active_steps;
    float max_travel;
    float thickness;
    float confidence_min;
    float eps_abs;
    float eps_rel;
    float min_step;
    float softness;
};

// Function-local interchange record. It is not a mandatory framebuffer carrier.
// Each consumer may cast with its own policy and may optionally pack only the fields it needs.
struct OCCULT_RM_TraceRecord
{
    float valid;
    float hit;
    float miss;
    float2 hit_uv;
    float3 hit_position;
    float3 hit_normal;
    float hit_normal_magnitude;
    float hit_normal_valid;
    float ray_depth;
    float scene_depth;
    float delta;
    float travel;
    float travel01;
    float step_count;
    float step01;
    float confidence;
    float edge_risk;
    float normal_alignment;
    float min_distance;
    float visibility;
    uint domain;
    uint family;
    uint intent;
    uint miss_reason;
    uint rejection_flags;
    uint applied_tags;
};

#endif // OCCULT_API_RM_TRACE_TYPES_FXH
