Texture3D<float4> velocityRead : register(t0);
Texture3D<float4> inkRead : register(t1);
RWTexture3D<float4> velocityWrite : register(u0);
RWTexture3D<float4> inkWrite : register(u1);

SamplerState TextureSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
	AddressW = Clamp;
};

uniform uint2 texResolution;
uniform float timeSinceLast;
uniform float reciprocalDeltaX;
uniform float velocityDissipationConstant;
uniform float inkDissipationConstant;

//potato!

[numthreads(@value( threads_per_group_x ), @value( threads_per_group_y ), @value( threads_per_group_z ))]
void main
(
	uint3 gl_LocalInvocationID : SV_GroupThreadID,
	uint3 gl_GlobalInvocationID : SV_DispatchThreadID
)
{
	uint3 cell = gl_GlobalInvocationID;
	if (cell.x >= texResolution.x || cell.y >= texResolution.y || cell.z != 0)
		return;

	int3 sourceCell = int3(cell);
	float4 velocity = velocityRead.Load(int4(sourceCell, 0));

	float2 backtracedCell = float2(cell.xy) -
		float2(velocity.x, velocity.z) * (timeSinceLast * reciprocalDeltaX);
	backtracedCell = clamp(backtracedCell, float2(0.0, 0.0),
		float2(texResolution) - 1.0);

	float3 samplePosition = float3(
		(backtracedCell + 0.5) / float2(texResolution),
		0.5);

	float4 advectedVelocity = velocityRead.SampleLevel(
		TextureSampler, samplePosition, 0);
	float4 advectedInk = inkRead.SampleLevel(
		TextureSampler, samplePosition, 0);

	float elapsedFrames = max(timeSinceLast, 0.0) * 60.0;
	advectedVelocity.xyz *= pow(saturate(velocityDissipationConstant), elapsedFrames);
	advectedInk.xyz *= pow(saturate(inkDissipationConstant), elapsedFrames);

	velocityWrite[cell] = float4(advectedVelocity.x, 0.0, advectedVelocity.z, 0.0);
	inkWrite[cell] = advectedInk;
}

/*
Legacy in-place advection implementation retained for reference:

RWTexture3D<float4> velocityTexture : register(u0);
RWTexture3D<float4> inkTexture : register(u1);

uniform uint2 texResolution;
uniform float timeSinceLast;
uniform float reciprocalDeltaX;
uniform float velocityDissipationConstant;
uniform float inkDissipationConstant;

int3 idx = int3(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y, gl_GlobalInvocationID.z);
int3 currentIdx = int3(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y, gl_GlobalInvocationID.z);
int4 idx4 = int4(gl_GlobalInvocationID.x, gl_GlobalInvocationID.y, gl_GlobalInvocationID.z, 0);
float4 velocity = velocityTexture.Load(idx4);
float4 ink = inkTexture.Load(idx4);
idx = idx - (velocity.xyz * timeSinceLast);
float3 a = velocityTexture.Load(float3(idx.x - 1, idx.y, idx.z)).xyz;
float3 b = velocityTexture.Load(float3(idx.x + 1, idx.y, idx.z)).xyz;
float3 c = velocityTexture.Load(float3(idx.x, idx.y - 1, idx.z)).xyz;
float3 d = velocityTexture.Load(float3(idx.x, idx.y + 1, idx.z)).xyz;
float3 e = lerp(a, c, 0.5);
float3 f = lerp(b, d, 0.5);
float3 newVel = lerp(e, f, 0.5);
velocityTexture[idx] = float4(newVel.xyz, 0);
float3 inkIdx = currentIdx - (velocity.xyz * timeSinceLast);
float4 ai = inkTexture.Load(float4(inkIdx.x - 1, inkIdx.y, inkIdx.z, 0));
float4 bi = inkTexture.Load(float4(inkIdx.x + 1, inkIdx.y, inkIdx.z, 0));
float4 ci = inkTexture.Load(float4(inkIdx.x, inkIdx.y - 1, inkIdx.z, 0));
float4 di = inkTexture.Load(float4(inkIdx.x, inkIdx.y + 1, inkIdx.z, 0));
float4 ei = lerp(ai, ci, 0.5);
float4 fi = lerp(bi, di, 0.5);
float4 newInk = lerp(ei, fi, 0.5);
if (length(newInk.xyz) > 0)
	inkTexture[idx] = float4(newInk.xyz, ink.w);
else
	inkTexture[idx] = float4(newInk.xyz, 0);
*/
