#ifndef GRAPHICS_API_GLES3
	#define NO_NATIVE_SHADOWMAP
#endif

#ifdef NO_NATIVE_SHADOWMAP
	#define TEXTURE2D_SHADOW(textureName) uniform mediump sampler2D textureName
	#define SAMPLE_TEXTURE2D_SHADOW(textureName, coord3) texture2D(textureName,coord3.xy).r<coord3.z?0.0:1.0
	#define TEXTURE2D_SHADOW_PARAM(shadowMap) sampler2D shadowMap
#else
	#define TEXTURE2D_SHADOW(textureName) uniform mediump sampler2DShadow textureName
	#define SAMPLE_TEXTURE2D_SHADOW(textureName, coord3) texture2D(textureName,coord3)
	#define TEXTURE2D_SHADOW_PARAM(shadowMap) sampler2DShadow shadowMap
#endif

#include "ShadowSampleTent.glsl"

TEXTURE2D_SHADOW(u_shadowMap1);
uniform vec4 u_ShadowMapSize;
uniform vec4 u_ShadowBias; // x: depth bias, y: normal bias
uniform vec4 u_ShadowParams; // x: shadowStrength
uniform vec4 u_shadowPSSMDistance;

vec4 packDepth(const in float depth)
{
	const vec4 bitShift = vec4(256.0*256.0*256.0, 256.0*256.0, 256.0, 1.0);
	const vec4 bitMask	= vec4(0.0, 1.0/256.0, 1.0/256.0, 1.0/256.0);
	vec4 res = mod(depth*bitShift*vec4(255), vec4(256))/vec4(255);
	res -= res.xxyz * bitMask;
	return res;
}
float unpackDepth(const in vec4 rgbaDepth)
{
	const vec4 bitShift = vec4(1.0/(256.0*256.0*256.0), 1.0/(256.0*256.0), 1.0/256.0, 1.0);
	float depth = dot(rgbaDepth, bitShift);
	return depth;
}

float sampleShdowMapFiltered4(TEXTURE2D_SHADOW_PARAM(shadowMap),vec3 shadowCoord,vec4 shadowMapSize)
{
	float attenuation;
	vec4 attenuation4;
	vec2 offset=shadowMapSize.xy/2.0;
	vec3 shadowCoord0=shadowCoord + vec3(-offset,0.0);
	vec3 shadowCoord1=shadowCoord + vec3(offset.x,-offset.y,0.0);
	vec3 shadowCoord2=shadowCoord + vec3(-offset.x,offset.y,0.0);
	vec3 shadowCoord3=shadowCoord + vec3(offset,0.0);
    attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(shadowMap, shadowCoord0);
    attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(shadowMap, shadowCoord1);
    attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(shadowMap, shadowCoord2);
    attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(shadowMap, shadowCoord3);
	attenuation = dot(attenuation4, vec4(0.25));
	return attenuation;
}

float sampleShdowMapFiltered9(TEXTURE2D_SHADOW_PARAM(shadowMap),vec3 shadowCoord,vec4 shadowmapSize)
{
	float attenuation;
	float fetchesWeights[9];
    vec2 fetchesUV[9];
    sampleShadowComputeSamplesTent5x5(shadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);
	attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[0].xy, shadowCoord.z));
    attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[1].xy, shadowCoord.z));
    attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[2].xy, shadowCoord.z));
    attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[3].xy, shadowCoord.z));
    attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[4].xy, shadowCoord.z));
    attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[5].xy, shadowCoord.z));
    attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[6].xy, shadowCoord.z));
    attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[7].xy, shadowCoord.z));
    attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(shadowMap, vec3(fetchesUV[8].xy, shadowCoord.z));
	return attenuation;
}

float getShadowPSSM1(vec4 lightMVPPos,vec4 pssmDistance,vec4 shadowMapSize,float posViewZ)
{
	float attenuation = 1.0;
	if( posViewZ < pssmDistance.x )
	{
		vec3 vText = lightMVPPos.xyz / lightMVPPos.w;
		float fMyZ = vText.z;
		if ( fMyZ <= 1.0 ) 
		{
			#if defined(SHADOW_SOFT_SHADOW_HIGH)
				attenuation = sampleShdowMapFiltered9(u_shadowMap1,vText,shadowMapSize);
			#elif defined(SHADOW_SOFT_SHADOW_LOW)
				attenuation = sampleShdowMapFiltered4(u_shadowMap1,vText,shadowMapSize);
			#else
				attenuation = SAMPLE_TEXTURE2D_SHADOW(u_shadowMap1,vText);
			#endif
			attenuation = mix(1.0,attenuation,u_ShadowParams.x);//u_ShadowParams.x:shadow strength
		}
	}
	return attenuation;
}

vec3 applyShadowBias(vec3 positionWS, vec3 normalWS, vec3 lightDirection)
{
    float invNdotL = 1.0 - clamp(dot(lightDirection, normalWS),0.0,1.0);
    float scale = invNdotL * u_ShadowBias.y;

    // normal bias is negative since we want to apply an inset normal offset
    positionWS += lightDirection * vec3(u_ShadowBias);
    positionWS += normalWS * vec3(scale);
    return positionWS;
}