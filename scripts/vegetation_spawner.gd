extends Node3D
## Scatters trees, rocks, and bushes via MultiMeshInstance3D.

@export var terrain_path: NodePath

const TREE_COUNT := 260
const ROCK_COUNT := 150
const BUSH_COUNT := 180
const SPREAD := 230.0


func _ready() -> void:
	await get_tree().process_frame
	var terrain := get_node_or_null(terrain_path)
	if terrain == null or not terrain.has_method("get_height_at"):
		push_warning("VegetationSpawner: terrain not found")
		return
	_spawn_trees(terrain)
	_spawn_rocks(terrain)
	_spawn_bushes(terrain)


func _gather_tree_transforms(terrain: Node) -> Array[Transform3D]:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var result: Array[Transform3D] = []
	var attempts := 0
	while result.size() < TREE_COUNT and attempts < TREE_COUNT * 10:
		attempts += 1
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < 14.0:
			continue
		var y: float = terrain.get_height_at(x, z)
		if y < 4.0 or y > 32.0:
			continue
		var dx: float = terrain.get_height_at(x + 1.0, z) - terrain.get_height_at(x - 1.0, z)
		var dz: float = terrain.get_height_at(x, z + 1.0) - terrain.get_height_at(x, z - 1.0)
		if sqrt(dx * dx + dz * dz) > 6.0:
			continue
		var scale := rng.randf_range(0.75, 1.45)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(0, rng.randf() * TAU, 0)).scaled(Vector3(scale, scale, scale))
		xf.origin = Vector3(x, y, z)
		result.append(xf)
	return result


func _spawn_trees(terrain: Node) -> void:
	var transforms := _gather_tree_transforms(terrain)
	var count := transforms.size()
	if count == 0:
		return

	# Trunks
	var trunk := CylinderMesh.new()
	trunk.top_radius = 0.18
	trunk.bottom_radius = 0.3
	trunk.height = 2.5
	trunk.radial_segments = 8
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.36, 0.22, 0.12)
	trunk_mat.roughness = 0.9
	trunk.material = trunk_mat

	var trunk_mmi := MultiMeshInstance3D.new()
	var trunk_mm := MultiMesh.new()
	trunk_mm.transform_format = MultiMesh.TRANSFORM_3D
	trunk_mm.mesh = trunk
	trunk_mm.instance_count = count
	trunk_mmi.multimesh = trunk_mm
	trunk_mmi.name = "TreeTrunks"
	add_child(trunk_mmi)

	# Canopies
	var canopy := SphereMesh.new()
	canopy.radius = 1.35
	canopy.height = 2.3
	canopy.radial_segments = 10
	canopy.rings = 6
	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.17, 0.42, 0.15)
	canopy_mat.roughness = 0.85
	canopy.material = canopy_mat

	var canopy_mmi := MultiMeshInstance3D.new()
	var canopy_mm := MultiMesh.new()
	canopy_mm.transform_format = MultiMesh.TRANSFORM_3D
	canopy_mm.mesh = canopy
	canopy_mm.instance_count = count
	canopy_mmi.multimesh = canopy_mm
	canopy_mmi.name = "TreeCanopies"
	add_child(canopy_mmi)

	for i in range(count):
		var xf: Transform3D = transforms[i]
		var trunk_xf := xf
		trunk_xf.origin += xf.basis.y * 1.25
		trunk_mm.set_instance_transform(i, trunk_xf)

		var canopy_xf := xf
		canopy_xf.origin += xf.basis.y * 3.1
		canopy_mm.set_instance_transform(i, canopy_xf)


func _spawn_rocks(terrain: Node) -> void:
	var rock := SphereMesh.new()
	rock.radius = 0.7
	rock.height = 1.0
	rock.radial_segments = 8
	rock.rings = 4
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.5, 0.48, 0.45)
	mat.roughness = 0.95
	rock.material = mat

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = rock
	mm.instance_count = ROCK_COUNT
	mmi.multimesh = mm
	mmi.name = "Rocks"
	add_child(mmi)

	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	for i in range(ROCK_COUNT):
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		if Vector2(x, z).length() < 8.0:
			x += 15.0
		var y: float = terrain.get_height_at(x, z)
		var s := rng.randf_range(0.4, 1.8)
		var xf := Transform3D()
		xf.basis = Basis.from_euler(Vector3(
			rng.randf_range(-0.3, 0.3),
			rng.randf() * TAU,
			rng.randf_range(-0.2, 0.2)
		)).scaled(Vector3(s, s * rng.randf_range(0.5, 0.9), s))
		xf.origin = Vector3(x, y + 0.15 * s, z)
		mm.set_instance_transform(i, xf)


func _spawn_bushes(terrain: Node) -> void:
	var bush := SphereMesh.new()
	bush.radius = 0.55
	bush.height = 0.9
	bush.radial_segments = 6
	bush.rings = 3
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.5, 0.18)
	mat.roughness = 0.9
	bush.material = mat

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = bush
	mm.instance_count = BUSH_COUNT
	mmi.multimesh = mm
	mmi.name = "Bushes"
	add_child(mmi)

	var rng := RandomNumberGenerator.new()
	rng.seed = 333
	var placed := 0
	var attempts := 0
	while placed < BUSH_COUNT and attempts < BUSH_COUNT * 8:
		attempts += 1
		var x := rng.randf_range(-SPREAD, SPREAD)
		var z := rng.randf_range(-SPREAD, SPREAD)
		var y: float = terrain.get_height_at(x, z)
		if y < 3.0 or y > 28.0:
			continue
		var s := rng.randf_range(0.5, 1.2)
		var xf := Transform3D()
		xf.basis = Basis.IDENTITY.scaled(Vector3(s, s * 0.7, s))
		xf.origin = Vector3(x, y + 0.2, z)
		mm.set_instance_transform(placed, xf)
		placed += 1
	if placed < BUSH_COUNT:
		mm.visible_instance_count = placed
