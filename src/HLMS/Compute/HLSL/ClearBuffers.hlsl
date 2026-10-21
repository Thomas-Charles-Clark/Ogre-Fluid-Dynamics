struct Particle
{
	float ink;
	float4 colour;
	float3 velocity;
	float inkLifetime;
}; 

RWStructuredBuffer<Particle> inputUavBuffer		: register(u0);
RWTexture3D<float4> inkTexture					: register(u1);
RWTexture3D<float4> velocityTexture				: register(u2);
RWTexture3D<float4> divergenceTexture			: register(u3);
RWTexture3D<float4> pressureTexture				: register(u4);

uniform uint2 texResolution;
uniform float timeSinceLast;
uniform float velocityDissipationConstant; 
uniform float inkDissipationConstant;
uniform float pressureDissipationConstant;

[numthreads(@value( threads_per_group_x ), @value( threads_per_group_y ), @value( threads_per_group_z ))]
void main
(
    uint3 gl_LocalInvocationID : SV_GroupThreadID,
    uint3 gl_GlobalInvocationID : SV_DispatchThreadId
)
{
    if (gl_GlobalInvocationID.x < texResolution.x &&
        gl_GlobalInvocationID.y < texResolution.y)
        //&& gl_GlobalInvocationID.z < texResolution.z)
    {
        uint rwIdx = gl_GlobalInvocationID.y * texResolution.x + gl_GlobalInvocationID.x;
		
        float4 zero = float4(0, 0, 0, 0);
		
        float4 currentInk = inkTexture[gl_GlobalInvocationID];
		
        if (currentInk.w > 0)
        {
            currentInk.w -= timeSinceLast;
        }
        else
        {
            if (dot(currentInk.xyz, currentInk.xyz) > 0.0001f)
            {
                currentInk.w = 0.0f;
            }
            else
            {
                currentInk = zero;
            }
        }
        
        inkTexture[gl_GlobalInvocationID] = currentInk;
        pressureTexture[gl_GlobalInvocationID] = zero;
        divergenceTexture[gl_GlobalInvocationID] = zero;
    }
}