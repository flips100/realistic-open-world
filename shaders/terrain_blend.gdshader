shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

/* Multi-layer terrain: grass / dirt / rock / cliff by height + slope.
   Uses NoiseTexture2D samplers for albedo detail and normals. */

uniform sampler2D grass_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D dirt_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D rock_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D cliff_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D detail_normal : hint_normal, filter_linear_mipmap, repeat_enable;

uniform float uv_scale : hint_range(1.0, 200.0) = 48.0;
uniform float normal_strength : hint_range(0.0, 2.0) = 0.85;
uniform float roughness_base : hint_range(0.0, 1.0) = 0.88;
uniform float height_grass_max : hint_range(0.0, 80.0) = 28.0;
uniform float height_rock_start : hint_range(0.0, 80.0) = 32.0;
uniform float height_snow_start : hint_range(0.0, 100.0) = 48.0;
uniform float slope_rock : hint_range(0.0, 1.0) = 0.55;
uniform float slope_cliff : hint_range(0.0, 1.0) = 0.78;
uniform vec3 grass_tint : source_color = vec3(0.32, 0.52, 0.24);
uniform vec3 dirt_tint : source_color = vec3(0.45, 0.34, 0.20);
uniform vec3 rock_tint : source_color = vec3(0.48, 0.47, 0.50);
uniform vec3 cliff_tint : source_color = vec3(0.38, 0.37, 0.40);
uniform vec3 snow_tint : source_color = vec3(0.92, 0.94, 0.97);

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec3 triplanar_albedo(sampler2D tex, vec3 world_pos, vec3 world_n, float scale) {
	vec3 blend = abs(world_n);
	blend = pow(blend, vec3(4.0));
	blend /= (blend.x + blend.y + blend.z + 1e-5);
	vec3 x = texture(tex, world_pos.zy * scale).rgb;
	vec3 y = texture(tex, world_pos.xz * scale).rgb;
	vec3 z = texture(tex, world_pos.xy * scale).rgb;
	return x * blend.x + y * blend.y + z * blend.z;
}

vec3 triplanar_normal(sampler2D tex, vec3 world_pos, vec3 world_n, float scale) {
	vec3 blend = abs(world_n);
	blend = pow(blend, vec3(4.0));
	blend /= (blend.x + blend.y + blend.z + 1e-5);
	vec3 nx = texture(tex, world_pos.zy * scale).xyz * 2.0 - 1.0;
	vec3 ny = texture(tex, world_pos.xz * scale).xyz * 2.0 - 1.0;
	vec3 nz = texture(tex, world_pos.xy * scale).xyz * 2.0 - 1.0;
	return normalize(nx * blend.x + ny * blend.y + nz * blend.z);
}

void fragment() {
	float scale = 1.0 / uv_scale;
	vec3 wn = normalize(v_world_normal);
	float slope = 1.0 - clamp(wn.y, 0.0, 1.0);
	float h = v_world_pos.y;

	vec3 grass = triplanar_albedo(grass_albedo, v_world_pos, wn, scale) * grass_tint;
	vec3 dirt = triplanar_albedo(dirt_albedo, v_world_pos, wn, scale) * dirt_tint;
	vec3 rock = triplanar_albedo(rock_albedo, v_world_pos, wn, scale) * rock_tint;
	vec3 cliff = triplanar_albedo(cliff_albedo, v_world_pos, wn, scale * 0.7) * cliff_tint;

	float dirt_w = smoothstep(2.0, 8.0, h);
	vec3 ground = mix(dirt, grass, dirt_w);

	float rock_h = smoothstep(height_rock_start - 4.0, height_rock_start + 6.0, h);
	ground = mix(ground, rock, rock_h * 0.85);

	float slope_w = smoothstep(slope_rock, slope_cliff, slope);
	ground = mix(ground, cliff, slope_w);

	float snow_w = smoothstep(height_snow_start - 3.0, height_snow_start + 8.0, h) * (1.0 - slope * 0.7);
	ground = mix(ground, snow_tint, clamp(snow_w, 0.0, 1.0));

	// Vertex color from mesh as subtle tint variation
	ground *= mix(vec3(0.92), COLOR.rgb * 1.15, 0.55);

	ALBEDO = ground;
	ROUGHNESS = mix(roughness_base, 0.97, slope_w);
	METALLIC = 0.0;

	vec3 nmap = triplanar_normal(detail_normal, v_world_pos, wn, scale * 1.4);
	NORMAL_MAP = normalize(mix(vec3(0.5, 0.5, 1.0), nmap * 0.5 + 0.5, normal_strength));
	NORMAL_MAP_DEPTH = normal_strength;
}
