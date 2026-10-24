#version 150

in vec3 Direction;
in vec4 vColor;

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;

out vec4 OutColor;

// Функция для преобразования RGB в HSV
vec3 rgb2hsv(vec3 c) {
    vec4 K = vec4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));
    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

// Функция для преобразования HSV в RGB
vec3 hsv2rgb(vec3 c) {
    vec4 K = vec4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

float hash13(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float caustic(vec2 uv, float t) {
    vec2 p = mod(uv * 6.28318, 6.28318) - 250.0;
    vec2 i = p;
    float c = 1.0;
    float inten = 0.0052;
    for (int n = 0; n < 4; n++) {
        float tn = t * 0.5 + float(n);
        i = p + vec2(cos(tn - i.x) + sin(tn + i.y), sin(tn - i.y) + cos(tn + i.x));
        c += 1.0 / length(vec2(p.x / (sin(i.x + tn) / inten), p.y / (cos(i.y + tn) / inten)));
    }
    c /= 4.0;
    c = 1.17 - pow(c, 1.4);
    return clamp(pow(abs(c), 8.0), 0.0, 5.0);
}

vec3 starfield(vec3 d, float t, vec3 tint) {
    vec3 p = d * 180.0;
    vec3 i = floor(p);
    float h = hash13(i);
    if (h < 0.991) return vec3(0.0);
    vec3 f = fract(p) - 0.5;
    float disc = exp(-dot(f, f) * 1400.0);
    float twinkle = 0.5 + 0.5 * sin(t * 2.0 + h * 113.0);
    return mix(vec3(0.95, 0.96, 1.00), tint, 0.20) * disc * twinkle * 1.1;
}

void main() {
    vec3 d = normalize(Direction);
    float t = Time * 0.30;

    // Получаем цвет акцента из темы
    vec3 accent = max(Accent, vec3(0.05));

    // Конвертируем акцент в HSV для более гибкого управления
    vec3 accentHSV = rgb2hsv(accent);

    // Создаем вариации цвета на основе HSV
    // Темный фон - более темная версия
    vec3 deep = accent * 0.08 + vec3(0.002, 0.003, 0.005);

    // Средний тон - с насыщенностью 0.7 и яркостью 0.3-0.4
    vec3 midHSV = vec3(accentHSV.x, accentHSV.y * 0.7, accentHSV.z * 0.35);
    vec3 mid = hsv2rgb(midHSV);

    // Светлый/яркий тон - для вспышек
    vec3 hotHSV = vec3(accentHSV.x, accentHSV.y * 0.6, min(accentHSV.z * 1.5, 1.0));
    vec3 hot = hsv2rgb(hotHSV);

    // Свечение - очень яркий цвет с низкой насыщенностью
    vec3 glowHSV = vec3(accentHSV.x, accentHSV.y * 0.3, min(accentHSV.z * 1.8, 1.0));
    vec3 accentGlow = hsv2rgb(glowHSV);

    vec2 uv = d.xz / (abs(d.y) + 0.30) * 0.50;

    // Вычисляем волны каустики
    float c1 = caustic(uv, t);
    float c2 = caustic(uv * 1.30 + vec2(7.3, 11.1), t * 0.78 + 3.1) * 0.55;
    float c = c1 + c2;

    // Фон неба
    vec3 sky = mix(mid, deep, smoothstep(0.0, 0.75, d.y));
    float skyMask = smoothstep(-0.05, 0.22, d.y);

    // Основной цвет каустики - смесь акцента и горячего тона
    vec3 causticColor = accent * 0.85 + hot * 0.45;
    vec3 color = sky + causticColor * c * skyMask;

    // Яркие вспышки
    float core = smoothstep(0.65, 1.6, c);
    color += accentGlow * core * 0.75;

    // Звезды
    float starOcc = 1.0 - smoothstep(0.08, 0.55, c);
    vec3 starColor = starfield(d, Time, accent) * starOcc;
    color += starColor;

    // Пост-обработка с тональной коррекцией
    color = color / (1.0 + color * 0.55);
    color = pow(color, vec3(0.92));

    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}