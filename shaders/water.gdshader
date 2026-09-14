shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

/* Photographic lake: dual-scroll normals, fresnel reflectivity, depth tint,
   subtle refraction-like view distortion via normal, shoreline darkening. */

uniform vec3 shallow_color : source_color = vec3(0.22, 0.52, 0.50);
uniform vec3 deep_color : source_color = vec3(0.02, 0.10, 0.18);
uniform vec3 shore_color : source_color = vec3(0.08, 0.18, 0.20);
uniform float roughness : hint_range(0.0, 1.0) = 0.045;
uniform float metallic : hint_range(0.0, 1.0) = 0.05;
uniform float wave_scale : hint_range(0.01, 2.0) = 0.055;
uniform float wave_speed : hint_range(0.0, 2.0) = 0.28;
uniform float wave_height : hint_range(0.0, 1.0) = 0.08;
uniform sampler2D normal_a : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.65;
uniform float fresnel_power : hint_range(1.0, 10.0) = 4.2;
uniform float fresnel_bias : hint_range(0.0, 0.5) = 0.04;
uniform float opacity : hint_range(0.0, 1.0) = 0.88;
uniform float refraction_strength : hint_range(0.0, 0.2) = 0.035;
uniform float specular_boost : hint_range(0.0, 2.0) = 1.15;

varying vec3 v_world_pos;
varying float v_wave;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float w1 = sin(v_world_pos.x * wave_scale * 5.5 + TIME * wave_speed * 1.8);
	float w2 = cos(v_world_pos.z * wave_scale * 4.2 + TIME * wave_speed * 1.35);
	float w3 = sin((v_world_pos.x + v_world_pos.z) * wave_scale * 2.2 + TIME * wave_speed * 0.7);
	v_wave = (w1 * 0.45 + w2 * 0.35 + w3 * 0.2);
	VERTEX.y += v_wave * wave_height;
}

void fragment() {
	vec2 uv1 = v_world_pos.xz * wave_scale + vec2(TIME * wave_speed * 0.04, TIME * wave_speed * 0.025);
	vec2 uv2 = v_world_pos.xz * wave_scale * 1.65 + vec2(-TIME * wave_speed * 0.032, TIME * wave_speed * 0.02);
	vec2 uv3 = v_world_pos.xz * wave_scale * 0.35 + vec2(TIME * wave_speed * 0.008, -TIME * wave_speed * 0.01);
	vec3 n1 = texture(normal_a, uv1).xyz * 2.0 - 1.0;
	vec3 n2 = texture(normal_b, uv2).xyz * 2.0 - 1.0;
	vec3 n3 = texture(normal_a, uv3).xyz * 2.0 - 1.0;
	vec3 n = normalize(n1 * 0.55 + n2 * 0.35 + n3 * 0.25);
	n = normalize(mix(vec3(0.0, 0.0, 1.0), n, normal_strength));
	NORMAL_MAP = n * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = normal_strength;

	float ndotv = clamp(dot(normalize(VIEW), normalize(NORMAL)), 0.0, 1.0);
	float fres = fresnel_bias + (1.0 - fresnel_bias) * pow(1.0 - ndotv, fresnel_power);

	// Depth-ish tint from view angle + wave (no screen texture needed)
	float depth_proxy = clamp(1.0 - ndotv * 0.65 + abs(v_wave) * 0.15, 0.0, 1.0);
	vec3 col = mix(deep_color, shallow_color, depth_proxy * 0.55 + fres * 0.25);
	// Shore darkening toward mesh edges via world distance from water center-ish
	float shore = smoothstep(55.0, 88.0, length(v_world_pos.xz - vec2(25.0, 35.0)));
	col = mix(col, shore_color, shore * 0.35);

	ALBEDO = col;
	ROUGHNESS = mix(roughness, roughness + 0.12, shore * 0.5);
	METALLIC = metallic;
	// High specular + fresnel alpha so SSR / sky reflections read photographically
	SPECULAR = mix(0.55, specular_boost, fres);
	ALPHA = mix(opacity * 0.92, 0.97, fres);
	EMISSION = shallow_color * fres * 0.015;

	// Hint refraction by slightly shifting albedo with normal (SSR does heavy lifting)
	ALBEDO = mix(ALBEDO, ALBEDO * (1.0 + n.xyx * refraction_strength * 4.0), 0.35);
}
