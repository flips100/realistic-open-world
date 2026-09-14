extends Node3D
## Photoreal-leaning scatter: multi-blob crowns, bark normals, grass MultiMesh, denser cover.

@export var terrain_path: NodePath

const TREE_COUNT := 520
const PINE_COUNT := 260
const ROCK_COUNT := 280
const BUSH_COUNT := 400
const GRASS_TUFT_COUNT := 2800
const SPREAD := 240.0


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
	_spawn_grass_tufts(terrain)


func _noise_tex(seed_v: int, freq: float, as_normal: bool = false, w: int = 256) -> NoiseTexture2D:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = freq
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX
	n.fractal_octaves = 5
	var t := NoiseTexture2D.new()
	t.noise = n
	t.width = w
	t.height = w
	t.seamless = true
	t.generate_mipmaps = true
	if as_normal:
		t.as_normal_map = true
		t.bump_strength = 8.0
	return t


func _bark_material(tint: Color) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/bark.gdshader") as Shader
	mat.set_shader_parameter("albedo_color", tint)
	mat.set_shader_parameter("albedo_tex", _noise_tex(11, 0.14, false, 512))
	mat.set_shader_parameter("normal_tex", _noise_tex(22, 0.18, true, 512))
	mat.set_shader_parameter("rough_tex", _noise_tex(23, 0.12, false, 256))
	mat.set_shader_parameter("roughness", 0.94)
	mat.set_shader_parameter("uv_scale", 2.4)
	mat.set_shader_parameter("normal_strength", 1.0)
	mat.set_shader_parameter("vertical_stretch", 2.6)
	return mat


func _foliage_material(tint: Color, wind: float = 0.28) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://shaders/foliage_wind.gdshader") as Shader
	mat.set_shader_parameter("albedo_color", tint)
	mat.set_shader_parameter("albedo_tex", _noise_tex(33, 0.22, false, 256))
	mat.set_shader_parameter("roughness", 0.8)
	mat.set_shader_parameter("wind_strength", wind)
	mat.set_shader_parameter("wind_speed", 0.9)
	mat.set_shader_parameter("translucency", 0.32)
	return mat


func _gather_positions(terrain: Node, count: int, seed_v: int, y_min: float, y_max: float, slope_max: float, clear_r: float) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var result: Array[Transform3D] = []
	var attempts := 0
	while result.size() < count and attempts < count * 14:
		attempts += 1
		# Soft clustering: occasional bias toward existing points for natural clumps
		var x: float
		var z: float
		if result.size() > 8 and rng.randf() < 0.35:
			var base: Transform3D = result[rng.randi() % result.size()]
			x = base.origin.x + rng.randf_range(-18.0, 18.0)
			z = base.origin.z + rng.randf_range(-18.0, 18.0)
		else:
			x = rng.randf_range(-SPREAD, SPREAD)
			z = rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < clear_r:
			continue
		# Keep clear of lake center
		if Vector2(x - 25.0, z - 35.0).length() < 55.0:
			continue
		var y: float = terrain.get_height_at(x, z)
		if y < y_min or y > y_max:
			continue
		var dx: float = terrain.get_height_at(x + 1.0, z) - terrain.get_height_at(x - 1.0, z)
		var dz: float = terrain.get_height_at(x, z + 1.0) - terrain.get_height_at(x, z - 1.0)
		if sqrt(dx * dx + dz * dz) > slope_max:
			continue
		var scale := rng.randf_range(0.65, 1.55)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(scale, scale, scale))
		xf.origin = Vector3(x, y, z)
		result.append(xf)
	return result


