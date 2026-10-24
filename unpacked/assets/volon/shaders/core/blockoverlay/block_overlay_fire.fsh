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
    p = fract(p * vec2(234.34, 435.34));
    p += dot(p, p + 34.23);
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
    float a = 0.52;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p = p * 2.15 + vec2(1.7, 9.2);
        a *= 0.48;
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
        OutColor = vec4(mix(color, color2, 0.6), edgeAlpha);
        return;
    }

    float t = time * max(speed, 0.001);
    vec2 p = uv * mix(2.5, 6.0, clamp(scale / 3.0, 0.0, 1.0));

    // Convective upward motion
    vec2 warp = vec2(
        fbm(p * 1.4 + vec2(0.0, -t * 1.6)),
        fbm(p * 1.1 + vec2(3.2, -t * 2.1))
    );
    vec2 q = p + (warp - 0.5) * 1.4;

    // Rising flames
    float flame1 = fbm(q * 1.8 + vec2(0.0, -t * 2.4));
    float flame2 = fbm(q * 3.4 + vec2(t * 0.25, -t * 3.2));
    float flame = clamp(flame1 * 0.65 + flame2 * 0.55, 0.0, 1.0);

    // Crackling hot fissures
    float fissures = 1.0 - abs(noise(q * 2.8 + vec2(0.0, -t * 1.2)) * 2.0 - 1.0);
    fissures = pow(clamp(fissures, 0.0, 1.0), 3.0);

    // Drifting sparks / embers
    vec2 emberGrid = vec2(uv.x * 22.0, (uv.y + t * 0.9) * 26.0);
    vec2 emberId = floor(emberGrid);
    float emberH = hash(emberId);
    float ember = step(0.968, emberH) * pow(clamp(1.0 - length(fract(emberGrid) - 0.5) * 2.3, 0.0, 1.0), 2.8);

    // Flame color dynamics (theme integrated)
    vec3 charCol  = mix(vec3(0.03, 0.01, 0.01), color * 0.08, 0.5);
    vec3 midFlame = mix(color, color2, clamp(flame * 1.2 - 0.1, 0.0, 1.0));
    vec3 hotCore  = mix(color2, vec3(1.0, 0.95, 0.75), 0.75);

    vec3 flameCol = mix(charCol, midFlame, smoothstep(0.18, 0.65, flame));
    flameCol = mix(flameCol, hotCore, smoothstep(0.60, 0.94, flame));
    flameCol += hotCore * fissures * (0.6 + glow * 0.2);
    flameCol += vec3(1.0, 0.95, 0.8) * ember * 1.8;

    vec3 outlineColor = mix(color, color2, 0.5);

    float innerMask = clamp(mask - edgeBand * 0.56, 0.0, 1.0);
    float fillStrength = fill * innerMask * (0.3 + flame * 0.68 + fissures * 0.35);
    float edgeStrength = edgeBand * (0.35 + glow * 0.14);

    vec3 rgb = flameCol * fillStrength + outlineColor * edgeStrength;
    float outAlpha = clamp(alpha * (fillStrength * 0.94 + edgeBand * 0.5) * mask, 0.0, 1.0);

    if (outAlpha <= 0.001) discard;
    OutColor = vec4(rgb, outAlpha);
}
