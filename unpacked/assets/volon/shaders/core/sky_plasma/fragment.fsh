#version 150

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
in vec3 Direction;
in vec4 vColor;
out vec4 OutColor;

#define TAU 6.28318530718
#define MAX_ITER 4
#define INTENSITY 0.005

void main() {
    vec3 ray = normalize(Direction);
    vec2 uv = vec2(atan(ray.x, ray.z) / TAU, asin(clamp(ray.y, -1.0, 1.0)) / 3.14159265);
    vec2 p = mod(uv * TAU, TAU) - 250.0;
    vec2 iterPos = p;
    float value = 1.0;
    float timeOffset = Time * 0.5 + 23.0;
    for (int n = 0; n < MAX_ITER; n++) {
        float iterTime = timeOffset * (1.0 - (3.5 / float(n + 1)));
        iterPos = p + vec2(cos(iterTime - iterPos.x) + sin(iterTime + iterPos.y), sin(iterTime - iterPos.y) + cos(iterTime + iterPos.x));
        float sx = sin(iterPos.x + iterTime);
        float cy = cos(iterPos.y + iterTime);
        vec2 comp = vec2(p.x * INTENSITY / max(abs(sx), 0.001), p.y * INTENSITY / max(abs(cy), 0.001));
        value += 1.0 / length(comp);
    }
    value = 1.17 - pow(value / float(MAX_ITER), 1.4);
    float power = value * value;
    power = power * power;
    power = power * power;
    vec3 baseColor = vec3(abs(power));
    vec3 enhancedColor = clamp(baseColor + vec3(0.0, 0.35, 0.5), 0.0, 1.0);
    float luminance = dot(enhancedColor, vec3(0.299, 0.587, 0.114));
    OutColor = vec4(vec3(luminance) * Accent * 1.4, luminance) * ColorModulator * vColor;
}
