#version 150

uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
in vec3 Direction;
in vec4 vColor;
out vec4 OutColor;

void main() {
    vec3 ray = normalize(Direction);
    vec2 p = vec2(atan(ray.x, ray.z), asin(clamp(ray.y, -1.0, 1.0))) * 0.05;
    float pLen = length(p);
    float angle = atan(p.y, p.x + 1e-6) + Time * 0.2 + 302.2 - 20.0 * (0.5 * pLen + 0.5);
    p = vec2(pLen * cos(angle), pLen * sin(angle)) * 30.0;
    float speed = Time * 0.5;
    vec2 p2 = p;
    for (int i = 0; i < 4; i++) {
        p2 += sin(max(p.x, p.y)) + p;
        p += 0.5 * vec2(cos(5.1123314 + 0.353 * p2.y + speed * 0.131121), sin(p2.x - 0.113 * speed));
        p -= cos(p.x + p.y) - sin(p.x * 0.711 - p.y);
    }
    float contrastMod = 1.825;
    float paintRes = clamp(length(p) * 0.035 * contrastMod, 0.0, 2.0);
    float c1 = max(0.0, 1.0 - contrastMod * abs(1.0 - paintRes));
    float c2 = max(0.0, 1.0 - contrastMod * abs(paintRes));
    float c3 = 1.0 - min(1.0, c1 + c2);
    float light = 0.5 * max(c1 * 5.0 - 4.0, 0.0) + 0.7 * max(c2 * 5.0 - 4.0, 0.0);
    vec3 col = (0.13 * Accent) + (0.87 * (Accent * c1 + Accent * vec3(0.5, 1.2, 0.8) * c2 + Accent * vec3(1.2, 0.6, 1.1) * c3)) + light;
    float luminance = clamp(dot(col, vec3(0.299, 0.587, 0.114)), 0.0, 1.0);
    OutColor = vec4(col, luminance) * ColorModulator * vColor;
}
