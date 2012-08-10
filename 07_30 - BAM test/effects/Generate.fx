//@author: elliotwoods
//@help: Creates a BAM (Brightness Assignment Map)
//@tags: BAM, projection mapping
//@credits: kimchiandchips

#define PROJECTOR_COUNT 2
#include "BAM.fxh"
// --------------------------------------------------------------------------------------------------
// PARAMETERS:
// --------------------------------------------------------------------------------------------------

//texture
texture Tex <string uiname="Depth Map";>;
sampler Samp = sampler_state    //sampler for doing the texture-lookup
{
    Texture   = (Tex);          //apply a texture to the sampler
    MipFilter = POINT;         //sampler states
    MinFilter = POINT;
    MagFilter = POINT;
};

float4x4 tProjectorV[PROJECTOR_COUNT] <string uiname="Projector View Transforms";>;
float4x4 tProjectorP[PROJECTOR_COUNT] <string uiname="Projector Projection Transforms";>;
float tProjectorB[PROJECTOR_COUNT] <string uiname="Projector Brightness";>;
float4x4 tProjectorL[PROJECTOR_COUNT] <string uiname="Projector Viewport Lookup";>;

// --------------------------------------------------------------------------------------------------
// VERTEXSHADERS
// --------------------------------------------------------------------------------------------------

AreaSection VS(
    float4 Pos : POSITION,
	float4 Norm : NORMAL)
{
    //inititalize all fields of output struct with 0
    AreaSection Out = (AreaSection) 0;
	
    //transform position
	Out.PosW = mul(Pos, tW);
    Out.PosP = mul(Out.PosW, tVP);
	
	//transform normals
	Out.NormW.xyz = normalize( mul( (float3) Norm, (float3x3) tW));
	Out.NormW.w = 1.0f;
	
    return Out;
}

// --------------------------------------------------------------------------------------------------
// PIXELSHADERS:
// --------------------------------------------------------------------------------------------------

///Determines available brightness per unit area for a projector
/// at a geometry element seen by a pixel fragment in BAM space.
float AvailableBrightness(AreaSection fragment) {
	float brightness = 0;
	Projector Projectors[PROJECTOR_COUNT];
	
	for (int i=0; i<PROJECTOR_COUNT; i++) {
		Projectors[i] = BuildProjector(tProjectorV[i], tProjectorP[i], tProjectorB[i]);
		brightness += CalcBrightness(fragment, Projectors[i], Samp, tProjectorL[i]);
	}
	
	return brightness;
}

float4 PS(AreaSection fragment): COLOR
{
	Projector projector = BuildProjector(tProjectorV[0], tProjectorP[0], tProjectorB[0]);
	return float4(( float3) AvailableBrightness(fragment), 1.0f);
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