func _spawn_deciduous(terrain: Node) -> void:
	var transforms := _gather_positions(terrain, TREE_COUNT, 12345, 4.5, 30.0, 5.5, 12.0)
	var count := transforms.size()
	if count == 0:
		return

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.14
	trunk.bottom_radius = 0.34
	trunk.height = 3.2
	trunk.radial_segments = 12
	trunk.material = _bark_material(Color(0.45, 0.30, 0.16, 1.0))

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk
	trunk_mm.instance_count = count
	var trunk_mmi := MultiMeshInstance3D.new()
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.name = "DeciduousTrunks"
	trunk_mmi.visibility_range_end = 230.0
	trunk_mmi.visibility_range_end_margin = 35.0
	add_child(trunk_mmi)

	# Irregular multi-blob crown (3-4 spheres) -- less lollipop
	var canopy := SphereMesh.new()
	canopy.radius = 1.35
	canopy.height = 2.0
	canopy.radial_segments = 14
	canopy.rings = 8
	canopy.material = _foliage_material(Color(0.30, 0.52, 0.22, 1.0), 0.30)

	var blobs_per := 5
	var canopy_mm := MultiMesh.new()
	canopy_mm.transform_format = MultiMesh.TRANSFORM_3D
	canopy_mm.mesh = canopy
	canopy_mm.instance_count = count * blobs_per
	var canopy_mmi := MultiMeshInstance3D.new()
	canopy_mmi.multimesh = canopy_mm
	canopy_mmi.name = "DeciduousCanopies"
	canopy_mmi.visibility_range_end = 210.0
	canopy_mmi.visibility_range_end_margin = 30.0
	add_child(canopy_mmi)

	var offsets := [
		Vector3(0.0, 3.5, 0.0),
		Vector3(0.7, 4.1, 0.35),
		Vector3(-0.65, 3.95, -0.4),
		Vector3(0.2, 4.9, 0.15),
		Vector3(-0.25, 4.55, 0.55),
	]
	var scales := [
		Vector3(1.25, 1.0, 1.2),
		Vector3(0.95, 0.8, 1.0),
		Vector3(0.9, 0.75, 0.95),
		Vector3(0.7, 0.65, 0.75),
		Vector3(0.75, 0.7, 0.8),
	]

	for i in range(count):
		var xf: Transform3D = transforms[i]
		var trunk_xf := xf
		trunk_xf.origin += xf.basis.y * 1.6
		trunk_mm.set_instance_transform(i, trunk_xf)
		for b in range(blobs_per):
			var cx := xf
			cx.basis = cx.basis.scaled(scales[b])
			cx.origin += xf.basis * offsets[b]
			canopy_mm.set_instance_transform(i * blobs_per + b, cx)


func _spawn_pines(terrain: Node) -> void:
	var transforms := _gather_positions(terrain, PINE_COUNT, 55501, 11.0, 38.0, 6.5, 16.0)
	var count := transforms.size()
	if count == 0:
		return

	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.08
	trunk.bottom_radius = 0.24
	trunk.height = 5.0
	trunk.radial_segments = 10
	trunk.material = _bark_material(Color(0.36, 0.24, 0.14, 1.0))

	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk
	trunk_mm.instance_count = count
	var trunk_mmi := MultiMeshInstance3D.new()
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.name = "PineTrunks"
	trunk_mmi.visibility_range_end = 240.0
	add_child(trunk_mmi)

	var cone := CylinderMesh.new()
	cone.top_radius = 0.04
	cone.bottom_radius = 1.55
	cone.height = 2.4
	cone.radial_segments = 12
	cone.material = _foliage_material(Color(0.18, 0.40, 0.22, 1.0), 0.16)

	var layers := 5
	var cone_mm := MultiMesh.new()
	cone_mm.transform_format = MultiMesh.TRANSFORM_3D
	cone_mm.mesh = cone
	cone_mm.instance_count = count * layers
	var cone_mmi := MultiMeshInstance3D.new()
	cone_mmi.multimesh = cone_mm
	cone_mmi.name = "PineNeedles"
	cone_mmi.visibility_range_end = 220.0
	add_child(cone_mmi)

	for i in range(count):
		var xf: Transform3D = transforms[i]
		var trunk_xf := xf
		trunk_xf.origin += xf.basis.y * 2.5
		trunk_mm.set_instance_transform(i, trunk_xf)
		for layer in range(layers):
			var cx := xf
			var s := 1.05 - float(layer) * 0.2
			cx.basis = cx.basis.scaled(Vector3(s, 0.95, s))
			cx.origin += xf.basis.y * (3.2 + float(layer) * 1.25)
			cone_mm.set_instance_transform(i * layers + layer, cx)


