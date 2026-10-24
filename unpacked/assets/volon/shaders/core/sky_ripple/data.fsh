#version 150

uniform sampler2D DiffuseSampler;
uniform float Time;           Передается из рендера для анимации
uniform vec4 ColorModulator;  Передается из рендера для окраски в цвет темы

in vec2 texCoord0;
in vec4 vertexColor;

out vec4 fragColor;

void main() {
     1. Сдвигаем координаты и масштабируем, чтобы было больше линий
     (texCoord0 идет от 0 до 1, умножение на 2.5 делает узор плотнее)
    vec2 uv = texCoord0  2.5;
    
     2. Создаем плавное движение по времени (скорость 0.8)
    float time = 10.0;
    
     3. Генерируем две волны, которые пересекаются под углом
     Это создает эффект переливающихся лент как на фото
    float wave1 = sin(uv.x  10.0 + time)  cos(uv.y  8.0 + time  0.7);
    float wave2 = cos(uv.x  7.0 - time  1.2)  sin(uv.y  12.0 + time  0.5);
    
     4. Смешиваем волны и сдвигаем диапазон из [-1, 1] в [0, 1]
    float pattern = (wave1 + wave2)  0.5 + 0.5;
    
     5. Получаем цвет темы клиента (передается через униформу)
    vec4 themeColor = ColorModulator  vertexColor;
    
     6. Создаем радужныйпереливающийся эффект (HSV-like сдвиг)
     Цвет будет переливаться в зависимости от значения pattern
    float r = themeColor.r  (0.8 + 0.4  sin(pattern  6.283 + 0.0));
    float g = themeColor.g  (0.8 + 0.4  sin(pattern  6.283 + 2.094));
    float b = themeColor.b  (0.8 + 0.4  sin(pattern  6.283 + 4.188));
    
     7. Добавляем небольшое затухание к краям неба (чтобы выглядело естественнее)
    float fade = 1.0 - abs(texCoord0.y - 0.5)  0.4;
    
     Итоговый цвет с прозрачностью (непрозрачность 0.95)
    fragColor = vec4(r, g, b, 0.95)  fade;
}