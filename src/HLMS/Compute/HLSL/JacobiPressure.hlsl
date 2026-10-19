Texture3D<float4> pressureCurrent : register(t0);
Texture3D<float4> divergenceTexture : register(t1);
RWTexture3D<float4> pressureOutput : register(u0);

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
	int2 maxCell = int2(texResolution) - 1;
	if (p.x == 0 || p.x == maxCell.x || p.y == 0 || p.y == maxCell.y)
	{
		int2 interior = clamp(p, int2(1, 1), maxCell - 1);
		pressureOutput[cell] = pressureCurrent.Load(int4(interior, 0, 0));
		return;
	}

	float left = pressureCurrent.Load(int4(p + int2(-1, 0), 0, 0)).x;
	float right = pressureCurrent.Load(int4(p + int2(1, 0), 0, 0)).x;
	float top = pressureCurrent.Load(int4(p + int2(0, -1), 0, 0)).x;
	float bottom = pressureCurrent.Load(int4(p + int2(0, 1), 0, 0)).x;
	float divergence = divergenceTexture.Load(int4(p, 0, 0)).x;
	float deltaX = 0.5 / max(halfDeltaX, 1e-6);
	float pressure = (left + right + top + bottom -
		divergence * deltaX * deltaX) * 0.25;
	pressureOutput[cell] = float4(pressure, pressure, pressure, 0.0);
}

/*
Legacy in-place pressure solve:

float alpha = -halfDeltaX * halfDeltaX;
float rBeta = 0.25;
float3 beta = divergenceRead.SampleLevel(TextureSampler, idx / width, 1.0);
float4 p = (a + b + c + d + alpha * beta.x) * rBeta;
pressureTexture[idx] = p;
*/
