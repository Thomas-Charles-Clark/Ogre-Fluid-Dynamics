Texture3D<float4> velocityTexture : register(t0);
RWTexture3D<float4> divergenceTexture : register(u0);

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
	float divergence = 0.0;
	if (p.x > 0 && p.x < int(texResolution.x) - 1 &&
		p.y > 0 && p.y < int(texResolution.y) - 1)
	{
		float left = velocityTexture.Load(int4(p + int2(-1, 0), 0, 0)).x;
		float right = velocityTexture.Load(int4(p + int2(1, 0), 0, 0)).x;
		float top = velocityTexture.Load(int4(p + int2(0, -1), 0, 0)).z;
		float bottom = velocityTexture.Load(int4(p + int2(0, 1), 0, 0)).z;
		divergence = ((right - left) + (bottom - top)) * halfDeltaX;
	}

	divergenceTexture[cell] = float4(divergence, 0.0, 0.0, 0.0);
}

/*
Legacy sampled divergence:

float3 div = float3(((a.x - b.x) + (c.z - d.z)) * halfDeltaX, 0, 0);
divergenceTexture[idx] = div;
*/
