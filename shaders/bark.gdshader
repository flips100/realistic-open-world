shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.38, 0.24, 0.14, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.92;
uniform float uv_scale : hint_range(0.1, 8.0) = 2.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.7;

void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 tex = texture(albedo_tex, uv).rgb;
	ALBEDO = albedo_color.rgb * mix(vec3(0.85), tex, 0.7);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	NORMAL_MAP = texture(normal_tex, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
}
