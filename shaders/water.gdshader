shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec3 shallow_color : source_color = vec3(0.15, 0.45, 0.48);
uniform vec3 deep_color : source_color = vec3(0.05, 0.18, 0.28);
uniform float roughness : hint_range(0.0, 1.0) = 0.08;
uniform float metallic : hint_range(0.0, 1.0) = 0.15;
uniform float wave_scale : hint_range(0.01, 2.0) = 0.08;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.35;
uniform float wave_height : hint_range(0.0, 1.0) = 0.12;
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.75;
uniform float fresnel_power : hint_range(1.0, 8.0) = 3.5;
uniform float opacity : hint_range(0.0, 1.0) = 0.82;

varying vec3 v_world_pos;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w1 = sin(v_world_pos.x * wave_scale * 6.0 + TIME * wave_speed * 2.0);
	float w2 = cos(v_world_pos.z * wave_scale * 5.0 + TIME * wave_speed * 1.6);
	VERTEX.y += (w1 + w2) * wave_height * 0.5;
}

void fragment() {
	vec2 uv1 = v_world_pos.xz * wave_scale + vec2(TIME * wave_speed * 0.05, TIME * wave_speed * 0.03);
	vec2 uv2 = v_world_pos.xz * wave_scale * 1.4 + vec2(-TIME * wave_speed * 0.04, TIME * wave_speed * 0.025);
	vec3 n1 = texture(normal_a, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(normal_b, uv2).xyz * 2.0 - 1.0;
	vec3 n = normalize(mix(vec3(0.0, 0.0, 1.0), normalize(n1 + n2), normal_strength));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;

	float fres = pow(1.0 - clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0), fresnel_power);
	vec3 col = mix(deep_color, shallow_color, fres * 0.65 + 0.2);
	ALBEDO = col;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	ALPHA = mix(opacity, 0.95, fres);
	SPECULAR = 0.6;
}
