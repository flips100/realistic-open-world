shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_opaque;

/* Translucent-ish leaves with layered wind (gust + flutter), not rubber sway. */

uniform vec4 albedo_color : source_color = vec4(0.16, 0.40, 0.14, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.78;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.28;
uniform float wind_speed : hint_range(0.0, 4.0) = 0.95;
uniform float wind_height_influence : hint_range(0.0, 2.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.35);
uniform float translucency : hint_range(0.0, 1.0) = 0.22;
uniform float ao_lift : hint_range(0.0, 0.3) = 0.06;

varying float v_height_factor;
varying float v_facing;

void vertex() {
	float phase = float(INSTANCE_ID) * 0.173 + (MODEL_MATRIX[3].x + MODEL_MATRIX[3].z) * 0.05;
	float h = max(VERTEX.y, 0.0);
	v_height_factor = clamp(h * wind_height_influence * 0.55, 0.0, 2.2);
	float t = TIME * wind_speed + phase;
	vec2 dir = normalize(wind_direction);
	// Primary gust (slow) + secondary flutter (fast, small)
	float gust = sin(t * 0.55 + VERTEX.x * 0.15 + VERTEX.z * 0.12) * 0.7
		+ sin(t * 0.23 + phase) * 0.3;
	float flutter = sin(t * 3.1 + VERTEX.y * 4.0 + phase * 2.0) * 0.12
		+ cos(t * 4.7 + VERTEX.x * 5.0) * 0.06;
	float sway = (gust + flutter) * wind_strength * v_height_factor;
	VERTEX.x += dir.x * sway;
	VERTEX.z += dir.y * sway;
	VERTEX.y += abs(flutter) * wind_strength * 0.08 * v_height_factor;
	v_facing = abs(NORMAL.y);
}

void fragment() {
	vec3 tex = texture(albedo_tex, UV * 2.5).rgb;
	vec3 base = albedo_color.rgb * mix(vec3(0.92), tex, 0.6);
	// Slight darkening toward branch (UV center proxy via V)
	base *= mix(0.78, 1.05, clamp(UV.y, 0.0, 1.0));
	ALBEDO = base;
	ROUGHNESS = mix(roughness, 0.92, 0.2);
	METALLIC = 0.0;
	SPECULAR = 0.25;
	// Cheap translucency / SSS stand-in: emission lifts when facing light-ish via NORMAL
	float leaf_thin = mix(translucency, translucency * 0.4, v_facing);
	EMISSION = albedo_color.rgb * (ao_lift + leaf_thin * 0.08);
}
