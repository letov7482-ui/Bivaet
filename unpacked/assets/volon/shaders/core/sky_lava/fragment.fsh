#version 150

in vec3 Direction;
in vec4 vColor;

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;

out vec4 OutColor;

float hash3(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 x) {
    vec3 i = floor(x);
    vec3 f = fract(x);
    f = f * f * (3.0 - 2.0 * f);
    float a = mix(hash3(i), hash3(i + vec3(1,0,0)), f.x);
    float b = mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), f.x);
    float c = mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), f.x);
    float d = mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), f.x);
    return mix(mix(a, b, f.y), mix(c, d, f.y), f.z);
}

float fbm(vec3 p) {
    float v = 0.0, a = 0.55;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.05 + vec3(5.2, 1.3, 3.7);
        a *= 0.48;
    }
    return v;
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.05));
    float t = Time * 0.18;

    // --- лавовое поле ---
    vec3 p = d * 2.8;
    // Завихрения
    vec3 q = vec3(
        fbm(p + vec3(0.0, t, 0.5)),
        fbm(p + vec3(2.0, t * 0.9, 1.8)),
        fbm(p + vec3(3.1, 1.5, t * 1.1))
    );
    float lava = fbm(p + q * 1.4);

    // --- цветовой градиент ---
    // Чёрная корка → оранжевый жар → белое ядро
    vec3 cBlack  = vec3(0.01, 0.005, 0.003);
    vec3 cDark   = mix(vec3(0.12, 0.02, 0.0), accent * 0.3, 0.4);
    vec3 cOrange = mix(vec3(0.9, 0.25, 0.0), accent, 0.35);
    vec3 cYellow = mix(vec3(1.0, 0.75, 0.1), accent * 1.5, 0.2);
    vec3 cWhite  = vec3(1.0, 0.95, 0.8);

    // Многоуровневый тонкий маппинг
    vec3 color;
    color = mix(cBlack,  cDark,   smoothstep(0.0,  0.28, lava));
    color = mix(color,   cOrange, smoothstep(0.28, 0.52, lava));
    color = mix(color,   cYellow, smoothstep(0.52, 0.72, lava));
    color = mix(color,   cWhite,  smoothstep(0.72, 0.90, lava));

    // --- прожилки трещин ---
    float cracks = abs(fbm(p * 2.2 + vec3(t * 0.4, 0.0, t * 0.3)) - 0.5);
    float crackMask = smoothstep(0.15, 0.0, cracks);
    vec3 crackGlow = mix(cOrange * 2.5, cYellow * 3.0, lava);
    color += crackGlow * crackMask * (0.6 + lava * 0.8);

    // --- атмосферное вертикальное распределение ---
    // Снизу — горячее (лава), сверху — тёмное дымное небо
    float up = d.y * 0.5 + 0.5;
    vec3 skyDark = vec3(0.015, 0.007, 0.0) + accent * 0.08;
    vec3 skyMid  = mix(vec3(0.18, 0.05, 0.0), accent * 0.4, 0.3);
    vec3 sky = mix(skyMid, skyDark, smoothstep(0.3, 1.0, up));
    color = mix(color, sky, smoothstep(0.0, 0.7, up));

    // --- горизонтальное свечение (раскалённый горизонт) ---
    float horizGlow = exp(-abs(d.y) * 2.5) * 0.6;
    color += mix(cOrange, cYellow, lava) * horizGlow;

    // --- дым/пепел сверху ---
    if (d.y > 0.1) {
        float ashNoise = fbm(d * 5.5 + vec3(t * 0.3, 0.0, t * 0.2));
        float ash = smoothstep(0.45, 0.65, ashNoise) * smoothstep(0.1, 0.6, d.y);
        vec3 ashColor = mix(vec3(0.06, 0.04, 0.04), vec3(0.15, 0.10, 0.08), ashNoise);
        color = mix(color, ashColor, ash * 0.55);
    }

    // --- светлячки-искры ---
    vec3 sp = d * 95.0 + vec3(0.0, t * 12.0, 0.0);
    vec3 sc = floor(sp);
    vec3 sf = fract(sp) - 0.5;
    float sh = hash3(sc);
    if (sh > 0.978) {
        float spark = (1.0 - smoothstep(0.0, 0.06, length(sf)));
        float flicker = 0.4 + 0.6 * sin(Time * 8.0 + sh * 33.0);
        color += mix(cOrange, cYellow, sh) * spark * flicker * 3.0;
    }

    // --- тонмэппинг ---
    color = color / (1.0 + color * 0.35);
    color = pow(max(color, vec3(0.0)), vec3(0.88));

    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
