#version 150

in vec3 Direction;
in vec4 vColor;
uniform float Time;
uniform vec3 Accent;
uniform vec4 ColorModulator;
out vec4 OutColor;

float hash(float n) { return fract(sin(n) * 43758.5453); }

float noise(vec3 p) {
    vec3 i = floor(p); vec3 f = fract(p);
    f = f*f*(3.0-2.0*f);
    float n = i.x + i.y*57.0 + i.z*113.0;
    return mix(mix(mix(hash(n),hash(n+1.0),f.x),mix(hash(n+57.0),hash(n+58.0),f.x),f.y),
               mix(mix(hash(n+113.0),hash(n+114.0),f.x),mix(hash(n+170.0),hash(n+171.0),f.x),f.y),f.z);
}

void main() {
    vec3 d = normalize(Direction);
    vec3 accent = max(Accent, vec3(0.05));
    float t = Time * 0.3;

    // Тёмный фон
    vec3 color = mix(vec3(0.0,0.01,0.03), vec3(0.0,0.02,0.06), smoothstep(0.0,1.0,abs(d.y)));

    // Волны северного сияния
    for(int i=0; i<4; i++) {
        float fi = float(i);
        float wave = sin(d.x * (3.0+fi) + t + fi*1.3) * cos(d.z * (2.0+fi*0.7) - t*0.8);
        float band = exp(-pow((d.y - wave*0.3 - 0.1 + fi*0.15)*8.0, 2.0));
        vec3 c = mix(accent, vec3(accent.z, accent.x, accent.y+0.3), fi*0.25);
        c = mix(c, vec3(1.0), 0.15);
        color += c * band * (0.5 + 0.5*noise(d*4.0+vec3(t,t*0.7,fi)));
    }

    // Звёзды
    float starNoise = noise(d * 180.0);
    float stars = step(0.985, starNoise) * (1.0 - abs(d.y)*0.5);
    color += vec3(0.9, 0.95, 1.0) * stars;

    color = color / (1.0 + color * 0.4);
    OutColor = vec4(color, 1.0) * ColorModulator * vColor;
}
