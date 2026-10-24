#version 150

in vec3 Direction;

uniform float Time;
uniform vec3 Accent;

out vec4 OutColor;

float random(vec2 p) {
    return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    
    return mix(
        mix(random(i), random(i + vec2(1, 0)), f.x),
        mix(random(i + vec2(0, 1)), random(i + vec2(1, 1)), f.x),
        f.y
    );
}

// Функция для создания электрических разрядов
float lightning(vec2 p, float time) {
    // Основная ветвь молнии
    float mainBolt = abs(sin(p.y * 15.0 + noise(vec2(p.x * 10.0, time * 5.0)) * 8.0));
    mainBolt = smoothstep(0.95, 1.0, mainBolt);
    
    // Ветвящиеся разряды
    float branches = 0.0;
    for(int i = 0; i < 3; i++) {
        float fi = float(i + 1);
        vec2 offset = vec2(noise(p * fi + time), noise(p.yx * fi - time)) * 0.3;
        float branch = abs(sin((p.y + offset.y) * 20.0 * fi));
        branch = smoothstep(0.98, 1.0, branch);
        branches += branch / fi;
    }
    
    return mainBolt + branches * 0.5;
}

void main() {
    vec3 d = normalize(Direction);
    vec2 uv = d.xy / (d.z + 1.0);
    
    float time = Time * 2.0;
    vec2 p = uv * 6.0;
    
    // Создаем несколько молний в разных местах
    float bolt1 = lightning(p + vec2(sin(time * 0.3) * 2.0, time * 0.5), time);
    float bolt2 = lightning(p * 0.7 + vec2(cos(time * 0.4) * 1.5, -time * 0.3), time + 2.0);
    float bolt3 = lightning(p * 1.2 + vec2(sin(time * 0.2) * 1.8, time * 0.4), time + 4.0);
    
    // Комбинируем разряды
    float electricity = bolt1 + bolt2 * 0.8 + bolt3 * 0.6;
    
    // Добавляем атмосферное свечение
    float atmosphere = noise(p * 0.5 + time * 0.1) * 0.3;
    
    // Создаем цветовую схему электричества
    vec3 electric_blue = vec3(0.2, 0.5, 1.0);
    vec3 electric_white = vec3(0.9, 0.95, 1.0);
    vec3 electric_purple = vec3(0.6, 0.3, 1.0);
    
    vec3 finalColor = mix(electric_blue, electric_white, electricity);
    finalColor = mix(finalColor, electric_purple, sin(time * 3.0 + electricity * 10.0) * 0.5 + 0.5);
    
    // Применяем акцентный цвет
    finalColor *= max(Accent, vec3(0.1));
    
    // Добавляем интенсивность и мерцание
    float flicker = sin(time * 15.0 + electricity * 50.0) * 0.1 + 0.9;
    finalColor *= electricity * 2.0 * flicker;
    
    // Добавляем фоновое свечение
    finalColor += atmosphere * vec3(0.1, 0.2, 0.4);
    
    OutColor = vec4(finalColor, 1.0);
}