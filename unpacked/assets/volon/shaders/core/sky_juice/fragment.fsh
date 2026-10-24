#version 150

uniform float Time;
uniform vec3 Accent;
uniform vec3 Accent2;
uniform vec3 StarColor;
uniform vec4 ColorModulator;
in vec3 Direction;
in vec4 vColor;
out vec4 OutColor;

// ---------- Шумовые функции ----------
float hash21(vec2 p) {
    p = fract(p * vec2(443.8975, 397.2973));
    p += dot(p, p + 19.19);
    return fract(p.x * p.y);
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

float smoothNoise2D(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash21(i);
    float b = hash21(i + vec2(1.0, 0.0));
    float c = hash21(i + vec2(0.0, 1.0));
    float d = hash21(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0, a = 0.5, freq = 1.0;
    for (int k = 0; k < 5; k++) {
        v += a * smoothNoise2D(p * freq);
        freq *= 2.1;
        a *= 0.48;
    }
    return v;
}

vec2 warp(vec2 p, float t) {
    vec2 q = vec2(fbm(p + vec2(0.0, 0.0) + t * 0.12),
                  fbm(p + vec2(5.2, 1.3) + t * 0.09));
    vec2 r = vec2(fbm(p + 4.0 * q + vec2(1.7, 9.2) + t * 0.06),
                  fbm(p + 4.0 * q + vec2(8.3, 2.8) + t * 0.07));
    return p + 1.8 * r;
}

// ---------- МОЛНИЯ ----------
float lightningSegment(vec2 p, vec2 a, vec2 b, float thickness) {
    vec2 pa = p - a;
    vec2 ba = b - a;
    float h = clamp(dot(pa, ba) / dot(ba, ba), 0.0, 1.0);
    float d = length(pa - ba * h);
    return exp(-d * d / (thickness * thickness));
}

// Молния с заданными начальной и конечной позицией
float lightningBoltCustom(vec2 p, vec2 start, vec2 end, float seed, float thickness) {
    float bolt = 0.0;
    int segments = 14;
    vec2 current = start;
    vec2 prev = start;
    
    for (int i = 0; i < segments; i++) {
        float t = float(i) / float(segments - 1);
        vec2 target = mix(start, end, t);
        
        // Случайное смещение
        float offsetX = (hash12(vec2(seed * 10.0 + float(i), seed * 3.0)) - 0.5) * 0.25 * (1.0 - t * 0.7);
        float offsetY = (hash12(vec2(seed * 7.0 + float(i), seed * 1.5)) - 0.5) * 0.05 * sin(t * 3.14);
        
        current = target + vec2(offsetX, offsetY);
        
        if (i > 0) {
            bolt += lightningSegment(p, prev, current, thickness);
        }
        prev = current;
        
        // Ответвления
        if (i > 4 && i < segments - 3) {
            float branch = hash12(vec2(seed * 5.0 + float(i), seed * 2.0));
            if (branch > 0.7) {
                vec2 branchEnd = current + vec2((branch - 0.7) * 6.0 * 0.15 * (1.0 - t), -0.1 * (1.0 - t));
                bolt += lightningSegment(p, current, branchEnd, thickness * 0.4);
            }
        }
    }
    
    return bolt;
}

// Вспышка молнии
float lightningFlash(float time, float seed, float flashDuration) {
    float cycle = fract(time * 0.12 + seed * 0.7);
    float flash = 0.0;
    
    // Основная вспышка
    float flashStart = 0.25 + seed * 0.15;
    float flashEnd = flashStart + flashDuration;
    
    if (cycle > flashStart && cycle < flashEnd) {
        float flashT = (cycle - flashStart) / flashDuration;
        flash = exp(-flashT * 10.0) * 2.0;
    }
    
    // Эхо вспышки
    float flash2Start = flashStart + 0.12;
    float flash2End = flash2Start + flashDuration * 0.5;
    if (cycle > flash2Start && cycle < flash2End) {
        float flash2T = (cycle - flash2Start) / (flashDuration * 0.5);
        flash = max(flash, exp(-flash2T * 7.0) * 0.7);
    }
    
    return flash;
}

void main() {
    vec3 dir = normalize(Direction);
    vec2 uv = dir.xz * 0.5 + 0.5;
    float time = Time;
    float anim = time * 0.5;
    
    float up = clamp(dir.y, 0.0, 1.0);
    float horizonFade = smoothstep(-0.15, 0.05, dir.y);
    if (horizonFade < 0.005) discard;
    
    // Дрейф
    vec3 drift = vec3(0.0, anim * 0.025, anim * 0.04);
    
    // Координаты для молний (разные области неба)
    vec2 p = dir.xz * 1.0 + drift.xz * 0.9;
    p.y += dir.y * 0.2;
    
    // Варпинг для фона
    float t = anim * 0.045;
    vec2 wp = warp(p, t);
    
    // Слои фона
    float n1 = fbm(wp * 0.9 + vec2(0.0, 0.0));
    float n2 = fbm(wp * 1.5 + vec2(2.7, 4.3));
    float n3 = fbm(wp * 0.5 + vec2(-1.8, 3.1));
    float n4 = fbm(wp * 2.2 + vec2(-3.0, 1.2));
    
    float juice = (n1 * 0.4 + n2 * 0.25 + n3 * 0.20 + n4 * 0.15);
    juice = smoothstep(0.15, 0.85, juice);
    
    float heightMask = 0.7 + 0.3 * smoothstep(0.0, 0.6, up);
    float flicker = 0.8 + 0.2 * sin(anim * 0.5 + dir.x * 14.0 + dir.z * 10.0);
    flicker *= 0.9 + 0.1 * sin(anim * 0.9 + dir.y * 18.0);
    juice = juice * heightMask * flicker;
    
    // Блестки
    float glitter = 0.0;
    for (int i = 0; i < 3; i++) {
        float seed = float(i) * 2.13;
        vec2 pos = vec2(
            0.5 + 0.8 * sin(seed * 1.7 + anim * 0.2 + p.x * 0.5),
            0.5 + 0.8 * cos(seed * 2.3 + anim * 0.15 + p.y * 0.5)
        );
        float d = length(uv - pos);
        float sz = 0.01 + 0.02 * sin(seed * 3.1 + anim * 0.3);
        glitter += exp(-d * d / (2.0 * sz * sz)) * 0.6;
    }
    glitter *= (0.7 + 0.3 * sin(anim * 0.6 + p.x * 5.0));
    
    // Цвет фона
    float mix1 = 0.5 + 0.5 * sin(anim * 0.06 + p.x * 1.2 + p.y * 0.8 + juice * 1.5);
    float mix2 = 0.5 + 0.5 * cos(anim * 0.08 + p.x * 0.9 - p.y * 1.1 + juice * 2.0);
    vec3 color1 = mix(Accent, Accent2, mix1);
    vec3 color2 = mix(Accent2, vec3(1.0, 0.9, 0.8), 0.3);
    vec3 color = mix(color1, color2, mix2);
    
    float hot = exp(-abs(juice - 0.4) * 6.0) * 0.6;
    color += vec3(1.0, 0.95, 0.7) * hot;
    color += StarColor * glitter * 0.8;
    
    float bloom = exp(-juice * 3.0) * 0.4;
    color += vec3(0.9, 0.8, 1.0) * bloom * 0.5;
    
    // ---------- 5 МОЛНИЙ В РАЗНЫХ МЕСТАХ НЕБА ----------
    float lightning = 0.0;
    float totalFlash = 0.0;
    
    // Молния 1 - слева
    vec2 start1 = vec2(-0.8, 0.95);
    vec2 end1 = vec2(-0.7, -0.1);
    float bolt1 = lightningBoltCustom(p, start1, end1, 1.0, 0.018);
    float flash1 = lightningFlash(time, 1.0, 0.04);
    lightning += bolt1 * flash1;
    totalFlash = max(totalFlash, flash1);
    
    // Молния 2 - справа
    vec2 start2 = vec2(0.6, 0.9);
    vec2 end2 = vec2(0.55, 0.0);
    float bolt2 = lightningBoltCustom(p, start2, end2, 2.0, 0.015);
    float flash2 = lightningFlash(time + 0.2, 2.0, 0.035);
    lightning += bolt2 * flash2;
    totalFlash = max(totalFlash, flash2);
    
    // Молния 3 - центр
    vec2 start3 = vec2(0.1, 1.0);
    vec2 end3 = vec2(0.0, -0.2);
    float bolt3 = lightningBoltCustom(p, start3, end3, 3.0, 0.02);
    float flash3 = lightningFlash(time + 0.5, 3.0, 0.045);
    lightning += bolt3 * flash3;
    totalFlash = max(totalFlash, flash3);
    
    // Молния 4 - далеко слева
    vec2 start4 = vec2(-1.2, 0.8);
    vec2 end4 = vec2(-1.0, 0.1);
    float bolt4 = lightningBoltCustom(p, start4, end4, 4.0, 0.012);
    float flash4 = lightningFlash(time + 0.8, 4.0, 0.03);
    lightning += bolt4 * flash4;
    totalFlash = max(totalFlash, flash4);
    
    // Молния 5 - далеко справа
    vec2 start5 = vec2(1.1, 0.85);
    vec2 end5 = vec2(1.0, 0.15);
    float bolt5 = lightningBoltCustom(p, start5, end5, 5.0, 0.014);
    float flash5 = lightningFlash(time + 1.1, 5.0, 0.04);
    lightning += bolt5 * flash5;
    totalFlash = max(totalFlash, flash5);
    
    // Цвет молнии
    vec3 lightningColor = vec3(0.9, 0.95, 1.0) * lightning * 3.0;
    vec3 glowColor = vec3(0.4, 0.5, 1.0) * lightning * 1.5;
    
    color += lightningColor;
    color += glowColor;
    
    // Вспышка освещает небо
    color += vec3(0.3, 0.4, 0.8) * totalFlash * 0.8;
    
    // Итог
    float finalIntensity = juice * 1.3 + hot * 0.3 + glitter * 0.4 + lightning * 2.0;
    vec3 finalColor = color * finalIntensity;
    
    float finalAlpha = clamp(finalIntensity * 1.5, 0.0, 1.0) * horizonFade;
    float vignette = 1.0 - length(dir.xz) * 0.15;
    finalAlpha *= clamp(vignette, 0.0, 1.0);
    
    if (finalAlpha < 0.01) discard;
    OutColor = vec4(clamp(finalColor, 0.0, 1.0), finalAlpha) * ColorModulator * vColor;
}