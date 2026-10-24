#version 150

in vec2 texCoord;
out vec4 fragColor;

layout(std140) uniform ShaderFogData {
    vec2 uResolution;
    vec2 uCameraDir;
    vec3 uColor;
    float uTime;
    float uAlpha;
    float uSpeed;
    float uScale;
    float uIntensity;
    float uFov;
};

mat3 rotX(float a) {
    float c = cos(a), s = sin(a);
    return mat3(1.0, 0.0, 0.0, 0.0, c, s, 0.0, -s, c);
}

mat3 rotY(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, 0.0, s, 0.0, 1.0, 0.0, -s, 0.0, c);
}

mat3 rotZ(float a) {
    float c = cos(a), s = sin(a);
    return mat3(c, s, 0.0, -s, c, 0.0, 0.0, 0.0, 1.0);
}

float hash31(vec3 p) {
    p = fract(p * vec3(443.8975, 397.2973, 491.1871));
    p += dot(p, p.yxz + 19.19);
    return fract((p.x + p.y) * p.z);
}

float smoothNoise3D(vec3 p) {
    vec3 i = floor(p);
    vec3 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(
        mix(
            mix(hash31(i), hash31(i + vec3(1.0, 0.0, 0.0)), f.x),
            mix(hash31(i + vec3(0.0, 1.0, 0.0)), hash31(i + vec3(1.0, 1.0, 0.0)), f.x), 
            f.y
        ),
        mix(
            mix(hash31(i + vec3(0.0, 0.0, 1.0)), hash31(i + vec3(1.0, 0.0, 1.0)), f.x),
            mix(hash31(i + vec3(0.0, 1.0, 1.0)), hash31(i + vec3(1.0, 1.0, 1.0)), f.x), 
            f.y
        ),
        f.z
    );
}

float fbm(vec3 p) {
    float v = 0.0;
    float a = 0.5;
    for (int k = 0; k < 4; k++) {
        v += a * smoothNoise3D(p);
        p = p * 2.02 + vec3(1.2, 2.3, 0.9);
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 uv = gl_FragCoord.xy / uResolution;
    vec2 sp = uv * 2.0 - 1.0;
    float aspect = uResolution.x / uResolution.y;
    float tanV = tan(radians(uFov) * 0.5);
    vec3 rayV = normalize(vec3(sp.x * tanV * aspect, sp.y * tanV, 1.0));
    vec3 rayW = rotY(uCameraDir.x) * rotX(uCameraDir.y) * rayV;
    
    mat3 riftRot = rotZ(0.65) * rotX(0.35);
    vec3 pRay = riftRot * rayW;
    
    float time = uTime * uSpeed * 0.12;
    float sc = max(uScale, 0.05);
    vec3 p = pRay * (1.8 / sc);
    
    vec3 warp = vec3(
        fbm(p + vec3(0.0, time * 0.5, 1.3)),
        fbm(p + vec3(2.1, 1.1, time * 0.4)),
        fbm(p + vec3(1.4, time * 0.6, 0.0))
    );
    
    float riftDist = abs(pRay.y - (warp.x - 0.5) * 0.7);
    float tearWidth = 0.18 * sc + (warp.y * 0.14);
    float insideRift = smoothstep(tearWidth + 0.12, tearWidth - 0.02, riftDist);
    float edgeDist = abs(riftDist - tearWidth);
    float edgeGlow = exp(-edgeDist * 16.0) * 2.5;
    
    vec3 q = p * 1.4 + vec3(time * 0.4, time * 0.2, time * 0.3);
    for(int n = 1; n <= 3; n++) {
        float fn = float(n);
        q += vec3(
            sin(q.y * 1.8 + time * 0.8) + cos(q.z * 1.5),
            cos(q.z * 1.7 - time * 0.6) + sin(q.x * 1.4),
            sin(q.x * 1.6 + time * 0.7) + cos(q.y * 1.3)
        ) * (0.35 / fn);
    }
    
    float innerTurbulence = fbm(q * 1.1);
    float innerCore = exp(-length(pRay - vec3(0.0, 0.0, 0.95)) * 1.8) * 2.0;
    
    vec3 cGold     = vec3(1.00, 0.88, 0.45);
    vec3 cCyan     = vec3(0.00, 0.85, 0.98);
    vec3 cMagenta  = vec3(0.92, 0.15, 0.62);
    vec3 cPurple   = vec3(0.28, 0.04, 0.58);
    
    vec3 innerColor = mix(cPurple, cMagenta, clamp(innerTurbulence * 1.3, 0.0, 1.0));
    innerColor = mix(innerColor, cCyan, clamp(sin(q.x * 2.2 + time) * 0.5 + 0.5, 0.0, 1.0));
    innerColor = mix(innerColor, cGold, clamp(innerCore * 0.9 + innerTurbulence * 0.4 - 0.25, 0.0, 1.0));
    innerColor *= (1.8 + uIntensity * 12.0);
    
    float outerHaze = exp(-riftDist * 2.2) * 0.3 * fbm(p * 0.8);
    vec3 outerColor = mix(vec3(0.01, 0.005, 0.03), vec3(0.08, 0.02, 0.15), outerHaze) * uColor;
    vec3 finalColor = mix(outerColor, innerColor, insideRift);
    vec3 edgeColor = mix(cCyan, vec3(1.0, 0.95, 0.8), edgeGlow * 0.5);
    finalColor += edgeColor * edgeGlow * (1.0 + uIntensity * 8.0);
    finalColor *= uColor * 1.2;
    finalColor = mix(vec3(0.002, 0.002, 0.005), finalColor, clamp(uAlpha, 0.0, 1.0));
    
    fragColor = vec4(finalColor, uAlpha);
}
