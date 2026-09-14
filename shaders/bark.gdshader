shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo_color : source_color = vec4(0.36, 0.22, 0.13, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.94;
uniform float uv_scale : hint_range(0.1, 8.0) = 2.2;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.95;
uniform float vertical_stretch : hint_range(0.5, 4.0) = 2.4;

void fragment() {
	vec2 uv = vec2(UV.x * uv_scale, UV.y * uv_scale * vertical_stretch);
	vec3 tex = texture(albedo_tex, uv).rgb;
	float rtex = texture(rough_tex, uv).r;
	float streak = texture(albedo_tex, vec2(UV.x * 0.5, UV.y * 6.0)).r;
	ALBEDO = albedo_color.rgb * mix(vec3(0.78), tex, 0.75) * mix(0.88, 1.08, streak);
	ROUGHNESS = clamp(mix(roughness, rtex, 0.45), 0.4, 1.0);
	METALLIC = 0.0;
	SPECULAR = 0.3;
	NORMAL_MAP = texture(normal_tex, uv).rgb;
	NORMAL_MAP_DEPTH = normal_strength;
}
