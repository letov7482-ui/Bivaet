#version 150

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
in vec3 Direction;
in vec4 vColor;
out vec4 OutColor;

float hash31(vec3 p) {
    return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453123);
}

float noise3(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    vec3 w = f * f * (3.0 - 2.0 * f);
    float n000 = hash31(i);
    float n100 = hash31(i + vec3(1, 0, 0));
    float n010 = hash31(i + vec3(0, 1, 0));
    float n110 = hash31(i + vec3(1, 1, 0));
    float n001 = hash31(i + vec3(0, 0, 1));
    float n101 = hash31(i + vec3(1, 0, 1));
    float n011 = hash31(i + vec3(0, 1, 1));
    float n111 = hash31(i + vec3(1, 1, 1));
    float x00 = mix(n000, n100, w.x);
    float x10 = mix(n010, n110, w.x);
    float x01 = mix(n001, n101, w.x);
    float x11 = mix(n011, n111, w.x);
    return mix(mix(x00, x10, w.y), mix(x01, x11, w.y), w.z);
}

float fbm3(vec3 p) {
    float s = 0.0;
    float a = 0.5;
    for (int i = 0; i < 3; i++) {
        s += a * noise3(p);
        p *= 2.07;
        a *= 0.5;
    }
    return s;
}

void main() {
    vec3 rd = normalize(Direction);
    float y = rd.y;
    float t = Time;
    float night = 0.0;
    float breathe = 0.93 + 0.07 * sin(t * 0.26);
    vec3 rsum = rd + vec3(sin(t * 2.15 + dot(rd, vec3(1.0, 0.55, 0.35)) * 12.0), cos(t * 1.95 + dot(rd, vec3(-0.45, 1.0, 0.5)) * 11.5), sin(t * 2.35 + dot(rd, vec3(0.25, -0.4, 1.0)) * 13.0)) * (0.0055 * smoothstep(0.2, -0.38, y));
    vec3 rs = normalize(rsum);
    vec3 drift = vec3(t * 0.042, t * 0.024, t * 0.033);

    vec3 zenith = mix(vec3(0.04, 0.26, 0.78), vec3(0.015, 0.04, 0.14), night);
    vec3 horizon = mix(vec3(0.62, 0.86, 1.0), vec3(0.05, 0.07, 0.16), night);
    vec3 grass = mix(vec3(0.1, 0.42, 0.24), vec3(0.02, 0.05, 0.09), night);
    float gradMix = smoothstep(-0.38, 0.68, y);
    vec3 skyBase = mix(horizon, zenith, gradMix);
    float nearGround = (1.0 - gradMix) * smoothstep(-0.55, 0.18, y);
    skyBase = mix(skyBase, mix(skyBase, grass, 0.4), nearGround * 0.55);

    vec3 p = rs * 1.85 + drift;
    float boil = noise3(p * 2.35 + vec3(t * 0.11));
    float clouds = fbm3(p + vec3(boil * 0.5, -boil * 0.38, boil * 0.22)) * 0.7 + noise3(p * 1.35 - drift * 0.55 + vec3(17.3, 84.1, 31.7)) * 0.3;
    clouds = pow(clamp(clouds, 0.0, 1.0), 0.82);
    float puffCore = smoothstep(0.5, 0.84, clouds);
    float puffEdge = smoothstep(0.36, 0.9, clouds) * (1.0 - puffCore) * 0.45;
    vec3 col = mix(skyBase, vec3(1.0, 0.99, 0.97), puffCore);
    col = mix(col, mix(skyBase, vec3(1.0, 0.99, 0.97), 0.88), puffEdge);
    col += vec3(1.0, 0.92, 0.75) * puffEdge * 0.12 * breathe;

    float gold = smoothstep(0.52, 0.8, noise3(rs * 1.25 + drift * 0.85) * 0.55 + noise3(rs * 2.75 - vec3(t * 0.05, t * 0.03, t * 0.04)) * 0.45);
    gold *= smoothstep(-0.15, 0.58, y);
    col += mix(vec3(1.0, 0.843, 0.0), Accent, 0.2) * gold * 0.5 * breathe;
    col = clamp(col * 1.02, 0.0, 1.0);
    OutColor = vec4(col, 1.0) * ColorModulator * vColor;
}
