Texture3D<float4> velocityTexture : register(t0);
RWTexture3D<float> vorticityTexture : register(u0);

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

	float curl = 0.0;
	if (cell.x > 0 && cell.x < texResolution.x - 1 &&
		cell.y > 0 && cell.y < texResolution.y - 1)
	{
		int2 p = int2(cell.xy);
		float leftZ = velocityTexture.Load(int4(p + int2(-1, 0), 0, 0)).z;
		float rightZ = velocityTexture.Load(int4(p + int2(1, 0), 0, 0)).z;
		float topX = velocityTexture.Load(int4(p + int2(0, -1), 0, 0)).x;
		float bottomX = velocityTexture.Load(int4(p + int2(0, 1), 0, 0)).x;
		curl = ((leftZ - rightZ) - (topX - bottomX)) * halfDeltaX;
	}

	vorticityTexture[cell] = curl;
}

/*
Legacy vorticity computation:

float vort = ((a.y - b.y) - (c.x - d.x)) * halfDeltaX;
vorticityTexture[idx] = vort;
*/
