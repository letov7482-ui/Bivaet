#version 150

uniform sampler2D Sampler0;
uniform float Radius;
uniform vec2 Resolution;

in vec2 texCoord;
out vec4 fragColor;

void main() {
    vec2 texelSize = 1.0 / Resolution;
    vec4 color = vec4(0.0);
    float total = 0.0;
    int r = int(Radius);

    for (int x = -r; x <= r; x++) {
        for (int y = -r; y <= r; y++) {
            vec2 offset = vec2(float(x), float(y)) * texelSize;
            float weight = 1.0 / (1.0 + float(x * x + y * y));
            color += texture(Sampler0, texCoord + offset) * weight;
            total += weight;
        }
    }

    fragColor = color / total;
}
