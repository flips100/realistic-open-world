extends Node3D
## Varied trees / rocks / bushes with wind-shaded foliage and denser MultiMesh scatter.

@export var terrain_path: NodePath

const TREE_COUNT := 380
const PINE_COUNT := 160
const ROCK_COUNT := 220
const BUSH_COUNT := 280
const SPREAD := 235.0


func _ready() -> void:
	await get_tree().process_frame
	var terrain := get_node_or_null(terrain_path)
	if terrain == null or not terrain.has_method("get_height_at"):
		push_warning("VegetationSpawner: terrain not found")
		return
	_spawn_deciduous(terrain)
	_spawn_pines(terrain)
	_spawn_rocks(terrain)
	_spawn_bushes(terrain)


func _noise_tex(seed_v: int, freq: float, as_normal: bool = false) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.fractal_octaves = 4
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = 256
	t.height = 256
	t.seamless = true
	t.generate_mipmaps = true
	if as_normal:
		t.as_normal_map = true
		t.bump_strength = 6.0
	return t


func _bark_material(tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/bark.gdshader") as Shader
	mat.set_shader_parameter("albedo_color", tint)
	mat.set_shader_parameter("albedo_tex", _noise_tex(11, 0.15))
	mat.set_shader_parameter("normal_tex", _noise_tex(22, 0.2, true))
	mat.set_shader_parameter("roughness", 0.93)
	mat.set_shader_parameter("uv_scale", 2.5)
	return mat


func _foliage_material(tint: Color, wind: float = 0.35) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/foliage_wind.gdshader") as Shader
	mat.set_shader_parameter("albedo_color", tint)
	mat.set_shader_parameter("albedo_tex", _noise_tex(33, 0.25))
	mat.set_shader_parameter("roughness", 0.86)
	mat.set_shader_parameter("wind_strength", wind)
	mat.set_shader_parameter("wind_speed", 1.05)
	return mat


func _gather_positions(terrain: Node, count: int, seed_v: int, y_min: float, y_max: float, slope_max: float, clear_r: float) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var result: Array[Transform3D] = []
	var attempts := 0
	while result.size() < count and attempts < count * 12:
		attempts += 1
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < clear_r:
			continue
		var y: float = terrain.get_height_at(x, z)
		if y < y_min or y > y_max:
			continue
		var dx: float = terrain.get_height_at(x + 1.0, z) - terrain.get_height_at(x - 1.0, z)
		var dz: float = terrain.get_height_at(x, z + 1.0) - terrain.get_height_at(x, z - 1.0)
		if sqrt(dx * dx + dz * dz) > slope_max:
			continue
		var scale := rng.randf_range(0.7, 1.5)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(scale, scale, scale))
		xf.origin = Vector3(x, y, z)
		result.append(xf)
	return result


func _spawn_deciduous(terrain: Node) -> void:
	var transforms := _gather_positions(terrain, TREE_COUNT, 12345, 4.5, 30.0, 5.5, 14.0)
	var count := transforms.size()
	if count == 0:
		return

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.16
	trunk.bottom_radius = 0.32
	trunk.height = 2.8
	trunk.radial_segments = 10
	trunk.material = _bark_material(Color(0.40, 0.26, 0.14, 1.0))

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk
	trunk_mm.instance_count = count
	var trunk_mmi := MultiMeshInstance3D.new()
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.name = "DeciduousTrunks"
	trunk_mmi.visibility_range_end = 220.0
	trunk_mmi.visibility_range_end_margin = 30.0
	add_child(trunk_mmi)

	# Layered canopy spheres for less "lollipop" look
	var canopy := SphereMesh.new()
	canopy.radius = 1.45
	canopy.height = 2.1
	canopy.radial_segments = 12
	canopy.rings = 7
	canopy.material = _foliage_material(Color(0.20, 0.46, 0.18, 1.0), 0.4)

	var canopy_mm := MultiMesh.new()
	canopy_mm.transform_format = MultiMesh.TRANSFORM_3D
	canopy_mm.mesh = canopy
	canopy_mm.instance_count = count * 2
	var canopy_mmi := MultiMeshInstance3D.new()
	canopy_mmi.multimesh = canopy_mm
	canopy_mmi.name = "DeciduousCanopies"
	canopy_mmi.visibility_range_end = 200.0
	canopy_mmi.visibility_range_end_margin = 25.0
	add_child(canopy_mmi)

	for i in range(count):
		var xf: Transform3D = transforms[i]
		var trunk_xf := xf
		trunk_xf.origin += xf.basis.y * 1.4
		trunk_mm.set_instance_transform(i, trunk_xf)

		var c0 := xf
		c0.origin += xf.basis.y * 3.35
		canopy_mm.set_instance_transform(i * 2, c0)
		var c1 := xf
		c1.basis = c1.basis.scaled(Vector3(0.75, 0.7, 0.75))
		c1.origin += xf.basis.y * 4.3 + xf.basis.x * 0.4
		canopy_mm.set_instance_transform(i * 2 + 1, c1)


