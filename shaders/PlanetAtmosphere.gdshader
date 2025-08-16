shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always;

uniform sampler2D albedo_tex : source_color;
uniform float scroll_speed = 0.01;
uniform vec4 atm_color : hint_color = vec4(0.2,0.6,1.0,1.0);

void fragment() {
    vec2 uv = UV;
    uv.y += TIME * scroll_speed;
    ALBEDO = texture(albedo_tex, uv).rgb;
    float fresnel = pow(1.0 - dot(normalize(NORMAL), -normalize(VIEW)), 3.0);
    EMISSION = atm_color.rgb * fresnel * atm_color.a;
}
