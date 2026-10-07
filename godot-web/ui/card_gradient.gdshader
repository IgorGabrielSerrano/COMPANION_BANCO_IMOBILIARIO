shader_type canvas_item;
uniform vec2 rect_size = vec2(350.0,112.0);
uniform float radius = 14.0;
void fragment() {
    vec2 p = UV * rect_size;
    vec2 q = abs(p - rect_size * 0.5) - rect_size * 0.5 + vec2(radius);
    float distance = length(max(q,vec2(0.0))) + min(max(q.x,q.y),0.0) - radius;
    COLOR = texture(TEXTURE,UV);
    COLOR.a *= 1.0 - smoothstep(-1.0,1.0,distance);
}
