#version 150

in vec3 Direction;
in vec4 vColor;
uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
out vec4 OutColor;

float hash13(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float noise(vec3 x) {
    vec3 i = floor(x); vec3 f = fract(x);
    f = f*f*(3.0-2.0*f);
    return mix(mix(mix(hash13(i),hash13(i+vec3(1,0,0)),f.x),mix(hash13(i+vec3(0,1,0)),hash13(i+vec3(1,1,0)),f.x),f.y),
               mix(mix(hash13(i+vec3(0,0,1)),hash13(i+vec3(1,0,1)),f.x),mix(hash13(i+vec3(0,1,1)),hash13(i+vec3(1,1,1)),f.x),f.y),f.z);
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.0, 0.2, 0.5));
    float t = Time * 0.25;

    // Градиент от глубокого синего до бирюзы
    vec3 deep    = vec3(0.0, 0.02, 0.12);
    vec3 surface = vec3(0.0, 0.45, 0.72) * accent;
    vec3 foam    = vec3(0.6, 0.85, 1.0);

    float vertical = d.y * 0.5 + 0.5;
    vec3 color = mix(deep, surface, smoothstep(0.0, 0.8, vertical));

    // Рябь волн
    vec3 waveP = d * 6.0 + vec3(t, -t*0.7, t*0.4);
    float wave1 = noise(waveP);
    float wave2 = noise(waveP * 2.1 + vec3(1.3, 0.7, -0.4));
    float waves = wave1 * 0.6 + wave2 * 0.4;

    float waveMask = smoothstep(0.0, 0.5, 1.0 - abs(d.y));
    color += foam * waves * waveMask * 0.25;

    // Отражение "солнца"
    vec3 sunDir = normalize(vec3(0.3, 0.7, 0.6));
    float sunRef = pow(max(dot(d, sunDir), 0.0), 32.0);
    color += vec3(1.0, 0.95, 0.8) * sunRef * 0.8;

    // Горизонтальное свечение
    float horizon = exp(-abs(d.y) * 3.0) * 0.4;
    color += mix(surface, foam, 0.3) * horizon;

    // Звёзды в верхней части
    float stars = step(0.988, hash13(d * 200.0)) * smoothstep(0.2, 0.6, d.y);
    color += vec3(0.9, 0.95, 1.0) * stars;

    color = color / (1.0 + color * 0.3);
    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
