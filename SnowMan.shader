Shader "Raymarching/SnowMan"
{
    Properties
    {
        [Header(Base)]_BaseColor("Base Color", Color) = (1, 1, 1, 1)
        _AccessoriesColor("Accessories Color", Color) = (1, 1, 1, 1)
        _NoseColor("Nose Color", Color) = (1, 1, 1, 1)
        _HandColor("Hand Color", Color) = (1, 1, 1, 1)
        _TearColor("Tear Color", Color) = (1, 1, 1, 1)
        _ShyColor("Shy Color", Color) = (1, 1, 1, 1)
        _Intensity ("Intensity", Range (0.0, 10)) = 1.0
        // _Scale ("Scale", Range (0, 1)) = 1

        [Header(Rendering)][Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 1
        _MaxStep ("Max step", Range (0, 120)) = 64

        [Header(Lighting)]_Diffuse("Diffuse", Range(0 , 1)) = 0.5
        _Specular("Specular", Range( 0 , 1)) = 0.1
        _RimOffset("Rim Offset", Range( 0 , 1)) = 0.2
        _RimPower("Rim Power", Range( 0 , 1)) = 0.2
        _RimColor("Rim Color", Color) = (1, 1, 1, 1)

        [Header(Blend Shapes)]_Mouth ("口 上下", Range (0, 100)) = 0
        _EyePattern1 ("ジト目", Range (0, 100)) = 0
        _EyePattern2 ("><", Range (0, 100)) = 0
        _EyeTear ("涙", Range (0, 100)) = 0
        _Shy ("頬染め", Range (0, 100)) = 0

        [Header(Raymarching)][KeywordEnum(Normal, Enchanced)] _RaymarchingType ("Raymarching Type", Float) = 0
    }

    SubShader
    {
        Cull [_CullMode]
        Tags
        {
            "RenderType" = "Opaque" "DisableBatching" = "True"
        }

        LOD 100


        CGINCLUDE
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

        uniform float4 _BaseColor;
        uniform float4 _AccessoriesColor;
        uniform float4 _NoseColor;
        uniform float4 _HandColor;
        uniform float4 _TearColor;
        uniform float4 _ShyColor;
        uniform float _Intensity;
        uniform float _Scale;
        uniform float _MaxStep;
        uniform float _Mouth;
        uniform float _EyePattern1;
        uniform float _EyePattern2;
        uniform float _EyeTear;
        uniform float _Shy;
        uniform int _CullMode;

        uniform float _Specular;
        uniform float _Diffuse;
        uniform float _RimOffset;
        uniform float _RimPower;
        uniform float4 _RimColor;

        float sphere( float3 p, float s )
        {
            return length(p)-s;
        }

        float cylinder( float3 p, float2 h )
        {
            float2 d = abs(float2(length(p.xz),p.y)) - h;
            return min(max(d.x,d.y),0.0) + length(max(d,0.0));
        }

        float sdCone( float3 p, float3 c )
        {
            float2 q = float2( length(p.xz), p.y );
            float d1 = -q.y-c.z;
            float d2 = max( dot(q,c.xy), q.y);
            return length(max(float2(d1,d2),0.0)) + min(max(d1,d2), 0.);
        }

        float sdCapsule(float3 p, float3 a, float3 b, float r1, float r2 )
        {
            float3 pa = p - a, ba = b - a;
            float h = saturate(dot(pa, ba) / dot(ba, ba));
            return length(pa - ba * h ) - lerp(r1, r2, h);
        }

        float box(float3 pos, float3 size)
        {
            return length(max(abs(pos) - size, 0.0));
        }

        float roundBox(float3 pos, float3 size, float round)
        {
            return length(max(abs(pos) - size * 0.5, 0.0)) - round;
        }

        float2 smin(float2 a, float2 b , float s)
        {
            float h = saturate(0.5 + 0.5 * (b - a) / s);
            return lerp(b, a, h) - h * (1.0 - h) * s;
        }

        float3 rotateZ(float3 pos, float th)
        {
            return mul(float3x3(cos(th), -sin(th), 0.0, sin(th), cos(th), 0.0, 0.0, 0.0, 1.0), pos);
        }

        float2 distanceFunction(float3 pos)
        {
            pos.y += 0.5;

            // body
            float2 res = float2(sphere(pos - float3( 0.0,0.25, 0.0), 0.25 ), 2.0);

            // head
            res = smin(res, float2(sphere(pos - float3( 0.0,0.6, 0.0), 0.15), 2.0), 0);

            // hat
            res = smin(res, float2(cylinder(pos - float3( 0.0, 0.76, 0.0), float2(0.1 ,0.08 )), 8.0), 0);
            res = smin(res, float2(cylinder(pos - float3( 0.0, 0.72, 0.0), float2(0.15,0.005)), 8.0), 0);

            //hand right
            res = smin(res, float2(sdCapsule(pos, float3( 0.14, 0.40, 0.12), float3( 0.20, 0.45, 0.20), 0.01, 0.01),    0.0), 0);
            res = smin(res, float2(sdCapsule(pos, float3( 0.185, 0.44, 0.18), float3( 0.20, 0.48, 0.17), 0.01, 0.01),   0.0), 0.001);

            res = smin(res, float2(sdCapsule(pos, float3( -0.14, 0.40, 0.12), float3( -0.20, 0.45, 0.20), 0.01, 0.01),  0.0), 0);
            res = smin(res, float2(sdCapsule(pos, float3( -0.185, 0.44, 0.18), float3( -0.20, 0.48, 0.17), 0.01, 0.01), 0.0), 0.001);

            // eyes
            float eyeLeft1  = sphere(pos - float3( -0.05, 0.65, 0.14), 0.015);
            float eyeLeft2  = roundBox(rotateZ(pos - float3( -0.05, 0.66, 0.14), 0.7), float3(0.04, 0.01, 0.01), 0.005);
            eyeLeft2  = smin(eyeLeft2, roundBox(rotateZ(pos - float3( -0.05, 0.64, 0.14), -0.7), float3(0.04, 0.01, 0.01), 0.005), 0.0);
            float eyeLeft  = roundBox(pos - float3( -0.05, 0.65, 0.14), float3(0.04, 0.01, 0.01), 0.005);


            float eyeRight1 = sphere(pos - float3(  0.05, 0.65, 0.14), 0.015);
            float eyeRight2  = roundBox(rotateZ(pos - float3( 0.05, 0.66, 0.14), -0.7), float3(0.04, 0.01, 0.01), 0.005);
            eyeRight2  = smin(eyeRight2, roundBox(rotateZ(pos - float3( 0.05, 0.64, 0.14), 0.7), float3(0.04, 0.01, 0.01), 0.005), 0.0);
            float eyeRight  = roundBox(pos - float3(  0.05, 0.65, 0.14), float3(0.04, 0.01, 0.01), 0.005);

            float el = lerp(lerp(eyeLeft1, eyeLeft2, _EyePattern2 / 100), lerp(eyeLeft, eyeLeft2, _EyePattern2 / 100), _EyePattern1 / 100.0);
            float er = lerp(lerp(eyeRight1, eyeRight2, _EyePattern2 / 100), lerp(eyeRight, eyeRight2, _EyePattern2 / 100), _EyePattern1 / 100.0);

            res = smin(res, float2(el, 8.0), 0);
            res = smin(res, float2(er, 8.0), 0);

            // tear
            res = smin(res, float2(sphere(pos - float3( -0.065, 0.63, 0.14 * (_EyeTear / 100)), 0.01), 16.0), 0);
            res = smin(res, float2(sphere(pos - float3(  0.065, 0.63, 0.14 * (_EyeTear / 100)), 0.01), 16.0), 0);

            // shy
            float d = (_Shy / 100);
            res = smin(res, float2(roundBox(pos - float3( -0.07, 0.61, 0.135), float3(0.04 * d, 0.01 * d, 0.01 * d), 0.005 * d), 32.0), 0);
            res = smin(res, float2(roundBox(pos - float3(  0.07, 0.61, 0.135), float3(0.04 * d, 0.01 * d, 0.01 * d), 0.005 * d), 32.0), 0);

            // mouth
            float mouthUpDown = _Mouth * 5.0 / 10000;
            res = smin(res, float2(sphere(pos - float3(  0.07, 0.575 - mouthUpDown, 0.14 - mouthUpDown / 2.0), 0.015), 8.0), 0);
            res = smin(res, float2(sphere(pos - float3( -0.07, 0.575 - mouthUpDown, 0.14 - mouthUpDown / 2.0), 0.015), 8.0), 0);
            res = smin(res, float2(sphere(pos - float3( -0.03, 0.55 , 0.14), 0.015), 8.0), 0);
            res = smin(res, float2(sphere(pos - float3(  0.03, 0.55 , 0.14), 0.015), 8.0), 0);

            // nose
            res = smin(res, float2(sphere(pos - float3(  0.0, 0.615, 0.16), 0.03), 4.0), 0);

            // buttons
            res = smin(res, float2(sphere(pos - float3(  0.0,0.45, 0.16), 0.031), 8.0), 0);
            res = smin(res, float2(sphere(pos - float3(  0.0,0.35, 0.22), 0.031), 8.0), 0);
            res = smin(res, float2(sphere(pos - float3(  0.0,0.25, 0.25), 0.031), 8.0), 0);

            return res;
        }

        float3 setNormal(float3 pos, float eps)
        {
            const float2 k = float2(1.0, -1.0);

            return normalize(k.xyy * distanceFunction(pos + k.xyy * eps).x +
                                k.yyx * distanceFunction(pos + k.yyx * eps).x +
                                k.yxy * distanceFunction(pos + k.yxy * eps).x +
                                k.xxx * distanceFunction(pos + k.xxx * eps).x);

            // float3 ddxVec = normalize(ddx(pos));
            // float3 ddyVec = normalize(ddy(pos));
            // float3 normal = cross(ddyVec, ddxVec);

            // return normal;
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

        float softShadow(float3 pos, float3 rd, float mint, float tmax )
        {
            float res = 1.0;
            float t = mint;
            float ph = 1e10;

            for( int i=0; i<32; i++ )
            {
                float h = distanceFunction(pos).x;
                res = min( res, 10.0*h/t );
                t += h;
                if( res<0.0001 || t>tmax ) break;

            }
            return clamp( res, 0.0, 1.0 );
        }

        float3 lighting(float3 pos, float3 direction, float3 color, float distance)
        {
            float3 normal = setNormal(pos, 0.0001);

            float3 rightPos = _WorldSpaceLightPos0 - pos;
            #if defined(LIGHTMAP_ON) && UNITY_VERSION < 560
                float3 worldLightDir = 1;
            #else
                float3 worldLightDir = normalize(UnityWorldSpaceLightDir(rightPos));
            #endif

            float3 lightDirection = normalize(worldLightDir);
            float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb;

            // float occ = lerp(calculateAO(pos, normal), 1.0, 0.8);
            float diffuse = saturate(dot(normal, lightDirection));
            // diffuse *= softShadow(pos, direction, 0.02, 2.5) * 0.9;

            float rim = pow(saturate(_RimOffset + dot(normal, direction)), _RimPower);
            float3 hal = normalize(lightDirection - direction);
            float specular = pow(saturate(dot(normal, hal)), 16.0);

            float3 lightingResult = float3 (0.0, 0.0, 0.0);
            lightingResult += _Diffuse * diffuse;
            lightingResult += _Specular * specular * diffuse;
            lightingResult += _RimColor * rim * 0.8;
            lightingResult += 0.5 * ambientLight;
            // lightingResult += 0.4 * occ;
            // lightingResult *= _LightColor0.rgb;
            //lightingResult += ShadeSH9(half4(float3(0, 1, 0), 1.0)) + (DecodeHDR(UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, normalize((float4( _WorldSpaceCameraPos , 0.0 ) - mul(unity_ObjectToWorld, float4( 0,0,0,1)))).xyz, 7), unity_SpecCube0_HDR) * 0.02);

            return saturate(lightingResult + color * 0.5);
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
            fixed4 color : SV_Target;
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

 #ifdef _RAYMARCHINGTYPE_NORMAL
            float t_min = 0.001;
            float t_max = 10.0;
            float t = t_min;
            float2 distance = float2(0.0, 0.0);

            float maxStep = _MaxStep;
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
                float3 col0 = lighting(posOnRay, ray_center.dir, _BaseColor, distance);
                float3 col1 = lighting(posOnRay, ray_center.dir, _AccessoriesColor, distance);
                float3 col2 = lighting(posOnRay, ray_center.dir, _NoseColor, distance);
                float3 col3 = lighting(posOnRay, ray_center.dir, _HandColor, distance);
                float3 col4 = lighting(posOnRay, ray_center.dir, _TearColor, distance);
                float3 col5 = lighting(posOnRay, ray_center.dir, _ShyColor, distance);

                o.color = distance.y >= 32.0 ?
                    fixed4(col5 * _Intensity, 1) :
                    distance.y >= 16.0 ?
                    fixed4(col4 * _Intensity, 1) :
                    distance.y >= 8.0 ?
                    fixed4(col1* _Intensity, 1) :
                    distance.y >= 4.0 ?
                    fixed4(col2 * _Intensity, 1) :
                    distance.y >= 2.0 ?
                    fixed4(col0 * _Intensity, 1) :
                    fixed4(col3 * _Intensity, 1);
            }
#else
                float t = 0.0;
                float2 distance = float2(0.0, 0.0);

                float maxStep = _MaxStep;

                for(int i = 0; i < maxStep; ++i)
                {
                    distance = distanceFunction(posOnRay);

                    t += distance.x;
                    posOnRay = ray_center.org + t * ray_center.dir;
                }

                gbuffer_out o;
                if(abs(distance.x) >= 0.001) discard;
                else
                {
                    float3 col0 = lighting(posOnRay, ray_center.dir, _BaseColor, distance);
                    float3 col1 = lighting(posOnRay, ray_center.dir, _AccessoriesColor, distance);
                    float3 col2 = lighting(posOnRay, ray_center.dir, _NoseColor, distance);
                    float3 col3 = lighting(posOnRay, ray_center.dir, _HandColor, distance);
                    float3 col4 = lighting(posOnRay, ray_center.dir, _TearColor, distance);
                    float3 col5 = lighting(posOnRay, ray_center.dir, _ShyColor, distance);

                    o.color = distance.y >= 32.0 ?
                        fixed4(col5 * _Intensity, 1) :
                        distance.y >= 16.0 ?
                        fixed4(col4 * _Intensity, 1) :
                        distance.y >= 8.0 ?
                        fixed4(col1* _Intensity, 1) :
                        distance.y >= 4.0 ?
                        fixed4(col2 * _Intensity, 1) :
                        distance.y >= 2.0 ?
                        fixed4(col0 * _Intensity, 1) :
                        fixed4(col3 * _Intensity, 1);
                }
#endif


            o.depth = computeDepth(posOnRay);
            return o;
        }
        ENDCG

        Pass
        {
            Name "ForwardBase"
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma target 4.6
            #pragma vertex vert
            #pragma fragment frag
            #pragma fragmentoption ARB_precision_hint_fastest


            ENDCG
        }

        // Pass
        // {
        //     Name "ForwardAdd"
        //     Tags { "LightMode" = "ForwardAdd" }

        //     CGPROGRAM
        //     #pragma target 4.6
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #pragma multi_compile_fwdadd
        //     #pragma fragmentoption ARB_precision_hint_fastest


        //     ENDCG
        // }

        // Pass
        // {
        //     Name "ShadowCaster"
        //     Tags { "LightMode" = "ShadowCaster" }

        //     CGPROGRAM
        //     #pragma target 4.6
        //     #pragma vertex vert
        //     #pragma fragment frag
        //     #pragma multi_compile_shadowcaster
        //     #pragma multi_compile UNITY_PASS_SHADOWCASTER
        //     #pragma fragmentoption ARB_precision_hint_fastest


        //     ENDCG
        // }
    }
    // Fallback "Diffuse"
}
