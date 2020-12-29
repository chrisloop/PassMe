TEXTURE2D(_CameraDepthTexture);
SAMPLER(sampler_CameraDepthTexture);

TEXTURE2D(_CameraNormalsTexture);
SAMPLER(sampler_CameraNormalsTexture);

TEXTURE2D(_CameraOpaqueTexture);
SAMPLER(sampler_CameraOpaqueTexture);
float4 _CameraOpaqueTexture_TexelSize;

void Effect_float(float2 ScreenPosition, float3 OutlineColor, float OutlineThickness, float OutlineDepthMultiplier, float OutlineDepthBias, float OutlineNormalMultiplier, float OutlineNormalBias, out float3 Out, out float3 Normal, out float Depth)
{
    float3 Color = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, ScreenPosition); // r alpha map for detail, b SSAO

    // sample distance
    float halfScaleFloor = floor(OutlineThickness * 0.5);
    float halfScaleCeil = ceil(OutlineThickness * 0.5);
    float2 Texel = (1.0) / float2(_CameraOpaqueTexture_TexelSize.z, _CameraOpaqueTexture_TexelSize.w);

    // offset sample positions
    float2 uvSamples[4];
    uvSamples[0] = ScreenPosition - float2(Texel.x, Texel.y) * halfScaleFloor;
    uvSamples[1] = ScreenPosition + float2(Texel.x, Texel.y) * halfScaleCeil;
    uvSamples[2] = ScreenPosition + float2(Texel.x * halfScaleCeil, -Texel.y * halfScaleFloor);
    uvSamples[3] = ScreenPosition + float2(-Texel.x * halfScaleFloor, Texel.y * halfScaleCeil);


    // base (center) values
    Depth = SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, ScreenPosition).r;
    Normal = (SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, ScreenPosition));

    float depthDifference = 0;
    float normalDifference = 0;

    for(int i = 0; i < 4 ; i++)
    {
        // depth
        depthDifference = depthDifference + Depth - SAMPLE_TEXTURE2D(_CameraDepthTexture, sampler_CameraDepthTexture, uvSamples[i]).r;

        // normals
        float3 normalDelta = Normal - SAMPLE_TEXTURE2D(_CameraNormalsTexture, sampler_CameraNormalsTexture, uvSamples[i]);
        normalDelta = normalDelta.r + normalDelta.g + normalDelta.b;
        normalDifference = normalDifference + normalDelta;
    
        // detail from opaque pass
       // detailDifference0 = detailDifference0 + Detail.r - SAMPLE_TEXTURE2D(_CameraColorTexture, sampler_CameraColorTexture, uvSamples[i]).r;
    }

    // depth sensitivity
    depthDifference = depthDifference * OutlineDepthMultiplier;
    depthDifference = saturate(depthDifference);
    depthDifference = pow(depthDifference, OutlineDepthBias);
    float DepthOutline = depthDifference;

    // normal sensitivity
    normalDifference = normalDifference * OutlineNormalMultiplier;
    normalDifference = saturate(normalDifference);
    normalDifference = pow(normalDifference, OutlineNormalBias);
    float NormalOutline = normalDifference;

    float Outline = max(DepthOutline, NormalOutline);

    Out = lerp(Color, OutlineColor, Outline);
    //Out = Color;
}