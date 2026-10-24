#version 150

in vec3 Direction;

uniform float Time;
uniform vec3 Accent;

out vec4 OutColor;

float hash21(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(hash21(i), hash21(i + vec2(1, 0)), f.x),
        mix(hash21(i + vec2(0, 1)), hash21(i + vec2(1, 1)), f.x),
        f.y
    );
}

float fbm(vec2 p) {
    float value = 0.0;
    float amp = 0.5;
    for(int i = 0; i < 4; i++) {
        value += amp * noise(p);
        p *= 2.02;
        amp *= 0.5;
    }
    return value;
}

// Функция для создания кристаллических структур
float crystal(vec2 p, float time) {
    p = abs(fract(p) - 0.5);
    float d = min(max(p.x - p.y, p.x + p.y), 1.0);
    d = smoothstep(0.0, 0.1, d);
    
    // Добавляем анимацию роста кристаллов
    float growth = sin(time * 2.0 + length(p) * 10.0) * 0.5 + 0.5;
    return d * growth;
}

void main() {
    vec3 d = normalize(Direction);
    vec2 uv = d.xy / (d.z + 1.0);
    
    float time = Time * 0.2;
    vec2 p = uv * 8.0;
    
    // Создаем многослойную кристаллическую структуру
    float cryst1 = crystal(p + vec2(time * 0.1, time * 0.05), time);
    float cryst2 = crystal(p * 0.5 + vec2(time * 0.08, -time * 0.03), time + 1.5);
    float cryst3 = crystal(p * 0.25 + vec2(-time * 0.06, time * 0.04), time + 3.0);
    
    // Комбинируем кристаллы
    float crystals = cryst1 + cryst2 * 0.7 + cryst3 * 0.5;
    
    // Добавляем шум для детализации
    float detail = fbm(p * 2.0 + time * 0.1) * 0.3;
    crystals += detail;
    
    // Создаем цветовую схему кристаллов
    vec3 color1 = vec3(0.1, 0.3, 0.8);  // Синий
    vec3 color2 = vec3(0.3, 0.8, 1.0);  // Голубой
    vec3 color3 = vec3(0.8, 0.9, 1.0);  // Белый
    
    vec3 finalColor = mix(color1, color2, crystals * 0.7);
    finalColor = mix(finalColor, color3, pow(crystals, 2.0));
    
    // Применяем акцентный цвет
    finalColor *= max(Accent, vec3(0.1));
    
    // Добавляем свечение
    float glow = pow(crystals, 1.5) * 1.5;
    finalColor += glow * vec3(0.2, 0.5, 1.0);
    
    OutColor = vec4(finalColor, 1.0);
}