func _spawn_pines(terrain: Node) -> void:
	var transforms := _gather_positions(terrain, PINE_COUNT, 55501, 12.0, 36.0, 6.5, 18.0)
	var count := transforms.size()
	if count == 0:
		return

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.1
	trunk.bottom_radius = 0.22
	trunk.height = 4.0
	trunk.radial_segments = 8
	trunk.material = _bark_material(Color(0.32, 0.22, 0.14, 1.0))

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk
	trunk_mm.instance_count = count
	var trunk_mmi := MultiMeshInstance3D.new()
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.name = "PineTrunks"
	trunk_mmi.visibility_range_end = 230.0
	add_child(trunk_mmi)

	# Cone foliage stacks
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 1.4
	cone.height = 2.2
	cone.radial_segments = 10
	cone.material = _foliage_material(Color(0.12, 0.32, 0.18, 1.0), 0.22)

	var cone_mm := MultiMesh.new()
	cone_mm.transform_format = MultiMesh.TRANSFORM_3D
	cone_mm.mesh = cone
	cone_mm.instance_count = count * 3
	var cone_mmi := MultiMeshInstance3D.new()
	cone_mmi.multimesh = cone_mm
	cone_mmi.name = "PineNeedles"
	cone_mmi.visibility_range_end = 210.0
	add_child(cone_mmi)

	for i in range(count):
		var xf: Transform3D = transforms[i]
		var trunk_xf := xf
		trunk_xf.origin += xf.basis.y * 2.0
		trunk_mm.set_instance_transform(i, trunk_xf)
		for layer in range(3):
			var cx := xf
			var s := 1.0 - float(layer) * 0.22
			cx.basis = cx.basis.scaled(Vector3(s, 1.0, s))
			cx.origin += xf.basis.y * (3.0 + float(layer) * 1.35)
			cone_mm.set_instance_transform(i * 3 + layer, cx)


func _spawn_rocks(terrain: Node) -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.75
	rock.height = 1.05
	rock.radial_segments = 10
	rock.rings = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.52, 0.50, 0.47)
	mat.roughness = 0.96
	mat.albedo_texture = _noise_tex(777, 0.1)
	mat.normal_enabled = true
	mat.normal_texture = _noise_tex(778, 0.14, true)
	mat.normal_scale = 0.85
	mat.uv1_scale = Vector3(2.5, 2.5, 2.5)
	mat.uv1_triplanar = true
	rock.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rock
	mm.instance_count = ROCK_COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "Rocks"
	mmi.visibility_range_end = 240.0
	add_child(mmi)

	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(ROCK_COUNT):
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < 8.0:
			x += 15.0
		var y: float = terrain.get_height_at(x, z)
		var s := rng.randf_range(0.35, 2.0)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(
			rng.randf_range(-0.35, 0.35),
			rng.randf() * TAU,
			rng.randf_range(-0.25, 0.25)
		)).scaled(Vector3(s, s * rng.randf_range(0.45, 0.85), s * rng.randf_range(0.7, 1.1)))
		xf.origin = Vector3(x, y + 0.12 * s, z)
		mm.set_instance_transform(i, xf)


func _spawn_bushes(terrain: Node) -> void:
	var bush := SphereMesh.new()
	bush.radius = 0.58
	bush.height = 0.95
	bush.radial_segments = 8
	bush.rings = 4
	bush.material = _foliage_material(Color(0.24, 0.48, 0.20, 1.0), 0.55)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bush
	mm.instance_count = BUSH_COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "Bushes"
	mmi.visibility_range_end = 160.0
	mmi.visibility_range_end_margin = 20.0
	add_child(mmi)

	var transforms := _gather_positions(terrain, BUSH_COUNT, 333, 3.5, 26.0, 7.0, 6.0)
	var placed := mini(transforms.size(), BUSH_COUNT)
	for i in range(placed):
		var xf: Transform3D = transforms[i]
		var s := xf.basis.get_scale()
		xf.basis = Basis.from_euler(Vector3(0, float(i) * 1.7, 0)).scaled(Vector3(s.x, s.y * 0.72, s.z))
		xf.origin.y += 0.22
		mm.set_instance_transform(i, xf)
	if placed < BUSH_COUNT:
		mm.visible_instance_count = placed
