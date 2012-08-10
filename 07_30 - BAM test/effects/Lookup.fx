//@author: elliotwoods
//@help: Creates a BAM (Brightness Assignment Map)
//@tags: BAM, projection mapping
//@credits: kimchiandchips

#include "BAM.fxh"
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//BAM Map
float4x4 BAMView <string uiname="BAM View Transform";>;
float4x4 BAMProjection <string uiname="BAM Projection Transform";>;

texture Tex <string uiname="BAM Map";>;
sampler SampBAM = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = LINEAR;         //sampler states
    MinFilter = LINEAR;
    MagFilter = LINEAR;
};

texture TexDepth <string uiname="BAM Depth";>;
sampler SampDepth = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (TexDepth);          //apply a texture to the sampler
    MipFilter = POINT;         //sampler states
    MinFilter = POINT;
    MagFilter = POINT;
};

float tProjectorB <string uiname="Projector Brightness";> = 1.0f;
float3 Gamma = float3(1.0f, 1.0f, 1.0f);
float TargetBrightness <string uiname="Target Brightness";> = 1.0f;

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------
// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

float4 PS(AreaSection fragment): COLOR
{
	Projector projector = BuildProjector(tV, tP, tProjectorB);
	float factor = ApplyBAMFactor(fragment, projector, BAMView, BAMProjection, SampBAM, SampDepth, Gamma, TargetBrightness);
	return float4( (float3) factor, 1.0f);
}

// --------------------------------------------------------------------------------------------------
// TECHNIQUES:
// --------------------------------------------------------------------------------------------------

technique TBAMFromSweetSpot
{
    pass P0
    {
        VertexShader = compile vs_3_0 BAMVS();
        PixelShader = compile ps_3_0 PS();
    }
}