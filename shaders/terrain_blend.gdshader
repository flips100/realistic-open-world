shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

/* Photoreal-leaning multi-layer PBR terrain:
   grass / dirt / rock / cliff / snow by height + slope + micro-noise.
   Triplanar albedo + normals + roughness; wetness near water_level. */

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D cliff_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D snow_albedo : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D detail_rough : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro_noise : hint_default_white, filter_linear_mipmap, repeat_enable;

uniform float uv_scale : hint_range(1.0, 200.0) = 36.0;
uniform float uv_scale_detail : hint_range(0.5, 80.0) = 12.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 1.05;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.82;
uniform float height_grass_max : hint_range(0.0, 80.0) = 28.0;
uniform float height_rock_start : hint_range(0.0, 80.0) = 30.0;
uniform float height_snow_start : hint_range(0.0, 100.0) = 46.0;
uniform float slope_rock : hint_range(0.0, 1.0) = 0.48;
uniform float slope_cliff : hint_range(0.0, 1.0) = 0.72;
uniform float water_level : hint_range(-5.0, 20.0) = 3.5;
uniform float wetness_distance : hint_range(0.5, 20.0) = 6.0;
uniform float ao_strength : hint_range(0.0, 1.0) = 0.35;

uniform vec3 grass_tint : source_color = vec3(0.28, 0.48, 0.20);
uniform vec3 dirt_tint : source_color = vec3(0.42, 0.30, 0.17);
uniform vec3 rock_tint : source_color = vec3(0.46, 0.45, 0.48);
uniform vec3 cliff_tint : source_color = vec3(0.34, 0.33, 0.36);
uniform vec3 snow_tint : source_color = vec3(0.90, 0.93, 0.96);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 triplanar_blend(vec3 world_n) {
	vec3 blend = abs(world_n);
	blend = pow(blend, vec3(4.0));
	blend /= (blend.x + blend.y + blend.z + 1e-5);
	return blend;
}

vec3 triplanar_albedo(sampler2D tex, vec3 world_pos, vec3 world_n, float scale) {
	vec3 blend = triplanar_blend(world_n);
	vec3 x = texture(tex, world_pos.zy * scale).rgb;
	vec3 y = texture(tex, world_pos.xz * scale).rgb;
	vec3 z = texture(tex, world_pos.xy * scale).rgb;
	return x * blend.x + y * blend.y + z * blend.z;
}

float triplanar_r(sampler2D tex, vec3 world_pos, vec3 world_n, float scale) {
	vec3 blend = triplanar_blend(world_n);
	float x = texture(tex, world_pos.zy * scale).r;
	float y = texture(tex, world_pos.xz * scale).r;
	float z = texture(tex, world_pos.xy * scale).r;
	return x * blend.x + y * blend.y + z * blend.z;
}

vec3 triplanar_normal(sampler2D tex, vec3 world_pos, vec3 world_n, float scale) {
	vec3 blend = triplanar_blend(world_n);
	vec3 nx = texture(tex, world_pos.zy * scale).xyz * 2.0 - 1.0;
	vec3 ny = texture(tex, world_pos.xz * scale).xyz * 2.0 - 1.0;
	vec3 nz = texture(tex, world_pos.xy * scale).xyz * 2.0 - 1.0;
	return normalize(nx * blend.x + ny * blend.y + nz * blend.z);
}

void fragment() {
	float scale = 1.0 / uv_scale;
	float scale_d = 1.0 / uv_scale_detail;
	vec3 wn = normalize(v_world_normal);
	float slope = 1.0 - clamp(wn.y, 0.0, 1.0);
	float h = v_world_pos.y;

	float macro = triplanar_r(macro_noise, v_world_pos, wn, 1.0 / 180.0);
	float micro = triplanar_r(detail_rough, v_world_pos, wn, scale_d);

	vec3 grass = triplanar_albedo(grass_albedo, v_world_pos, wn, scale) * grass_tint;
	vec3 dirt = triplanar_albedo(dirt_albedo, v_world_pos, wn, scale * 1.15) * dirt_tint;
	vec3 rock = triplanar_albedo(rock_albedo, v_world_pos, wn, scale * 0.85) * rock_tint;
	vec3 cliff = triplanar_albedo(cliff_albedo, v_world_pos, wn, scale * 0.55) * cliff_tint;
	vec3 snow = triplanar_albedo(snow_albedo, v_world_pos, wn, scale * 0.7) * snow_tint;

	// Dual-scale albedo to break tiling (macro + detail)
	grass = mix(grass, grass * (0.85 + macro * 0.3), 0.45);
	dirt = mix(dirt, dirt * (0.8 + micro * 0.35), 0.4);
	rock *= 0.88 + micro * 0.22;

	float dirt_w = smoothstep(1.5, 9.0, h);
	float patch = smoothstep(0.35, 0.65, macro);
	vec3 ground = mix(dirt, grass, dirt_w * (0.55 + patch * 0.45));

	float rock_h = smoothstep(height_rock_start - 5.0, height_rock_start + 8.0, h);
	ground = mix(ground, rock, rock_h * 0.9);

	float slope_w = smoothstep(slope_rock, slope_cliff, slope);
	ground = mix(ground, cliff, slope_w);

	float snow_w = smoothstep(height_snow_start - 4.0, height_snow_start + 10.0, h);
	snow_w *= (1.0 - slope * 0.75) * smoothstep(0.25, 0.7, macro);
	ground = mix(ground, snow, clamp(snow_w, 0.0, 1.0));

	// Shoreline / basin wetness -- darker, glossier near water
	float wet = 1.0 - smoothstep(water_level, water_level + wetness_distance, h);
	wet *= (1.0 - slope_w) * smoothstep(0.15, 0.55, 1.0 - slope);
	ground = mix(ground, ground * vec3(0.55, 0.58, 0.62), wet * 0.65);

	ground *= mix(vec3(0.90), COLOR.rgb * 1.12, 0.5);
	// Cheap contact AO from slope concavity proxy
	float ao = mix(1.0, 0.72 + micro * 0.2, ao_strength * (0.35 + slope * 0.4));
	ground *= ao;

	float rough_tex = triplanar_r(detail_rough, v_world_pos, wn, scale);
	float rough = mix(roughness_base, 0.96, slope_w * 0.7);
	rough = mix(rough, 0.55 + rough_tex * 0.35, 0.55);
	rough = mix(rough, 0.18 + rough_tex * 0.12, wet); // wet = glossy
	rough = mix(rough, 0.92, clamp(snow_w, 0.0, 1.0) * 0.5);

	ALBEDO = ground;
	ROUGHNESS = clamp(rough, 0.05, 1.0);
	METALLIC = 0.0;
	SPECULAR = mix(0.45, 0.7, wet);

	vec3 nmap = triplanar_normal(detail_normal, v_world_pos, wn, scale * 1.25);
	vec3 nmap2 = triplanar_normal(detail_normal, v_world_pos, wn, scale_d);
	nmap = normalize(mix(nmap, nmap2, 0.35));
	NORMAL_MAP = normalize(mix(vec3(0.5, 0.5, 1.0), nmap * 0.5 + 0.5, normal_strength));
	NORMAL_MAP_DEPTH = normal_strength * mix(1.0, 0.55, wet);
}
