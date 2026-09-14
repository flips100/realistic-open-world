extends Node3D
## Photographic lake plane: reflections (SSR), fresnel, dual normals, shoreline.

@export var water_size: float = 200.0
@export var water_height_offset: float = 3.2


func _ready() -> void:
	await get_tree().process_frame
	var terrain := get_parent().get_node_or_null("Terrain")
	var y := water_height_offset
	if terrain and terrain.has_method("get_height_at"):
		y = minf(terrain.get_height_at(40.0, 40.0), terrain.get_height_at(-30.0, 50.0)) - 0.35
		y = clampf(y, 2.0, 8.0)
		if "WATER_LEVEL" in terrain:
			y = minf(y, float(terrain.get("WATER_LEVEL")))

	var mi := MeshInstance3D.new()
	mi.name = "WaterMesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(water_size, water_size)
	plane.subdivide_width = 96
	plane.subdivide_depth = 96
	mi.mesh = plane
	mi.position = Vector3(25, y, 35)
	mi.material_override = _build_water_mat()
	# Help SSR / reflections
	mi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mi)

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(water_size, 0.5, water_size)
	col.shape = box
	col.position.y = -0.4
	body.add_child(col)
	mi.add_child(body)


func _noise_normal(seed_v: int, freq: float, bump: float) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.fractal_octaves = 4
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 512
	t.height = 512
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = bump
	t.generate_mipmaps = true
	return t


func _build_water_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader") as Shader
	mat.set_shader_parameter("shallow_color", Color(0.20, 0.50, 0.48))
	mat.set_shader_parameter("deep_color", Color(0.02, 0.09, 0.16))
	mat.set_shader_parameter("shore_color", Color(0.06, 0.15, 0.17))
	mat.set_shader_parameter("roughness", 0.04)
	mat.set_shader_parameter("metallic", 0.04)
	mat.set_shader_parameter("wave_scale", 0.05)
	mat.set_shader_parameter("wave_speed", 0.32)
	mat.set_shader_parameter("wave_height", 0.07)
	mat.set_shader_parameter("normal_a", _noise_normal(901, 0.035, 4.5))
	mat.set_shader_parameter("normal_b", _noise_normal(902, 0.055, 3.5))
	mat.set_shader_parameter("normal_strength", 0.62)
	mat.set_shader_parameter("fresnel_power", 4.5)
	mat.set_shader_parameter("opacity", 0.90)
	mat.set_shader_parameter("refraction_strength", 0.04)
	mat.set_shader_parameter("specular_boost", 1.2)
	return mat
