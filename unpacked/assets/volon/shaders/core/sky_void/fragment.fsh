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
    for(int k=0;k<5;k++){v+=a*noise(p); p=p*2.0+vec3(1.7,2.3,0.9); a*=0.5;}
    return v;
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.1, 0.0, 0.2));
    float t = Time * 0.06;

    // Абсолютная тьма
    vec3 color = vec3(0.0);

    // Пульсирующие трещины в пространстве
    vec3 p = d * 3.0 + vec3(t, t*0.5, -t*0.7);
    float crack = fbm(p);
    float edge = abs(crack - 0.5);
    float glow = exp(-edge * 12.0) * 0.8;

    color += accent * glow * 1.5;
    color += vec3(1.0, 0.8, 1.0) * exp(-edge * 30.0) * 0.4;

    // Вихри тьмы
    vec3 q = d * 2.0;
    for(int i=1;i<=3;i++){
        float fn = float(i);
        q += vec3(sin(q.y*2.0+t*0.6)/fn, cos(q.z*1.8-t*0.4)/fn, sin(q.x*2.2+t*0.5)/fn);
    }
    float swirl = fbm(q*1.5 + vec3(t));
    color += accent * 0.6 * smoothstep(0.4, 0.9, swirl);

    // Редкие мерцающие звёзды
    float starN = hash13(d * 300.0);
    float star = step(0.995, starN);
    float twinkle = 0.6 + 0.4 * sin(t * 8.0 + starN * 40.0);
    color += vec3(0.8, 0.7, 1.0) * star * twinkle;

    color = color / (1.0 + color * 0.6);
    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
