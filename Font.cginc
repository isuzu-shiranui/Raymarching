//  フォント

#ifndef FONT_INCLUDED // 条件コンパイル
#define FONT_INCLUDED // 重複定義回避

uniform float _Scale; // 大きさ

float mod(float x, float y) 
{
    return frac(abs(x / y)) * abs(y);
}

// Distance to a line segment,
float drawLine(float2 start, float2 end, float2 uv)
{
    start *= _Scale;
    end *= _Scale;
    
    float2 l = end - start;
    float f = dot(uv - start, l) / dot(l, l);
    return distance(start + l * saturate(f), uv);
}

// Distance to the edge of a circle.
float drawCircle(float2 origin, float radius, float2 uv)
{
    origin *= _Scale;
    radius *= _Scale;
    
    return abs(length(uv - origin) - radius);
}

// Distance to an arc.
float drawArc(float2 origin, float start, float sweep, float radius, float2 uv)
{
    const float pi = atan2(1.5, 1.0) * 4.0;
    const float tau = atan(1.0) * 8.0;

    origin *= _Scale;
    radius *= _Scale;
    
    uv -= origin;
    float2x2 arc = float2x2(cos(start), sin(start), -sin(start), cos(start));
    uv = mul(uv, arc);

    float offs = ((sweep / 2) - pi);
    float ang = mod(atan2(uv.y, uv.x) - offs, tau) + offs;
    ang = clamp(ang, min(0.0, sweep), max(0.0, sweep));
    
    return distance(radius * float2(cos(ang), sin(ang)), uv);
}

float ch_screamer(float2 uv)
{
    float dist = drawLine(float2(0.500, 1.500), float2(0.500, 0.500), uv);
    return min(dist, drawCircle(float2(0.500, 0.200), 0.080, uv));
}

float ch_doubleQuotation(float2 uv)
{
    float dist = drawLine(float2(0.400, 1.500), float2(0.400, 1.200), uv);
    return min(dist, drawLine(float2(0.600, 1.500), float2(0.600, 1.200), uv));
}

float ch_sharp(float2 uv)
{
    float dist = drawLine(float2(0.200, 0.900), float2(0.800, 0.900), uv);
    dist = min(dist, drawLine(float2(0.200, 0.600), float2(0.800, 0.600), uv));
    dist = min(dist, drawLine(float2(0.300, 0.400), float2(0.500, 1.100), uv));
    return min(dist, drawLine(float2(0.500, 0.400), float2(0.700, 1.100), uv));
}

float ch_dollar(float2 uv)
{
    float dist = drawLine(float2(0.500, 1.500), float2(0.500, 0.000), uv);
    dist = min(dist,  drawArc(float2(0.500, 1.000), 5.400, 1.800, 0.400, uv));
    dist = min(dist,  drawArc(float2(0.326, 1.100), 3.550, 1.400, 0.200, uv));
    dist = min(dist,  drawArc(float2(0.500, 0.500), 2.400, 2.000, 0.400, uv));
    dist = min(dist,  drawArc(float2(0.676, 0.400), 0.550, 1.400, 0.200, uv));
    return min(dist, drawLine(float2(0.219, 0.931), float2(0.807, 0.551), uv));
}

float ch_asterisk(float2 uv)
{
    float dist = drawLine(float2(0.500, 1.000), float2(0.500, 0.500), uv);
    dist = min(dist, drawLine(float2(0.200, 0.750), float2(0.800, 0.750), uv));
    dist = min(dist, drawLine(float2(0.300, 0.900), float2(0.700, 0.600), uv));
    return min(dist, drawLine(float2(0.300, 0.600), float2(0.700, 0.900), uv));
}

float ch_equal(float2 uv)
{
    float dist = drawLine(float2(0.200, 0.900), float2(0.800, 0.900), uv);
    return min(dist, drawLine(float2(0.200, 0.600), float2(0.800, 0.600), uv));
}

float ch_0(float2 uv)
{
    float dist = drawLine(float2(1.000, 1.000), float2(1.000, 0.500), uv);
    dist = min(dist, drawLine(float2(0.000, 1.000), float2(0.000, 0.500), uv));
    dist = min(dist,  drawArc(float2(0.500, 1.000), 0.000, 3.142, 0.500, uv));
    return min(dist,  drawArc(float2(0.500, 0.500), 3.142, 3.142, 0.500, uv));
}

float ch_1(float2 uv)
{
    return drawLine(float2(0.500, 1.500), float2(0.500, 0.000), uv);
}

float ch_2(float2 uv)
{
    float dist = drawLine(float2(1.000, 0.000), float2(0.000, 0.000), uv);
    dist = min(dist, drawLine(float2(0.388, 0.561), float2(0.840, 0.735), uv));
    dist = min(dist,  drawArc(float2(0.500, 1.000), 0.000, 3.142, 0.500, uv));
    dist = min(dist,  drawArc(float2(0.700, 1.000), 1.074, 1.209, 0.300, uv));
    return min(dist,  drawArc(float2(0.600, 0.000), 4.352, 1.209, 0.600, uv));
}

