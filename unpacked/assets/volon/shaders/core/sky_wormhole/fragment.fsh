#version 150

in vec3 Direction;
in vec4 vColor;

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;

out vec4 OutColor;

float hash(float n) {
    return fract(sin(n) * 43758.5453);
}

float hash3(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(hash3(i + vec3(0,0,0)), hash3(i + vec3(1,0,0)), f.x);
    float b = mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x);
    float c = mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x);
    float dd = mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x);
    return mix(mix(a,b,f.y), mix(c,dd,f.y), f.z);
}

// Кольца туннеля
float ring(float r, float radius, float width) {
    return smoothstep(width, 0.0, abs(r - radius));
}

vec3 rotY(vec3 v, float a) {
    float c = cos(a), s = sin(a);
    return vec3(v.x*c - v.z*s, v.y, v.x*s + v.z*c);
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.05));

    float t = Time * 0.4;

    // Полярные координаты вокруг оси тоннеля (ось Z)
    float angle = atan(d.y, d.x);
    float dist  = length(d.xy);

    // Угол в плоскости XY указывает на центр туннеля
    float tunnelFacing = 1.0 - smoothstep(0.0, 0.3, dist);

    // --- фон — тёмная глубина ---
    vec3 bg = vec3(0.005, 0.002, 0.015) + accent * 0.04;
    bg = mix(bg, accent * 0.1, smoothstep(0.8, 0.0, dist));

    // --- спиральные кольца туннеля ---
    // Пространство туннеля: r - расстояние от центра, phi - угол, z - глубина
    float phi     = angle + t * 0.8;                     // вращение
    float depth   = (1.0 / max(dist, 0.001)) * 0.1 - t; // "уход в даль"
    float spiral  = fract(phi / (3.14159 * 2.0) * 8.0 + depth * 2.0); // спираль

    // Кольца
    float rings = 0.0;
    for (int i = 0; i < 6; i++) {
        float fi = float(i);
        float radius = 0.05 + fi * 0.09;
        float w = 0.008 + 0.003 * noise(vec3(angle * 2.0, depth + fi, t));
        rings += ring(dist, radius, w) * (0.5 + 0.5 * sin(fi * 1.3 + t * 2.0 + spiral * 6.28));
    }

    // Закрученные линии по спирали
    float spiralLines = smoothstep(0.12, 0.0, abs(fract(spiral + noise(vec3(d * 3.0 + t * 0.5))) - 0.5));
    float spiralMask  = smoothstep(0.5, 0.05, dist) * spiralLines;

    // --- цвета ---
    float depthFade   = smoothstep(0.0, 0.6, tunnelFacing);
    vec3  innerGlow   = mix(accent, vec3(1.0), 0.6);
    vec3  midGlow     = mix(accent, vec3(0.2, 1.0, 0.9), 0.5);
    vec3  outerColor  = mix(accent * 0.5, vec3(0.5, 0.0, 1.0), 0.4);

    float colorShift  = noise(vec3(angle * 1.5, depth * 0.8, t * 0.3));
    vec3  ringColor   = mix(outerColor, midGlow, colorShift);
    ringColor = mix(ringColor, innerGlow, smoothstep(0.25, 0.05, dist));

    // Центральный свет — ослепительное ядро тоннеля
    float core      = exp(-dist * 7.0) * 3.5;
    vec3  coreColor = mix(innerGlow * 2.0, vec3(1.0, 0.95, 0.85) * 3.0, core * 0.5);

    // Туманность вокруг
    float nebula = noise(rotY(d, t * 0.15) * 2.5) * 0.5;
    nebula += noise(rotY(d, -t * 0.09) * 4.5) * 0.25;
    vec3  nebulaColor = mix(accent * 0.3, vec3(0.1, 0.0, 0.3), 0.6) * nebula;

    // Звёзды
    float starMask = smoothstep(0.3, 0.7, dist);
    float stars = 0.0;
    vec3 sp = d * 220.0;
    vec3 sc = floor(sp);
    float sh = hash3(sc);
    if (sh > 0.988) {
        vec3 sf = fract(sp) - 0.5;
        stars = (1.0 - smoothstep(0.0, 0.04, length(sf))) * (0.6 + 0.4 * sin(t * 4.0 + sh * 50.0));
        stars *= (sh - 0.988) / 0.012;
    }

    // --- собираем ---
    vec3 color = bg;
    color += nebulaColor;
    color += ringColor  * rings * (1.5 + depthFade);
    color += midGlow    * spiralMask * 0.8;
    color += coreColor  * core;
    color += vec3(stars) * mix(vec3(1.0), accent, 0.3) * starMask;

    color = color / (1.0 + color * 0.38);
    color = pow(max(color, vec3(0.0)), vec3(0.88));

    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
