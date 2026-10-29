#ifndef OCCULT_API_ALL_FXH
#define OCCULT_API_ALL_FXH

#include "OCCULT_API_Contract.fxh"
#include "OCCULT_API_SafeMath.fxh"
#include "OCCULT_API_Debug.fxh"
#include "OCCULT_API_PassSampling.fxh"
#include "MIXSR_API_RM_Domain.fxh"
#include "OCCULT_API_RM_Types.fxh"
#include "OCCULT_API_RM_TraceTypes.fxh"
#include "OCCULT_API_RM_IO.fxh"
#include "OCCULT_API_RM_Depth.fxh"
#include "OCCULT_API_RM_Sampling.fxh"
#include "OCCULT_API_RM_Ray.fxh"
#include "OCCULT_API_RM_Debug.fxh"
#include "OCCULT_API_RM_ColorDonor.fxh"
#include "OCCULT_API_RM_PassSampling.fxh"
#include "OCCULT_API_RM_SSR.fxh"
#include "OCCULT_API_RM_Resolve.fxh"
#include "OCCULT_API_RM_StabilityNeighborhood.fxh"
#include "OCCULT_API_RM_SDF.fxh"
#include "OCCULT_API_RM_Bounds.fxh"
#include "OCCULT_API_RM_PrimaryMarch.fxh"
#include "OCCULT_API_RM_Material.fxh"
#include "OCCULT_API_RM_Secondary.fxh"

// MIXSR tracing boundary: include OCCULT_API_RM_TraceAll.fxh explicitly in effects that need trace adapters/debug.
// MIXSR volatility boundary: scene-contact/application headers are included only by RM 46-49, not by the base bundle.
#include "OCCULT_API_GoldenWeave.fxh"
#endif // OCCULT_API_ALL_FXH