func _spawn_rocks(terrain: Node) -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.78
	rock.height = 1.1
	rock.radial_segments = 12
	rock.rings = 7
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.62, 0.60, 0.56)
	mat.roughness = 0.94
	mat.albedo_texture = _noise_tex(777, 0.09, false, 512)
	mat.normal_enabled = true
	mat.normal_texture = _noise_tex(778, 0.13, true, 512)
	mat.normal_scale = 1.05
	mat.uv1_scale = Vector3(2.2, 2.2, 2.2)
	mat.uv1_triplanar = true
	rock.material = mat

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rock
	mm.instance_count = ROCK_COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "Rocks"
	mmi.visibility_range_end = 250.0
	add_child(mmi)

	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(ROCK_COUNT):
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < 8.0:
			x += 15.0
		if Vector2(x - 25.0, z - 35.0).length() < 50.0:
			x += 40.0
		var y: float = terrain.get_height_at(x, z)
		var s := rng.randf_range(0.3, 2.1)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(
			rng.randf_range(-0.4, 0.4),
			rng.randf() * TAU,
			rng.randf_range(-0.3, 0.3)
		)).scaled(Vector3(s, s * rng.randf_range(0.4, 0.8), s * rng.randf_range(0.65, 1.15)))
		xf.origin = Vector3(x, y + 0.1 * s, z)
		mm.set_instance_transform(i, xf)


func _spawn_bushes(terrain: Node) -> void:
	var bush := SphereMesh.new()
	bush.radius = 0.55
	bush.height = 0.9
	bush.radial_segments = 10
	bush.rings = 5
	bush.material = _foliage_material(Color(0.34, 0.55, 0.24, 1.0), 0.42)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bush
	mm.instance_count = BUSH_COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "Bushes"
	mmi.visibility_range_end = 170.0
	mmi.visibility_range_end_margin = 25.0
	add_child(mmi)

	var transforms := _gather_positions(terrain, BUSH_COUNT, 333, 3.5, 26.0, 7.0, 5.0)
	var placed := mini(transforms.size(), BUSH_COUNT)
	for i in range(placed):
		var xf: Transform3D = transforms[i]
		var s := xf.basis.get_scale()
		xf.basis = Basis.from_euler(Vector3(0, float(i) * 1.7, 0)).scaled(Vector3(s.x * 1.1, s.y * 0.68, s.z * 1.05))
		xf.origin.y += 0.2
		mm.set_instance_transform(i, xf)
	if placed < BUSH_COUNT:
		mm.visible_instance_count = placed


func _spawn_grass_tufts(terrain: Node) -> void:
	## Dense ground cover as thin stretched spheres / capsules (clumps), MultiMesh
	var blade := CapsuleMesh.new()
	blade.radius = 0.04
	blade.height = 0.55
	blade.radial_segments = 4
	blade.rings = 2
	blade.material = _foliage_material(Color(0.38, 0.58, 0.22, 1.0), 0.65)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = blade
	mm.instance_count = GRASS_TUFT_COUNT
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.name = "GrassTufts"
	mmi.visibility_range_end = 95.0
	mmi.visibility_range_end_margin = 15.0
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mmi)

	var rng := RandomNumberGenerator.new()
	rng.seed = 99101
	var placed := 0
	var attempts := 0
	while placed < GRASS_TUFT_COUNT and attempts < GRASS_TUFT_COUNT * 8:
		attempts += 1
		var x := rng.randf_range(-SPREAD * 0.85, SPREAD * 0.85)
		var z := rng.randf_range(-SPREAD * 0.85, SPREAD * 0.85)
		if Vector2(x, z).length() < 4.0:
			continue
		if Vector2(x - 25.0, z - 35.0).length() < 58.0:
			continue
		var y: float = terrain.get_height_at(x, z)
		if y < 4.0 or y > 24.0:
			continue
		var dx: float = terrain.get_height_at(x + 1.0, z) - terrain.get_height_at(x - 1.0, z)
		var dz: float = terrain.get_height_at(x, z + 1.0) - terrain.get_height_at(x, z - 1.0)
		if sqrt(dx * dx + dz * dz) > 5.0:
			continue
		# Clump: place 1-3 blades close together by reusing nearby offsets in transform scale
		var s := rng.randf_range(0.7, 1.4)
		var lean := rng.randf_range(-0.15, 0.15)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(lean, rng.randf() * TAU, lean * 0.5)).scaled(Vector3(s, s * rng.randf_range(0.8, 1.3), s))
		xf.origin = Vector3(x, y + 0.12, z)
		mm.set_instance_transform(placed, xf)
		placed += 1
	if placed < GRASS_TUFT_COUNT:
		mm.visible_instance_count = placed
