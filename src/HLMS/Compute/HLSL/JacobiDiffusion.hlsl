Texture3D<float4> velocityCurrent : register(t0);
Texture3D<float4> velocityOriginal : register(t1);
RWTexture3D<float4> velocityOutput : register(u0);

uniform uint2 texResolution;
uniform float timeSinceLast;
uniform float halfDeltaX;
uniform float viscosity;

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

	int2 maxCell = int2(texResolution) - 1;
	int2 p = int2(cell.xy);
	float4 result = velocityCurrent.Load(int4(p, 0, 0));

	bool left = p.x == 0;
	bool right = p.x == maxCell.x;
	bool top = p.y == 0;
	bool bottom = p.y == maxCell.y;

	if (left || right || top || bottom)
	{
		if (left || right)
		{
			int2 neighbour = int2(left ? 1 : maxCell.x - 1, clamp(p.y, 1, maxCell.y - 1));
			float4 edge = velocityCurrent.Load(int4(neighbour, 0, 0));
			result.x = -edge.x;
			result.z = edge.z;
		}
		if (top || bottom)
		{
			int2 neighbour = int2(clamp(p.x, 1, maxCell.x - 1), top ? 1 : maxCell.y - 1);
			float4 edge = velocityCurrent.Load(int4(neighbour, 0, 0));
			if (!(left || right))
				result.x = edge.x;
			result.z = -edge.z;
		}
		velocityOutput[cell] = result;
		return;
	}

	if (viscosity <= 0.0 || timeSinceLast <= 0.0)
	{
		velocityOutput[cell] = velocityOriginal.Load(int4(p, 0, 0));
		return;
	}

	float4 center = velocityOriginal.Load(int4(p, 0, 0));
	float4 leftValue = velocityCurrent.Load(int4(p + int2(-1, 0), 0, 0));
	float4 rightValue = velocityCurrent.Load(int4(p + int2(1, 0), 0, 0));
	float4 topValue = velocityCurrent.Load(int4(p + int2(0, -1), 0, 0));
	float4 bottomValue = velocityCurrent.Load(int4(p + int2(0, 1), 0, 0));

	float deltaX = 0.5 / max(halfDeltaX, 1e-6);
	float a = viscosity * timeSinceLast / (deltaX * deltaX);
	float4 resultInterior = (center + a * (leftValue + rightValue + topValue + bottomValue)) /
		(1.0 + 4.0 * a);
	resultInterior.y = 0.0;
	resultInterior.w = 0.0;
	velocityOutput[cell] = resultInterior;
}

/*
Legacy in-place Jacobi diffusion:

float alpha = halfDeltaX * halfDeltaX / (viscosity * timeSinceLast);
float rBeta = 1 / (4 + alpha);
float4 beta = velocityTexture.Load(float4(idx.xyz, 0));
float4 v = (a + b + c + d + alpha * beta) * rBeta;
velocityTexture[idx] = float4(v.xyz, 0);
*/
