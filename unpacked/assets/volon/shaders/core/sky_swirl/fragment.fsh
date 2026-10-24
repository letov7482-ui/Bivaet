#version 150

in vec3 Direction;

uniform float Time;
uniform vec3 Accent;

out vec4 OutColor;

float hash21(vec2 p) {
    p = fract(p * vec2(234.34, 435.345));
    p += dot(p, p + 34.23);
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

// Функция для создания вихревых узоров
vec2 swirl(vec2 p, float strength, float time) {
    float dist = length(p);
    float angle = atan(p.y, p.x);
    
    // Создаем спиральное движение
    angle += dist * strength + time;
    
    return vec2(cos(angle), sin(angle)) * dist;
}

void main() {
    vec3 d = normalize(Direction);
    vec2 uv = d.xy / (d.z + 1.0);
    
    float time = Time * 0.5;
    vec2 center = vec2(0.0);
    
    // Создаем несколько вихрей разного размера
    vec2 p1 = swirl(uv * 3.0 - center, 2.0, time);
    vec2 p2 = swirl(uv * 5.0 - center, -1.5, time * 0.8);
    vec2 p3 = swirl(uv * 7.0 - center, 1.0, time * 1.2);
    
    // Генерируем шум для каждого слоя
    float swirl1 = noise(p1 + time * 0.1);
    float swirl2 = noise(p2 - time * 0.08) * 0.7;
    float swirl3 = noise(p3 + time * 0.12) * 0.5;
    
    // Комбинируем слои
    float pattern = swirl1 + swirl2 + swirl3;
    
    // Добавляем радиальный градиент для центрального эффекта
    float radial = 1.0 - length(uv) * 0.8;
    pattern *= max(radial, 0.2);
    
    // Создаем цветовую схему вихрей
    vec3 color1 = vec3(0.2, 0.1, 0.6);  // Темно-фиолетовый
    vec3 color2 = vec3(0.6, 0.2, 0.8);  // Фиолетовый
    vec3 color3 = vec3(0.9, 0.5, 1.0);  // Светло-фиолетовый
    
    vec3 finalColor = mix(color1, color2, pattern * 0.8);
    finalColor = mix(finalColor, color3, pow(pattern, 2.0));
    
    // Применяем акцентный цвет
    finalColor *= max(Accent, vec3(0.1));
    
    // Добавляем динамическую интенсивность
    float intensity = sin(time * 2.0 + pattern * 5.0) * 0.2 + 0.8;
    finalColor *= intensity * (0.5 + pattern * 1.5);
    
    OutColor = vec4(finalColor, 1.0);
}