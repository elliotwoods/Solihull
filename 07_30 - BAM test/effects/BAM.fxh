//-------------
//BAM include file
//-------------


//---------
//Parameters
//
//transforms
float4x4 tW: WORLD;
float4x4 tV: VIEW;
float4x4 tP: PROJECTION;
float4x4 tVP: VIEWPROJECTION;
float4x4 tWVP: WORLDVIEWPROJECTION;

float Feather = 0.05;
float TearingThreshold = 0.1f; // Higher = sticter
//
//---------


//---------
//Structs
//
struct Projector {
	float4x4 View;
	float4x4 Projection;
	float Brightness;
};

struct AreaSection {
    float4 Pos : POSITION;
	float4 PosW : TEXCOORD0;
    float4 PosP : TEXCOORD1;
	float4 NormW : TEXCOORD2;
	float4 NormV : TEXCOORD3;
};

struct ProjectorPixel {
	float4 PosV;
	float4 NormV;
	float4 PosP;
};
//
//---------


//---------
//Vertex shaders
//
AreaSection BAMVS(
    float4 Pos : POSITION,
	float4 Norm : NORMAL)
{
    //inititalize all fields of output struct with 0
    AreaSection Out = (AreaSection) 0;
	
    //transform position
	Out.PosW = mul(Pos, tW);
    Out.PosP = mul(Out.PosW, tVP);
	Out.Pos = Out.PosP;
	
	//transform normals
	Out.NormW.xyz = normalize( mul( (float3) Norm, (float3x3) tW));
	Out.NormW.w = 1.0f;
	Out.NormV.xyz = normalize( mul( (float3) Out.NormW, (float3x3) tV));
	Out.NormV.w = 1.0f;
	
    return Out;
}

//
//---------


Projector BuildProjector(float4x4 View, float4x4 Projection, float Brightness) {
	Projector projector;
	
	projector.View = View;
	projector.Projection = Projection;
	projector.Brightness = Brightness;
	
	return projector;
}

///Determines maximum available brightness that can be given from this projector
/// to this area section, taking into account:
///     * Kill pixels with extreme tearing
///     * Feather pixels at edge of projection plane
/// This function is used during Generate and Apply
float ProjectorFactor(ProjectorPixel pixel) {
    float factor = 1.0f;

    //----
	//Torn pixels
	float tearing = -pixel.NormV.z;
	
	factor *= smoothstep(TearingThreshold, TearingThreshold * 1.5, tearing);
	//
    //----
	
	
    //----
    //Edge feather
    const float2 toEdge = (float2(0.5f, 0.5f) - pixel.PosP.xy);
    const float2 edgeFactor = saturate(toEdge / Feather);

    factor *= edgeFactor.x * edgeFactor.y;
    //
    //----
	
	return factor;
}

ProjectorPixel ProjectPixel(AreaSection section, Projector projector) {
	ProjectorPixel pixel;
	
	pixel.PosV = mul(section.PosW, projector.View);
	pixel.PosP = mul(pixel.PosV, projector.Projection);
	pixel.PosP /= pixel.PosP.w;
	
	pixel.NormV.xyz = normalize(mul( (float3) section.NormW, (float3x3) projector.View));
	pixel.NormV.w = 1.0f;
	
	
	return pixel;
}

///Determines brightness given from this projector per unit area
/// of this fragment area section (in BAM space).
float CalcBrightness(AreaSection fragment, Projector projector, sampler shadowMap, float4x4 viewport) {
	
	ProjectorPixel PPixel = ProjectPixel(fragment, projector);
	
	float luminance = 1.0f;
	
	//---
	//Projector power
	luminance = projector.Brightness * ProjectorFactor(PPixel);
	//
	//---
	
	
	//---
	//Distance fall-off
	luminance /= pow(PPixel.PosV.z, 2.0f);
	//
	//---
	
	
	//---
	//Shadow map
	float4 texcd;
	texcd.xy = PPixel.PosP.xy;
	texcd.xy += 1.0f;
	texcd.xy /= 2.0f;
	texcd.y = 1.0f - texcd.y;
	texcd.zw = float2(0.0f, 1.0f);
	
	texcd.xy -= 0.5f;
	texcd = mul(texcd, viewport);
	texcd /= texcd.w;
	texcd.xy += 0.5f;
	
	float lookupDepth = tex2D(shadowMap, texcd.xy);
	lookupDepth = pow(lookupDepth, 2);
	
	float actualDepth = PPixel.PosP.z;
	luminance *= 1.0f - smoothstep(lookupDepth, lookupDepth + 0.0005, actualDepth);
	//
	//---
	
	
	//---
	//Normal
	luminance *= clamp(-PPixel.NormV.z, 0, 1);
	//
	//---
	
	return luminance;
}

float ApplyBAMFactor(AreaSection fragment, Projector projector, float4x4 BAMView, float4x4 BAMProjection, sampler BAM, sampler Depth, float3 Gamma, float TargetBrightness) {
	
	//---
	//Lookup BAM map
	float4 PosBAM = mul(mul(fragment.PosW, BAMView), BAMProjection);
	PosBAM /= PosBAM.w;
	float2 TexCd = PosBAM.xy;
	TexCd += 1.0f;
	TexCd /= 2.0f;
	TexCd.y = 1.0f - TexCd.y;
	
	const float BAMValue = tex2D(BAM, TexCd).r;
	float BAMDepth = tex2D(Depth, TexCd).r;
	BAMDepth *= BAMDepth;
	//
	//---
	
	
	//---
	//Use the ProjectorFactor as a starting value
	ProjectorPixel PPixel = ProjectPixel(fragment, projector);
	const float projectorFactor = ProjectorFactor(PPixel);
	//
	//---
	
	
	//---
	//Kill pixels in shadow from the BAM view
	const float actualBAMDepth = PosBAM.z;
	const float BAMShadowFactor = 1.0f - smoothstep(BAMDepth, BAMDepth + 0.0005, actualBAMDepth);
	//
	//---
	
	//---
	//Kill pixels torn in the BAM view
	const float TearingThreshold = 0.1;
	const float tearing = - normalize(mul( (float3) fragment.NormW, (float3x3) BAMView )).z;
	const float TearingFactor = smoothstep(TearingThreshold, TearingThreshold * 1.5, tearing);
	//
	//---
	
	
	float factor = projectorFactor;
	factor *= TargetBrightness / BAMValue;
	factor *= BAMShadowFactor;
	factor *= TearingFactor;
	
	return factor;
}