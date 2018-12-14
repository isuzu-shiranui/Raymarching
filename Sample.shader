Shader "Raymarching/Sample"
{
    Properties
    {
        _FirstColor("First Color", Color) = (1, 1, 1, 0)
        _SecondColor("Second Color", Color) = (1, 1, 1, 0)
    }

    SubShader
    {
        Cull Off

        Tags
        {
            "RenderType" = "Transparent"
            "Queue" = "Transparent+0"
            "IgnoreProjector" = "True"
            "IsEmissive" = "true"
        }

        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest
            #pragma multi_compile_shadowcaster

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            uniform float4 _FirstColor;
            uniform float4 _SecondColor;

            float sphere( float3 p, float s )
            {
                return length(p)-s;
            }

            float box(float3 pos, float3 size)
            {
                return length(max(abs(pos) - size, 0.0));
            }

            float2 smin(float2 a, float2 b , float s)
            {
                float h = saturate(0.5 + 0.5 * (b - a) / s);
                return lerp(b, a, h) - h * (1.0 - h) * s;
            }

            float2 distanceFunction(float3 pos)
            {
                pos.x += 0.2;
                float2 d1 = float2(sphere(pos, 0.1), 0.0);

                pos.x -= 0.4;
                float2 d2 = float2(box(pos, 0.1), 1.0);

                return smin(d1, d2, 0.0);
            }

            float3 setNormal(float3 pos)
            {
                const float3 d = float3(0.0001, 0.00, 0.00);

                float diffx = distanceFunction(pos + d.xyy) - distanceFunction(pos - d.xyy);
                float diffy = distanceFunction(pos + d.yxy) - distanceFunction(pos - d.yxy);
                float diffz = distanceFunction(pos + d.yyx) - distanceFunction(pos - d.yyx);

                return normalize(float3(diffx, diffy, diffz));
            }

            float calculateAO(float3 pos, float3 normal)
            {
                float sca = 4., occ = 0.0;
                for(int i = 1; i < 6; i++)
                {
                    float hr = float(i) * .125/5.;
                    float dd = distanceFunction(pos + hr * normal);
                    occ += (hr - dd) * sca;
                    sca *= .75;
                }

                return saturate(1. - occ);
            }

            float softShadow(float3 rayOrg, float3 rayDir, float dstance, float end, float k)
            {
                float shade = 1.0;
                const int maxIterationsShad = 24;

                float dist = .001 * (1. + dstance * .05);
                float stepDist = end / float(maxIterationsShad);

                for (int i=0; i < maxIterationsShad; i++)
                {
                    float h = distanceFunction(rayOrg + rayDir * dist);
                    shade = min(shade, k*h/dist);
                    dist += clamp(h, 0.01, 0.25);

                    if (h<0.0001 || dist > end) break;
                }

                return min(max(shade, 0.) + .1, 1.);
            }

            float3 lighting(float3 pos, float3 color, float distance)
            {
                float3 lightingResult = color;
                float3 normal = setNormal(pos);
                float ao = calculateAO(pos, normal);

                float3 rightPos = _WorldSpaceLightPos0 - pos;

                #if defined(LIGHTMAP_ON) && UNITY_VERSION < 560
                    float3 worldLightDir = 1;
                #else
                    float3 worldLightDir = normalize(UnityWorldSpaceLightDir(rightPos));
                #endif

                float NdotL = dot(normal, worldLightDir);
                #if defined(LIGHTMAP_ON) && UNITY_VERSION < 560
                    float4 lightColor = 0;
                #else
                    float4 lightColor = _LightColor0;
                #endif

                float3 lightDirection = normalize(worldLightDir);

                float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float lightAtten = 1. / (1. + lightDirection * .05 + lightDirection * lightDirection * 0.025);

                float shadow = softShadow(pos + normal * .0015, rightPos, distance, lightDirection, 8.);

                float diffuse = max(dot(rightPos, normal), .0);
                diffuse = pow(diffuse, 4.) * 2.;

                lightingResult *= (diffuse + .25);
                lightingResult += color * float3(1, 0.6, 0.2).zyx * 0.25;
                lightingResult *= lightColor + ambientLight;

                return lightingResult;
            }

            float computeDepth(float3 pos)
            {
                float4 vpPos = UnityObjectToClipPos(float4(pos, 1.0));
                #if UNITY_UV_STARTS_AT_TOP
                    return vpPos.z / vpPos.w;
                #else
                    return (vpPos.z / vpPos.w) * 0.5 + 0.5;
                #endif
            }

#pragma region struct
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 pos : TEXCOORD1;
            };

            struct Ray
            {
                float3 org;
                float3 dir;
            };

            struct gbuffer_out
            {
                half4 color : SV_Target;
                float depth : SV_Depth;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex.xyz;
                return o;
            }
#pragma endregion struct

            gbuffer_out frag (v2f i)
            {
                Ray ray_center;
                ray_center.org = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
                ray_center.dir = normalize(i.pos - ray_center.org);

                float3 posOnRay = ray_center.org;

                float t_min = 0.001;
                float t_max = 10.0;
                float t = t_min;
                float2 distance = float2(0.0, 0.0);

                float maxStep = 32.0;
                float omega = 1.3;
                float candidate_error = 1e32;
                float candidate_t = t_min;
                float previousRadius = 0.0;
                float stepLength = 0.0;
                float pixelRadius = 0.001;
                float functionSign = distanceFunction(posOnRay).x < 0.0 ? -1.0 : 1.0;

                for(int i = 0; i < maxStep; ++i)
                {
                    distance = distanceFunction(ray_center.org + t * ray_center.dir);
                    float signedRadius = functionSign * distance.x;
                    float radius = abs(signedRadius);
                    bool sorFail = omega > 1.0 && (radius + previousRadius) < stepLength;

                    if (sorFail)
                    {
                        stepLength -= omega * stepLength;
                        omega = 1.0;
                    }
                    else
                    {
                        stepLength = signedRadius * omega;
                    }

                    previousRadius = radius;
                    float error = radius / t;
                    if (!sorFail && error < candidate_error)
                    {
                        candidate_t = t;
                        candidate_error = error;
                    }
                    if (!sorFail && error < pixelRadius || t > t_max) break;

                    t += stepLength;
                }

                posOnRay += ray_center.dir * candidate_t;

                gbuffer_out o;
                if ((t > t_max || candidate_error > pixelRadius)) discard;
                else
                {
                    float3 col0 = lighting(posOnRay, _FirstColor, distance);
                    float3 col1 = lighting(posOnRay, _SecondColor, distance);

                    o.color = distance.y > 0.0 ?
                        float4(saturate(sqrt(saturate(col0))), 1) :
                        float4(saturate(sqrt(saturate(col1))), 1);
                }

                o.depth = computeDepth(posOnRay);
                return o;
            }
            ENDCG
        }
    }
}
