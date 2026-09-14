shader_type spatial;
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx, depth_draw_opaque;

uniform vec4 albedo_color : source_color = vec4(0.18, 0.42, 0.16, 1.0);
uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float roughness : hint_range(0.0, 1.0) = 0.88;
uniform float wind_strength : hint_range(0.0, 2.0) = 0.35;
uniform float wind_speed : hint_range(0.0, 4.0) = 1.1;
uniform float wind_height_influence : hint_range(0.0, 2.0) = 1.0;
uniform vec2 wind_direction = vec2(1.0, 0.35);

varying float v_height_factor;

void vertex() {
	// INSTANCE_CUSTOM.x can carry a random phase; fall back to origin hash
	float phase = float(INSTANCE_ID) * 0.17;
	float h = max(VERTEX.y, 0.0);
	v_height_factor = clamp(h * wind_height_influence, 0.0, 2.5);
	float t = TIME * wind_speed + phase;
	vec2 dir = normalize(wind_direction);
	float sway = sin(t + VERTEX.x * 0.4 + VERTEX.z * 0.3) * wind_strength * v_height_factor;
	float flutter = sin(t * 2.7 + VERTEX.y * 3.0) * wind_strength * 0.15 * v_height_factor;
	VERTEX.x += dir.x * sway + flutter;
	VERTEX.z += dir.y * sway;
}

void fragment() {
	vec3 tex = texture(albedo_tex, UV).rgb;
	ALBEDO = albedo_color.rgb * mix(vec3(1.0), tex, 0.55);
	ROUGHNESS = roughness;
	METALLIC = 0.0;
	// Slight subsurface-ish lift for leaves (cheap)
	EMISSION = albedo_color.rgb * 0.02;
}
