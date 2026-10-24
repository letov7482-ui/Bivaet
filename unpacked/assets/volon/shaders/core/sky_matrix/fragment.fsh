#version 150

in vec3 Direction;
in vec4 vColor;
uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
out vec4 OutColor;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.02, 0.3, 0.02));
    float t = Time * 0.8;

    // Тёмный фон
    vec3 color = vec3(0.0, 0.01, 0.0);

    // Падающие символы (дождь матрицы)
    float cols = 40.0;
    float col = floor((d.x * 0.5 + 0.5) * cols);
    float colHash = hash(vec2(col, 0.0));
    float speed = 0.5 + colHash * 1.5;
    float offset = colHash * 10.0;
    float row = fract(d.y * 0.5 + 0.5 + t * speed + offset);
    float trail = exp(-row * 6.0);
    float cellHash = hash(vec2(col, floor(t * speed * 8.0 + offset * 8.0)));
    float glyph = step(0.4, cellHash);

    // Свечение колонки
    float colGlow = exp(-pow(fract((d.x*0.5+0.5)*cols) - 0.5, 2.0) * 20.0);
    color += accent * trail * glyph * colGlow * 1.5;

    // Яркий верхний символ
    float headRow = fract(d.y * 0.5 + 0.5 + t * speed + offset);
    float head = exp(-headRow * headRow * 100.0);
    color += vec3(0.7, 1.0, 0.7) * head * colGlow;

    // Горизонтальное затухание — больше эффекта по центру неба
    color *= 1.0 - abs(d.y) * 0.6;

    color = color / (1.0 + color * 0.5);
    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
