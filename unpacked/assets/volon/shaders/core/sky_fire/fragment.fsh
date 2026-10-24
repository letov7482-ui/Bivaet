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

float fbm(vec3 p) {
    float v=0.0, a=0.5;
    for(int k=0;k<4;k++){v+=a*noise(p); p=p*2.02+vec3(1.2,2.3,0.9); a*=0.5;}
    return v;
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.5, 0.1, 0.0));
    float t = Time * 0.4;

    // Огненный градиент
    float h = d.y * 0.5 + 0.5;
    vec3 cEmber  = vec3(1.0, 0.15, 0.0);
    vec3 cFlame  = vec3(1.0, 0.6, 0.05);
    vec3 cHot    = vec3(1.0, 0.95, 0.6);
    vec3 cSmoke  = vec3(0.08, 0.04, 0.04);

    vec3 color = mix(cEmber, cSmoke, smoothstep(0.0, 1.0, h)) * accent * 0.5;

    // Языки пламени
    vec3 fp = d * 4.0 + vec3(t*0.3, -t, t*0.2);
    float flame = fbm(fp);
    float flameShape = smoothstep(0.35, 0.85, flame);
    float up = 1.0 - smoothstep(0.0, 0.8, h);

    color += mix(cEmber, cFlame, flameShape) * flameShape * up * 1.2 * accent;
    color += cHot * pow(flameShape, 3.0) * up * 0.8;

    // Искры
    float sparkN = hash13(d * 250.0 + vec3(floor(t*3.0)));
    float spark = step(0.993, sparkN) * (1.0 - h*0.7);
    float sparkLife = fract(t*3.0 + sparkN*5.0);
    color += cHot * spark * (1.0 - sparkLife);

    // Дымка сверху
    float smoke = fbm(d * 2.5 + vec3(t*0.1, t*0.08, 0.0));
    color = mix(color, cSmoke * 0.3, smoothstep(0.4, 1.0, h) * smoke * 0.5);

    color = color / (1.0 + color * 0.35);
    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
