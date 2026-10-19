Texture3D<float> vorticityTexture : register(t0);
Texture3D<float4> velocityInput : register(t1);
RWTexture3D<float4> velocityOutput : register(u0);

uniform uint2 texResolution;
uniform float halfDeltaX;
uniform float vorticityConfinementScale;
uniform float timeSinceLast;

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

	float4 velocity = velocityInput.Load(int4(cell, 0));
	if (cell.x > 0 && cell.x < texResolution.x - 1 &&
		cell.y > 0 && cell.y < texResolution.y - 1)
	{
		int2 p = int2(cell.xy);
		float left = abs(vorticityTexture.Load(int4(p + int2(-1, 0), 0, 0)));
		float right = abs(vorticityTexture.Load(int4(p + int2(1, 0), 0, 0)));
		float top = abs(vorticityTexture.Load(int4(p + int2(0, -1), 0, 0)));
		float bottom = abs(vorticityTexture.Load(int4(p + int2(0, 1), 0, 0)));
		float2 gradient = float2((right - left), (bottom - top)) * halfDeltaX;
		float gradientLength = length(gradient);
		if (gradientLength > 1e-6)
		{
			float2 normal = gradient / gradientLength;
			float curl = vorticityTexture.Load(int4(p, 0, 0));
			float2 force = float2(-normal.y * curl, normal.x * curl);
			velocity.xz += force * (vorticityConfinementScale * timeSinceLast);
		}
	}

	velocity.y = 0.0;
	velocity.w = 0.0;
	velocityOutput[cell] = velocity;
}

/*
Legacy in-place vorticity confinement:

float3 force = float3(abs(c) - abs(d), 0.0f, abs(b) - abs(a)) * halfDeltaX;
force *= vorticityConfinementScale * vorticityTexture[idx] * float3(1, 0, -1);
velocityTexture[idx] += force * timeSinceLast;
*/
