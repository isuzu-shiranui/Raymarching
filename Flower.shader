Shader "Raymarching/Flower"
{
    Properties
    {
    }

    SubShader
    {
        Tags
        {
            "Queue" = "Geometry"
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

            #define PI 3.14159265359

            // simple hash function
            float hash(float3 uv) {
                float f = frac(sin(dot(uv, float3(.08123898, .0131233, .0432234))) * 1e5);
                return f;
            }

            // 3d noise function (linear interpolation between hash of integer bounds)
            float noise(float3 uv) {
                float3 fuv = floor(uv);
                float4 cell0 = float4(
                    hash(fuv + float3(0, 0, 0)),
                    hash(fuv + float3(0, 1, 0)),
                    hash(fuv + float3(1, 0, 0)),
                    hash(fuv + float3(1, 1, 0))
                );
                float2 axis0 = lerp(cell0.xz, cell0.yw, frac(uv.y));
                float val0 = lerp(axis0.x, axis0.y, frac(uv.x));
                float4 cell1 = float4(
                    hash(fuv + float3(0, 0, 1)),
                    hash(fuv + float3(0, 1, 1)),
                    hash(fuv + float3(1, 0, 1)),
                    hash(fuv + float3(1, 1, 1))
                );
                float2 axis1 = lerp(cell1.xz, cell1.yw, frac(uv.y));
                float val1 = lerp(axis1.x, axis1.y, frac(uv.x));
                return lerp(val0, val1, frac(uv.z));
            }

            // fracional brownian motion
            float fbm(float3 uv) {
                float f = 0.;
                float r = 1.;
                for (int i = 0; i < 4; ++i) {
                    f += noise((uv + 10.) * r) / (r *= 2.);
                }
                return f / (1. - 1. / r);
            }

            // rotate 2d space with given angle
            void tRotate(inout float2 p, float angel) {
                float s = sin(angel), c = cos(angel);
                p = mul(float2x2(c, -s, s, c), p);
            }

            // divide 2d space into s chunks around the center
            void tFan(inout float2 p, float s) {
                float k = s / PI / 2.;
                tRotate(p, -floor((atan2(p.y, p.x)) * k + .5) / k);
            }

            // box distance
            float sdBox(float3 p, float3 r) {
                p = abs(p) - r;
                return min(max(p.x, max(p.y, p.z)), 0.) + length(max(p, 0.));
            }

            // sphere distance
            float sdSphere(float3 p, float r) {
                return length(p) - r;
            }

            // cylinder distance r - radius, l - height
            float sdCylinder(float3 p, float r, float l) {
                p.xy = float2(abs(p.y) - l, length(p.xz) - r);
                return min(max(p.x, p.y), 0.) + length(max(p.xy, 0.));
            }

            // union
            float opU(float a, float b) {
                return min(a, b);
            }

            // smooth union
            float opSU(float a, float b, float k)
            {
                float h = clamp(.5 + .5 * (b - a) / k, 0., 1.);
                return lerp(b, a, h) - k * h * (1. - h);
            }

            // one big petal distance
            float sdPetal(float3 p) {
                float h = .0;
                float r = .02;
                return opU(sdBox(p, float3(.2, h, .2)), sdCylinder(p + float3(.2, 0, .2), .4, h)) - r * (.8 - length(p.xz));
            }

            // distance to 3 of those petals
            float sd3Petals(float3 p) {
                tFan(p.xz, 3.);
                p.z *= 1.5;
                p.x -= .2;
                tRotate(p.xz, -PI * 3. / 4.);
                return sdPetal(p) / 2.;
            }

            // two layers of petals on top of each othere
            float sdAllPetals(float3 p)
            {
                #if NOISY_PETALS
                float3 q = p * 10. / length(p.xz * 5.);
                p.y += fbm(q) * .1 - .05;
                #endif
                p.y -= .05;
                float curve = dot(p.xz, p.xz) * 2.;
                p.y -= (curve * exp(-curve)) * .5;
                float d = sd3Petals(p);
                tRotate(p.xz, PI / 3.);
                p.y += .02;
                d = opU(d, sd3Petals(p));
                return d;
            }

            // distance to one of those little yellow things in the middle
            float sdStyle(float3 p) {
                return sdCylinder(p, 0., .2) - .015;
            }

            // all of those little yellow things together
            float sdPistil(float3 p) {
                tRotate(p.xz, -length(p.xz) * 4.);
                float d = sdStyle(p);
                tFan(p.xz, 6.);
                tRotate(p.xy, .5);
                d = opU(d, sdStyle(p));
                tFan(p.xz, 6.);
                tRotate(p.xy, .25);
                d = opU(d, sdStyle(p));
                return d;
            }

            // distance to one of those long tentacle things
            float sdFilament(float3 p) {
                float d = sdCylinder(p, 0., .4) - .005;
                p.x = abs(p.x) - .015 + p.y * .1 -.04;
                return opU(d, sdCylinder(p - float3(0, .4, 0), .0, .02) - .015);
            }

            // distance to all of those long tentacle things
            float sdStamen(float3 p) {
                p.y -= dot(p, p) * .2;
                tRotate(p.xz, p.y * .5 + .1);
                tFan(p.xz, 6.);
                tRotate(p.xy, .8);
                tRotate(p.xz, PI / 3.);
                tFan(p.xz, 3.);
                tRotate(p.xy, .25);
                float d = sdFilament(p);
                return d;
            }

            float2 smin(float2 a, float2 b , float s)
            {
                float h = saturate(0.5 + 0.5 * (b - a) / s);
                return lerp(b, a, h) - h * (1.0 - h) * s;
            }

            float2 distanceFunction(float3 pos)
            {
                float2 d = float2(sdAllPetals(pos), 2.0);
                d = smin(d, float2(sdPistil(pos), 4.0), 0);
                d = smin(d, float2(sdStamen(pos), 6.0), 0);

                return d;
            }

            float3 _texture(float3 p, float mat) {
                float3 q = p * 10. / length(p.xz * 4.);
                float2 r = p.xz;
                tFan(r, 6.);
                r.y *= 2.;
                float petalGrad = smoothstep(.2, .4, distance(r, float2(.5, 0)));
                float3 t =
                        mat >= 6.0 ?
                            lerp(float3(.7, .7, 2.), float3(2, 1.5, 2), smoothstep(.35, .42, length(p))) * 0.3:
                        mat >= 4.0 ?
                            lerp(float3(2, 2, .7), float3(5, 5, 3), smoothstep(.18, .25, length(p))) * fbm(p * 100.) :
                        mat >= 2.0 ?
                            float3(.8, 1, 2.)
                                - smoothstep(.0, .5, abs(.5 - fbm(q + fbm(q * 10.)))) * .5
                                - fbm(q * 10.) * .5
                                + dot(p.xz, p.xz) * .1
                                - petalGrad * .4 :
                            float3(0.0, 0.0, 0.0);
                return t;
            }

            float3 setNormal(float3 pos, float eps)
            {
                float3 ddxVec = normalize(ddx(pos));
                float3 ddyVec = normalize(ddy(pos));
                return cross(ddyVec, ddxVec);
            }

            float3 lighting(float3 pos, float3 direction, int material)
            {
                float3 normal = setNormal(pos, 0.0001);

                float3 rightPos = _WorldSpaceLightPos0 - pos;
                #if defined(LIGHTMAP_ON) && UNITY_VERSION < 560
                    float3 worldLightDir = 1;
                #else
                    float3 worldLightDir = normalize(UnityWorldSpaceLightDir(rightPos));
                #endif

                float3 lightDirection = normalize(worldLightDir);
                // diffuse light
                float diffuse = max(0., dot(lightDirection, normal));

                // specular light
                float specular = pow(max(0., dot(reflect(-lightDirection, normal), -direction)), 4.);
                float3 ambientLight = UNITY_LIGHTMODEL_AMBIENT.rgb;

                float3 tex = _texture(pos, material);

                float3 color = (tex * ((2. - ambientLight) * .5 + (specular + diffuse) * ambientLight));
                return saturate(color);
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

            gbuffer_out frag (v2f i)
            {
                Ray ray_center;
                ray_center.org = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1)).xyz;
                ray_center.dir = normalize(i.pos - ray_center.org);

                float t = 0.0;
                float steps = 0.0;
                float2 distance = float2(0.0, 0.0);
                float3 posOnRay = ray_center.org;

                float maxStep = 64;

                for(int i = 0; i < maxStep; ++i)
                {
                    distance = distanceFunction(posOnRay);

                    steps++;

                    t += distance.x;
                    posOnRay = ray_center.org + t * ray_center.dir;

                    if(t > 25565) break;
                }

                gbuffer_out o;

                if(abs(distance.x) < 0.001 && t > 0.01)
                {
                    float4 color = float4(lighting(posOnRay, ray_center.dir, distance.y), 0.0);
                    o.color = color;
                }
                else discard;

                o.depth = computeDepth(posOnRay);
                return o;
            }
            ENDCG
        }
    }
}
