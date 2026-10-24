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
    p = fract(p * vec2(213.34, 567.89));
    p += dot(p, p + 53.21);
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

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.1 + vec2(4.1, 7.3);
        a *= 0.5;
    }
    return v;
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
        OutColor = vec4(mix(color, color2, 0.4), edgeAlpha);
        return;
    }

    float t = time * max(speed, 0.001);
    vec2 p = (uv - 0.5) * mix(3.0, 7.5, clamp(scale / 3.0, 0.0, 1.0));

    // Spiral swirl galaxy motion
    float dist = length(p);
    float ang  = atan(p.y, p.x);
    float twist = ang + dist * 1.6 - t * 0.45;
    vec2 twisted = vec2(cos(twist), sin(twist)) * dist;

    // Layered cosmic dust nebulas
    float neb1 = fbm(twisted * 1.4 + vec2(t * 0.10, -t * 0.08));
    float neb2 = fbm(p * 2.1 - vec2(t * 0.08, t * 0.12));
    float nebula = clamp(neb1 * 0.65 + neb2 * 0.55, 0.0, 1.0);

    // Galaxy core glow
    float coreGlow = exp(-dist * 1.8) * 1.2;

    // Twinkling stars
    vec2 starGrid1 = uv * 32.0 * max(scale, 0.5);
    vec2 id1 = floor(starGrid1);
    float h1 = hash(id1);
    float star1 = step(0.965, h1) * pow(clamp(1.0 - length(fract(starGrid1) - 0.5) * 2.6, 0.0, 1.0), 3.5);
    star1 *= 0.35 + 0.65 * sin(t * 3.8 + h1 * 6.28);

    vec2 starGrid2 = uv * 16.0 * max(scale, 0.5);
    vec2 id2 = floor(starGrid2);
    float h2 = hash(id2 + vec2(42.3, 19.8));
    float star2 = step(0.975, h2) * pow(clamp(1.0 - length(fract(starGrid2) - 0.5) * 2.0, 0.0, 1.0), 2.5);
    star2 *= 0.3 + 0.7 * sin(t * 5.2 + h2 * 6.28);

    // Deep space dark void
    vec3 spaceVoid = mix(vec3(0.01, 0.01, 0.03), color * 0.08, 0.5);

    // Nebula dust coloration from theme
    vec3 nebColor = mix(color, color2, clamp(nebula * 1.2 - 0.1, 0.0, 1.0));
    vec3 coreColor = mix(color2, vec3(1.0, 0.95, 0.9), 0.7);

    vec3 space = mix(spaceVoid, nebColor, smoothstep(0.2, 0.75, nebula));
    space += coreColor * coreGlow * (0.6 + glow * 0.3);

    // Add stars
    space += vec3(1.0, 0.98, 1.0) * (star1 * 1.3 + star2 * 1.6);

    vec3 outlineColor = mix(color, color2, 0.5);

    float innerMask = clamp(mask - edgeBand * 0.55, 0.0, 1.0);
    float fillStrength = fill * innerMask * (0.28 + nebula * 0.65 + coreGlow * 0.35);
    float edgeStrength = edgeBand * (0.35 + glow * 0.14);

    vec3 rgb = space * fillStrength + outlineColor * edgeStrength;
    float outAlpha = clamp(alpha * (fillStrength * 0.94 + edgeBand * 0.5) * mask, 0.0, 1.0);

    if (outAlpha <= 0.001) discard;
    OutColor = vec4(rgb, outAlpha);
}
