extends Node3D
## Reflective / refractive water plane with animated normals.

@export var water_size: float = 180.0
@export var water_height_offset: float = 3.2


func _ready() -> void:
	await get_tree().process_frame
	var terrain := get_parent().get_node_or_null("Terrain")
	var y := water_height_offset
	if terrain and terrain.has_method("get_height_at"):
		# Place water near low basin around origin
		y = minf(terrain.get_height_at(40.0, 40.0), terrain.get_height_at(-30.0, 50.0)) - 0.5
		y = clampf(y, 2.0, 8.0)

	var mi := MeshInstance3D.new()
	mi.name = "WaterMesh"
	var plane := PlaneMesh.new()
	plane.size = Vector2(water_size, water_size)
	plane.subdivide_width = 64
	plane.subdivide_depth = 64
	mi.mesh = plane
	mi.position = Vector3(25, y, 35)
	mi.material_override = _build_water_mat()
	add_child(mi)

	# Soft collision so player can stand at shore edge feeling (thin box under surface)
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


func _noise_normal(seed_v: int) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = 0.04
	n.fractal_octaves = 3
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	t.as_normal_map = true
	t.bump_strength = 5.0
	t.generate_mipmaps = true
	return t


func _build_water_mat() -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/water.gdshader") as Shader
	mat.set_shader_parameter("shallow_color", Color(0.18, 0.48, 0.52))
	mat.set_shader_parameter("deep_color", Color(0.04, 0.16, 0.26))
	mat.set_shader_parameter("roughness", 0.06)
	mat.set_shader_parameter("metallic", 0.2)
	mat.set_shader_parameter("wave_scale", 0.07)
	mat.set_shader_parameter("wave_speed", 0.4)
	mat.set_shader_parameter("wave_height", 0.1)
	mat.set_shader_parameter("normal_a", _noise_normal(901))
	mat.set_shader_parameter("normal_b", _noise_normal(902))
	mat.set_shader_parameter("normal_strength", 0.8)
	mat.set_shader_parameter("opacity", 0.78)
	return mat