float ch_3(float2 uv)
{
    float dist = drawLine(float2(0.000, 1.500), float2(1.000, 1.500), uv);
    dist = min(dist, drawLine(float2(1.000, 1.500), float2(0.500, 1.000), uv));
    dist = min(dist,  drawArc(float2(0.500, 0.500), 1.570, 3.712, 0.500, uv));
    return min(dist,  drawArc(float2(0.500, 0.500), 3.000, 3.712, 0.500, uv));
}

float ch_4(float2 uv)
{
    float dist = drawLine(float2(0.700, 1.500), float2(0.000, 0.500), uv);
    dist = min(dist, drawLine(float2(0.000, 0.500), float2(1.000, 0.500), uv));
    return min(dist, drawLine(float2(0.700, 1.200), float2(0.700, 0.000), uv));
}

float ch_5(float2 uv)
{
    float dist = drawLine(float2(1.000, 1.500), float2(0.300, 1.500), uv);
    dist = min(dist, drawLine(float2(0.300, 1.500), float2(0.200, 0.900), uv));
    dist = min(dist,  drawArc(float2(0.500, 0.500), 0.930, 5.356, 0.500, uv));
    return min(dist,  drawArc(float2(0.500, 0.500), 3.000, 3.712, 0.500, uv));
}

float ch_6(float2 uv)
{
    float dist = drawLine(float2(0.067, 0.750), float2(0.500, 1.500), uv);
    return min(dist, drawCircle(float2(0.500, 0.500), 0.500, uv));
}

float ch_7(float2 uv)
{
    float dist = drawLine(float2(0.000, 1.500), float2(1.000, 1.500), uv);
    return min(dist, drawLine(float2(1.000, 1.500), float2(0.500, 0.000), uv));
}

float ch_8(float2 uv)
{
    float dist = drawCircle(float2(0.500, 0.400), 0.400, uv);
    return min(dist, drawCircle(float2(0.500, 1.150), 0.350, uv));
}

float ch_9(float2 uv)
{
    float dist = drawLine(float2(0.933, 0.750), float2(0.500, 0.000), uv);
    return min(dist, drawCircle(float2(0.500, 1.000), 0.500, uv));
}

float ch_colon(float2 uv)
{
    float dist = drawCircle(float2(0.500, 0.875), 0.080, uv);
    return min(dist, drawCircle(float2(0.500, 0.375), 0.080, uv));
}

float ch_E(float2 uv)
{
    float dist = drawLine(float2(0.000, 1.500), float2(1.000, 1.500), uv);
    dist = min(dist, drawLine(float2(0.000, 0.760), float2(1.000, 0.760), uv));
    dist = min(dist, drawLine(float2(0.000, 0.000), float2(1.000, 0.000), uv));
    return min(dist, drawLine(float2(0.000, 1.500), float2(0.000, 0.000), uv));
}

float ch_X(float2 uv)
{
    float dist = drawLine(float2(0.800, 1.500), float2(0.200, 0.000), uv);
    return min(dist, drawLine(float2(0.200, 1.500), float2(0.800, 0.000), uv));
}

float ch_Y(float2 uv)
{
    float dist = drawLine(float2(0.800, 1.500), float2(0.500, 0.750), uv);
    dist = min(dist, drawLine(float2(0.200, 1.500), float2(0.500, 0.750), uv));
    return min(dist, drawLine(float2(0.500, 0.750), float2(0.500, 0.000), uv));
}

float ch_Z(float2 uv)
{
    float dist = drawLine(float2(0.800, 1.500), float2(0.200, 0.000), uv);
    dist = min(dist, drawLine(float2(0.200, 0.000), float2(0.800, 0.000), uv));
    return min(dist, drawLine(float2(0.800, 1.500), float2(0.200, 1.500), uv));
}

float ch_i(float2 uv)
{
    float dist = drawLine(float2(0.500, 0.400), float2(0.500, 0.000), uv);
    return min(dist, drawCircle(float2(0.500, 0.500), 0.040, uv));
}

float ch_m(float2 uv)
{
    float dist = drawLine(float2(0.000, 0.600), float2(0.000, 0.000), uv);
    dist = min(dist, drawLine(float2(0.500, 0.300), float2(0.500, 0.000), uv));
    dist = min(dist, drawLine(float2(1.000, 0.300), float2(1.000, 0.000), uv));
    dist = min(dist,  drawArc(float2(0.250, 0.300), 0.000, 3.142, 0.250, uv));
    return min(dist,  drawArc(float2(0.750, 0.300), 0.000, 3.142, 0.250, uv));
}

float ch_o(float2 uv)
{
    return drawCircle(float2(0.500, 0.250), 0.250, uv);
}

#endif