#version 150

uniform vec2 texelSize;
uniform vec3 color;
uniform vec3 color2;
uniform float time;
uniform float speed;
uniform float intensity;
uniform float scale;

in vec2 TexCoord;
out vec4 OutColor;

float hash(vec2 p) {
    p = fract(p * vec2(127.1, 311.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += noise(p) * a;
        p = p * 2.03 + vec2(5.2, 1.3);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = TexCoord;

    float t = time * speed * 0.18;

    // Вертикальный градиент — плавное затухание без резкой границы
    float verticalFade = smoothstep(0.0, 0.85, uv.y);

    // Горизонтальные волны ауроры
    vec2 flow = uv * scale * vec2(2.5, 1.2);
    float wave1 = fbm(flow + vec2(t * 0.7, t * 0.3));
    float wave2 = fbm(flow * 1.4 - vec2(t * 0.5, t * 0.6) + vec2(3.1, 7.4));
    float wave3 = fbm(flow * 0.8 + vec2(t * 0.9, -t * 0.4) + vec2(8.2, 2.1));

    // Вертикальные полосы ауроры
    float stripe = abs(sin((uv.x * 3.5 + wave1 * 1.8) * 3.14159 + t * 0.4));
    stripe = pow(1.0 - stripe, 3.5);

    float stripe2 = abs(sin((uv.x * 2.2 - wave2 * 1.4) * 3.14159 - t * 0.55 + 1.1));
    stripe2 = pow(1.0 - stripe2, 4.0);

    float aurora = clamp(stripe * 0.65 + stripe2 * 0.45 + wave3 * 0.15, 0.0, 1.0);
    aurora *= verticalFade;

    // Цвет — градиент между color и color2 по горизонтали + волны
    float colorMix = clamp(wave1 * 0.6 + uv.x * 0.4 + stripe2 * 0.3, 0.0, 1.0);
    vec3 auroraColor = mix(color, color2, colorMix);

    // Мерцание
    float flicker = 0.92 + 0.08 * sin(time * speed * 1.7 + uv.x * 4.2);

    float alpha = aurora * intensity * flicker;
    if (alpha < 0.005) discard;

    OutColor = vec4(auroraColor, clamp(alpha, 0.0, 0.9));
}
