RWTexture3D<float4> velocityTexture : register(u0);

uniform uint2 texResolution;

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

	bool left = cell.x == 0;
	bool right = cell.x == texResolution.x - 1;
	bool top = cell.y == 0;
	bool bottom = cell.y == texResolution.y - 1;
	if (!(left || right || top || bottom))
		return;

	int2 p = int2(cell.xy);
	int2 maxCell = int2(texResolution) - 1;
	int2 xNeighbour = int2(left ? 1 : maxCell.x - 1, clamp(p.y, 1, maxCell.y - 1));
	int2 yNeighbour = int2(clamp(p.x, 1, maxCell.x - 1), top ? 1 : maxCell.y - 1);
	float4 current = velocityTexture[cell];
	float xNormal = (left || right) ?
		-velocityTexture[uint3(xNeighbour, cell.z)].x : current.x;
	float zNormal = (top || bottom) ?
		-velocityTexture[uint3(yNeighbour, cell.z)].z : current.z;
	current.x = xNormal;
	current.z = zNormal;
	current.y = 0.0;
	current.w = 0.0;
	velocityTexture[cell] = current;
}

/*
Legacy boundary implementation:

velocityTexture[gl_GlobalInvocationID] = -1 * velocityTexture[neighbourIdx];
pressureTexture[gl_GlobalInvocationID] = pressureTexture[neighbourIdx];
inkTexture[gl_GlobalInvocationID] = inkTexture[neighbourIdx];
*/
