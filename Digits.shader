Shader "Digits"
{

    Properties
    {
        [Enum(UnityEngine.Rendering.CullMode)]_CullMode("Cull Mode", Int) = 1
        _Scale ("Scale", Range (0, 1)) = 0.6
        _ScaleY ("Scale Y", Range (0, 1)) = 1.0
        [HDR]_ForegroundColor("Foreground Color", Color) = (1, 0.2, 0, 0)
        [HDR]_BackgroundColor("Background Color", Color) = (0, 0, 0, 0)
        _AnyValue ("Any Value", float) = 0.00000
        _IntegerPart("Scale", Range (0, 5)) = 5
        _DecimalPart("Scale", Range (0, 5)) = 5
        [KeywordEnum(FPS, Time, X, Y, Z, Any)] _DisplayMode ("Display mode", Float) = 0
        //Properties
    }

    SubShader
    {
        Cull [_CullMode]

        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _DISPLAYMODE_FPS _DISPLAYMODE_TIME _DISPLAYMODE_X _DISPLAYMODE_Y _DISPLAYMODE_Z _DISPLAYMODE_ANY

            #include "UnityCG.cginc"
            #include "Font.cginc"

            //Variables
            uniform int _CullMode;
            uniform int _DisplayMode;
            uniform int _IntegerPart;
            uniform int _DecimalPart;
            uniform float _AnyValue;
            uniform float _ScaleY;
            uniform float4 _ForegroundColor;
            uniform float4 _BackgroundColor;

            float rand(float2 co)
            {
                return frac(sin(dot(co.xy ,float2(12.9898, 78.233))) * 43758.5453);
            }

            float digit(float2 origin, float d, float2 uv)
            {
                uv -= origin;
                d = floor(d);
                float dist = 1e6;

                if(d == 0.0) return ch_0(uv);
                if(d == 1.0) return ch_1(uv);
                if(d == 2.0) return ch_2(uv);
                if(d == 3.0) return ch_3(uv);
                if(d == 4.0) return ch_4(uv);
                if(d == 5.0) return ch_5(uv);
                if(d == 6.0) return ch_6(uv);
                if(d == 7.0) return ch_7(uv);
                if(d == 8.0) return ch_8(uv);
                if(d == 9.0) return ch_9(uv);
                return dist;
            }

            float char(float2 origin, float d, float2 uv)
            {
                uv -= origin;
                d = floor(d);
                float dist = 1e6;

                if(d == 0.0) return ch_sharp(uv);
                if(d == 1.0) return ch_dollar(uv);
                if(d == 2.0) return ch_asterisk(uv);
                if(d == 3.0) return ch_equal(uv);
                if(d == 4.0) return ch_colon(uv);
                if(d == 5.0) return ch_E(uv);
                if(d == 6.0) return ch_X(uv);
                if(d == 7.0) return ch_Y(uv);
                if(d == 8.0) return ch_Z(uv);
                if(d == 9.0) return ch_9(uv);
                return dist;
            }

            //Distance to a number
            float dfNumber(float2 origin, float num, float2 uv)
            {
                uv -= origin;
                float dist = 1e6;
                float offs = 0.0;

                float2 digitSpacing = float2(1.1, 1.6) * _Scale;

                float integerPart = _IntegerPart;
                float decimalPart = _DecimalPart;

                for(float i = integerPart;i > -decimalPart; i--)
                {
                    float d = fmod(abs(num) / pow(10.0,i),10.0);

                    float2 pos = digitSpacing * float2(offs,0.0);

                    if(i == 0.0)
                    {
                        dist = min(dist, drawCircle(float2(offs + 0.9,0.1) * 1.1, 0.04, uv));
                    }

                    if(num < 0)
                    {
                        dist = min(dist, drawLine(float2(-0.7, 0.6), float2(-0.1, 0.6), uv));
                    }

                    if(abs(num) > pow(10.0,i) || i == 0.0)
                    {
                        dist = min(dist, digit(pos, d, uv));
                        offs++;
                    }
                }
                return dist;
            }


            //Length of a number in digits
            float numberLength(float n)
            {
                return floor(max(log(n) / log(10.0), 0.0) + 1.0) + 2.0;
            }

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.pos = v.vertex.xyz;
                o.uv = v.uv;
                return o;
            }


            float4 frag(v2f i) : SV_Target
            {
                float3 worldPos = mul(unity_ObjectToWorld, float4(0,0,0,1)).xyz;

                float2 aspect = 1 / 1;
                float2 uv = i.uv / 1 - aspect / 2.0;
                uv.y = uv.y * _ScaleY;
                uv.x += 0.07;

                float n = 0.0;
                float prefix = 0.0;

                #ifdef _DISPLAYMODE_FPS
                    n = unity_DeltaTime.y;
                    prefix = 4.0;
                #elif _DISPLAYMODE_TIME
                    n = _Time.y;
                    prefix = 5.0;
                #elif _DISPLAYMODE_X
                    n = worldPos.x;
                    prefix = 2.0;
                #elif _DISPLAYMODE_Y
                    n = worldPos.y;
                    prefix = 2.0;
                #elif _DISPLAYMODE_Z
                    n = worldPos.z;
                    prefix = 2.0;
                #elif _DISPLAYMODE_ANY
                    n = _AnyValue;
                    prefix = 0.0;
                #endif

                float nsize =  numberLength(abs(n));

                float2 digitSpacing = float2(1.1, 1.6) * _Scale;

                float2 pos = -digitSpacing * float2(nsize, 1.0) / 2.0;

                float dist = 1e6;

                #ifdef _DISPLAYMODE_FPS
                    dist = min(dist, dfNumber(pos, n, uv));
                #elif _DISPLAYMODE_TIME
                    dist = min(dist, dfNumber(pos, n, uv));
                #elif _DISPLAYMODE_X
                    dist = min(dist, ch_X(uv - float2(pos.x - 0.1, pos.y)));
                    dist = min(dist, ch_colon(uv - float2(pos.x - 0.0, pos.y)));
                    dist = min(dist, dfNumber(pos - float2(pos.x - 0.0, 0.0), n, uv));
                #elif _DISPLAYMODE_Y
                    dist = min(dist, ch_Y(uv - float2(pos.x - 0.1, pos.y)));
                    dist = min(dist, ch_colon(uv - float2(pos.x - 0.0, pos.y)));
                    dist = min(dist, dfNumber(pos - float2(pos.x - 0.0, 0.0), n, uv));
                #elif _DISPLAYMODE_Z
                    dist = min(dist, ch_Z(uv - float2(pos.x - 0.1, pos.y)));
                    dist = min(dist, ch_colon(uv - float2(pos.x - 0.0, pos.y)));
                    dist = min(dist, dfNumber(pos - float2(pos.x - 0.0, 0.0), n, uv));
                #elif _DISPLAYMODE_ANY
                    dist = min(dist, dfNumber(pos, n, uv));
                #endif



                float3 color = _BackgroundColor;

                float shade = 0.0;

                shade = 0.004 / (dist);

                color += _ForegroundColor * shade;

                float grid = 0.5 - max(abs(mod(uv.x * 64.0, 1.0) - 0.5), abs(mod(uv.y * 64.0, 1.0) - 0.5));
                float s = smoothstep(0.0, 64.0 / 1, grid);
                color *= 0.25 + float3(s, s, s) * 0.75;

                return saturate(float4(color, 1.0 ));

            }
            ENDCG
        }
    }
}