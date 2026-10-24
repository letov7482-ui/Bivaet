#version 150

uniform sampler2D Sampler0;
uniform vec2 texelSize;
uniform vec3 color;
uniform vec3 color2;
uniform float time;

uniform float speed;
uniform float scale;
uniform float outline;
uniform float glow;
uniform float fill;
uniform float alpha;
uniform float outlineOnly;

in vec2 TexCoord;
out vec4 OutColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

mat2 rot2D(float a) {
    float c = cos(a);
    float s = sin(a);
    return mat2(c, -s, s, c);
}

float fbm(vec2 p) {
    float value = 0.0;
    float amplitude = 0.52;
    mat2 r = rot2D(0.55);
    for (int i = 0; i < 5; i++) {
        value += noise(p) * amplitude;
        p = r * p * 2.08 + vec2(3.4, 7.1);
        amplitude *= 0.49;
    }
    return value;
}

float getEdge(vec2 uv, float s) {
    float a0  = texture(Sampler0, uv).a;
    float ax1 = texture(Sampler0, uv + vec2(texelSize.x * s, 0.0)).a;
    float ax2 = texture(Sampler0, uv - vec2(texelSize.x * s, 0.0)).a;
    float ay1 = texture(Sampler0, uv + vec2(0.0, texelSize.y * s)).a;
    float ay2 = texture(Sampler0, uv - vec2(0.0, texelSize.y * s)).a;
    float edge = abs(a0 - ax1) + abs(a0 - ax2) + abs(a0 - ay1) + abs(a0 - ay2);

    float diag1 = texture(Sampler0, uv + vec2(texelSize.x * s, texelSize.y * s)).a;
    float diag2 = texture(Sampler0, uv + vec2(-texelSize.x * s, texelSize.y * s)).a;
    float diag3 = texture(Sampler0, uv + vec2(texelSize.x * s, -texelSize.y * s)).a;
    float diag4 = texture(Sampler0, uv + vec2(-texelSize.x * s, -texelSize.y * s)).a;
    edge += 0.7 * (abs(a0 - diag1) + abs(a0 - diag2) + abs(a0 - diag3) + abs(a0 - diag4));

    return clamp(edge * 1.9, 0.0, 1.0);
}

void main() {
    vec2 uv = TexCoord;
    float mask = texture(Sampler0, uv).a;
    if (mask <= 0.0) discard;

    float edge = getEdge(uv, outline);
    float edgeBand = smoothstep(0.02, 0.42, edge);

    if (outlineOnly > 0.5) {
        float edgeAlpha = clamp(edgeBand * alpha, 0.0, 1.0) * mask;
        if (edgeAlpha <= 0.001) discard;
        OutColor = vec4(mix(color, color2, 0.5), edgeAlpha);
        return;
    }

    float t = time * max(speed, 0.001);
    vec2 flowUv = uv * mix(2.2, 5.5, clamp(scale / 3.0, 0.0, 1.0));

    // Multi-stage domain warping for billowing aurora / plasma smoke
    vec2 q = vec2(
        fbm(flowUv + vec2(t * 0.18, -t * 0.14) + vec2(0.0, 1.2)),
        fbm(flowUv + vec2(-t * 0.15, t * 0.22) + vec2(5.2, 3.4))
    );

    vec2 r = vec2(
        fbm(flowUv + 3.2 * q + vec2(t * 0.24, t * 0.16) + vec2(1.7, 9.2)),
        fbm(flowUv + 3.2 * q + vec2(-t * 0.20, -t * 0.28) + vec2(8.3, 2.8))
    );

    // Billowing smoke density
    float f = fbm(flowUv + 3.6 * r);

    // Deep shadowy voids vs bright billowing clouds (high contrast like in the screenshot)
    vec3 darkVoid = mix(color * 0.06, color2 * 0.04, 0.5);
    vec3 midTone  = mix(color, color2, clamp(length(q) * 0.85, 0.0, 1.0));
    vec3 brightCloud = mix(midTone, vec3(1.0, 1.0, 1.0), 0.55);

    // Core white hot highlights on the cloud crests
    float cloudCrest = pow(smoothstep(0.48, 0.92, f), 2.2);
    float deepFold   = smoothstep(0.18, 0.62, f);

    vec3 smokeColor = mix(darkVoid, midTone, deepFold);
    smokeColor = mix(smokeColor, brightCloud, smoothstep(0.55, 0.88, f));
    smokeColor += vec3(1.0, 1.0, 1.0) * cloudCrest * (0.85 + glow * 0.35);

    // Outline color tinted with theme blend
    vec3 outlineColor = mix(color, color2, 0.45);

    float innerMask = clamp(mask - edgeBand * 0.58, 0.0, 1.0);
    float fillStrength = fill * innerMask * (0.35 + deepFold * 0.55 + cloudCrest * 0.35);
    float edgeStrength = edgeBand * (0.36 + glow * 0.14);

    vec3 rgb = smokeColor * fillStrength + outlineColor * edgeStrength;
    float outAlpha = clamp(alpha * (fillStrength * 0.95 + edgeBand * 0.52) * mask, 0.0, 1.0);

    if (outAlpha <= 0.001) discard;
    OutColor = vec4(rgb, outAlpha);
}
