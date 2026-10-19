struct Particle
{
	float ink;
	float4 colour;
	float3 velocity;
	float inkLifetime;
};

RWStructuredBuffer<Particle> inputUavBuffer		: register(u0);
RWTexture3D<float4> velocityTexture				: register(u1);
RWTexture3D<float4> inkTexture					: register(u2);

SamplerState TextureSampler
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = Clamp;
	AddressV = Clamp;
};

uniform uint2 texResolution;
uniform float timeSinceLast;

[numthreads(@value(threads_per_group_x), @value(threads_per_group_y), @value(threads_per_group_z))]
void main
(
	uint3 gl_LocalInvocationID : SV_GroupThreadID,
	uint3 gl_GlobalInvocationID : SV_DispatchThreadId
)
{
	if (gl_GlobalInvocationID.x > 0 && 
		gl_GlobalInvocationID.x < texResolution.x - 1 && 
		gl_GlobalInvocationID.y > 0 &&
		gl_GlobalInvocationID.y < texResolution.y - 1)
	{
		uint rwIdx = gl_GlobalInvocationID.y * texResolution.x + gl_GlobalInvocationID.x;

		int4 idx4 = int4(gl_GlobalInvocationID.xyz, 0);

		float4 velocity = float4(inputUavBuffer[rwIdx].velocity, 0.0);

		float4 ink = float4(inputUavBuffer[rwIdx].ink, 0, 0, inputUavBuffer[rwIdx].inkLifetime);

		float width = texResolution.x;

		//if (ink.z > 0) {
		//} 

		//if (ink.z < 0) {
		//	ink.x = -5.0f;
		//}

		//ink.z -= timeSinceLast;

		//if (ink.z < -10.0f) {
		//	ink.z = 0;
		//}
		
		inkTexture[gl_GlobalInvocationID] += ink;
		
		//inkTexture[gl_GlobalInvocationID] += float4(inputUavBuffer[rwIdx].ink, 0, 0, inputUavBuffer[rwIdx].inkLifetime);

		velocityTexture[gl_GlobalInvocationID] += velocity;
	}
}