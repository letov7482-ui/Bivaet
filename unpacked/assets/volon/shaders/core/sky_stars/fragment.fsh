#version 150

uniform vec4 ColorModulator;
uniform float Time;

in vec3 Direction;

out vec4 fragColor;

float hash(vec3 p) {
    p = fract(p * vec3(127.1, 311.7, 74.7));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y * p.z);
}

void main() {
    vec3 dir = normalize(Direction);

    float starDensity = 200.0;
    vec3 cell = floor(dir * starDensity);
    float h = hash(cell);
    float brightness = step(0.985, h);
    float twinkle = brightness * (0.7 + 0.3 * sin(Time * 3.0 + h * 100.0));

    vec3 color = ColorModulator.rgb * twinkle;
    float alpha = twinkle * ColorModulator.a;

    if (alpha < 0.01) discard;
    fragColor = vec4(color, alpha);
}
