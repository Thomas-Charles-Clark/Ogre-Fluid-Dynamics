Texture3D<float4> pressureTexture : register(t0);
Texture3D<float4> velocityTexture : register(t1);
RWTexture3D<float4> velocityOutput : register(u0);

uniform uint2 texResolution;
uniform float halfDeltaX;

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

	int2 p = int2(cell.xy);
	float4 velocity = velocityTexture.Load(int4(p, 0, 0));
	if (p.x > 0 && p.x < int(texResolution.x) - 1 &&
		p.y > 0 && p.y < int(texResolution.y) - 1)
	{
		float left = pressureTexture.Load(int4(p + int2(-1, 0), 0, 0)).x;
		float right = pressureTexture.Load(int4(p + int2(1, 0), 0, 0)).x;
		float top = pressureTexture.Load(int4(p + int2(0, -1), 0, 0)).x;
		float bottom = pressureTexture.Load(int4(p + int2(0, 1), 0, 0)).x;
		velocity.x -= (right - left) * halfDeltaX;
		velocity.z -= (bottom - top) * halfDeltaX;
	}

	velocity.y = 0.0;
	velocity.w = 0.0;
	velocityOutput[cell] = velocity;
}

/*
Legacy pressure-gradient projection:

float3 grad = float3(a.x - b.x, c.z - d.z, 0) * halfDeltaX;
velocityTexture[idx] -= grad.xzy;
*/
