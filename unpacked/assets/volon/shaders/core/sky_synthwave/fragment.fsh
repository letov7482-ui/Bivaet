#version 150

in vec3 Direction;
in vec4 vColor;

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;

out vec4 OutColor;

float hash(float n) {
    return fract(sin(n) * 43758.5453123);
}

float hash2(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Нарисовать линию сетки
float gridLine(float v, float width) {
    return smoothstep(width, 0.0, abs(fract(v + 0.5) - 0.5));
}

vec3 starLayer(vec3 d, float density, float size) {
    vec3 p = d * density;
    vec3 cell = floor(p);
    vec3 f = fract(p) - 0.5;
    float h = hash2(cell.xz + cell.y * 71.3);
    if (h < 0.985) return vec3(0.0);
    float disc = 1.0 - smoothstep(0.0, size, length(f));
    float twinkle = 0.5 + 0.5 * sin(Time * 3.0 + h * 63.0);
    return vec3(disc * twinkle * (h - 0.985) / 0.015);
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.05));

    // --- небо ---
    // Горизонтальная полоса закатного неба
    float y = d.y;

    // Верхняя часть — тёмно-синяя ночь
    vec3 topColor    = vec3(0.01, 0.005, 0.06) * accent;
    // Горизонт — неоновый розово-фиолетовый закат
    vec3 midColor    = mix(accent * vec3(1.2, 0.1, 0.8), vec3(1.0, 0.1, 0.5), 0.4);
    // Нижняя линия горизонта — горячий оранжево-желтый
    vec3 sunsetColor = mix(vec3(1.0, 0.5, 0.0), accent, 0.3);

    float horizonBlend = smoothstep(0.0, 0.5, abs(y));
    vec3 skyColor = mix(sunsetColor, midColor, smoothstep(0.0, 0.12, abs(y)));
    skyColor = mix(skyColor, midColor, smoothstep(0.12, 0.5, abs(y)));
    skyColor = mix(skyColor, topColor, smoothstep(0.35, 1.0, abs(y)));

    // --- солнце ---
    // Плоское "солнце" на горизонте — горизонтальные полосы
    vec2 sunDir = vec2(d.x, d.z);
    float sunDist = length(sunDir);
    float sunAngle = atan(d.y, sunDist);
    float sunRadius = 0.22;
    float inSun = smoothstep(sunRadius + 0.02, sunRadius, abs(sunAngle));

    // Горизонтальные полосы на солнце
    float stripeY = d.y * 12.0;
    float stripe = gridLine(stripeY, 0.05);
    float sunBrightness = inSun * (1.0 - stripe * 0.6);
    vec3 sunColor = mix(vec3(1.0, 0.9, 0.3), vec3(1.0, 0.3, 0.7), smoothstep(-0.05, 0.05, d.y));
    sunColor *= mix(1.8, 0.6, stripe * inSun);

    // Свечение солнца
    float sunGlow = exp(-abs(sunAngle) * 6.0) * 0.5 * smoothstep(0.5, 0.0, sunDist);
    skyColor += sunColor * sunBrightness * 2.0;
    skyColor += mix(sunColor, vec3(1.0, 0.4, 0.8), 0.5) * sunGlow;

    // --- перспективная сетка под горизонтом ---
    // Сетка видна только в нижней полусфере (d.y < 0)
    if (d.y < 0.02) {
        float gridAlpha = smoothstep(0.0, -0.08, d.y);

        // Перспективные координаты сетки
        float dist = 1.0 / max(-d.y, 0.001);
        float scrollZ = d.z * dist - Time * 0.6;
        float gridX   = d.x * dist;

        // Линии сетки
        float lineW = 0.018;
        float gx = gridLine(gridX * 0.5, lineW);
        float gz = gridLine(scrollZ * 0.5, lineW);
        float grid = max(gx, gz);

        // Цвет сетки — градиент от акцента к неону
        float distFade = smoothstep(12.0, 0.5, dist);
        vec3 gridColor = mix(accent * 1.5, vec3(1.0, 0.1, 0.8) * 2.0, 0.5);
        gridColor *= distFade;

        skyColor = mix(skyColor, gridColor, grid * gridAlpha * 0.9);

        // Полосы горизонтального свечения от сетки
        float floorGlow = smoothstep(-0.6, -0.02, d.y) * 0.2;
        skyColor += gridColor * floorGlow;
    }

    // --- звёзды в верхней части ---
    float starMask = smoothstep(0.1, 0.5, d.y);
    vec3 stars  = starLayer(d, 160.0, 0.04) * 1.5;
    stars      += starLayer(d, 300.0, 0.025) * 0.8;
    skyColor   += stars * starMask;

    // --- тонмэппинг ---
    skyColor = skyColor / (1.0 + skyColor * 0.4);
    skyColor = pow(max(skyColor, vec3(0.0)), vec3(0.9));

    OutColor = vec4(skyColor, 1.0) * ColorModulator * vColor;
}
