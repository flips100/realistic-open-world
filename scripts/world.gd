extends Node3D
## Open-world scene: terrain, lighting, player, crystals, UI.

const CollectibleScript := preload("res://scripts/collectible.gd")
const PlayerScript := preload("res://scripts/player.gd")

@onready var terrain: Node3D = $Terrain
@onready var world_env: WorldEnvironment = $WorldEnvironment


func _ready() -> void:
	_setup_environment()
	await get_tree().process_frame
	_spawn_player()
	_spawn_crystals()
	_spawn_landmark()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.25, 0.45, 0.75)
	sky_mat.sky_horizon_color = Color(0.72, 0.82, 0.92)
	sky_mat.ground_bottom_color = Color(0.2, 0.18, 0.14)
	sky_mat.ground_horizon_color = Color(0.55, 0.6, 0.5)
	sky_mat.sun_angle_max = 30.0
	sky.sky_material = sky_mat
	env.sky = sky

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.05

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.7, 0.78, 0.88)
	env.fog_density = 0.0018
	env.fog_aerial_perspective = 0.4
	env.fog_sky_affect = 0.6
	env.fog_depth_begin = 90.0
	env.fog_depth_end = 340.0

	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.15

	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.5

	world_env.environment = env


func _spawn_player() -> void:
	var player := CharacterBody3D.new()
	player.set_script(PlayerScript)
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	var spawn_y: float = terrain.get_height_at(0.0, 0.0) + 2.0
	player.position = Vector3(0, spawn_y, 0)
	add_child(player)


func _spawn_crystals() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var count := GameManager.TOTAL_CRYSTALS
	var placed := 0
	var attempts := 0
	var min_dist := 35.0
	var positions: Array[Vector3] = []

	while placed < count and attempts < 200:
		attempts += 1
		var angle := (TAU / float(count)) * float(placed) + rng.randf_range(-0.3, 0.3)
		var radius := rng.randf_range(40.0, 160.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		var y: float = terrain.get_height_at(x, z) + 1.5
		if y > 36.0:
			continue
		var ok := true
		for p in positions:
			if Vector2(p.x, p.z).distance_to(Vector2(x, z)) < min_dist:
				ok = false
				break
		if not ok:
			continue
		var crystal := Area3D.new()
		crystal.set_script(CollectibleScript)
		crystal.position = Vector3(x, y, z)
		crystal.name = "Crystal_%d" % placed
		add_child(crystal)
		positions.append(crystal.position)
		placed += 1


func _spawn_landmark() -> void:
	var landmark := Node3D.new()
	landmark.name = "StandingStones"
	var center_y: float = terrain.get_height_at(8.0, -12.0)
	landmark.position = Vector3(8, center_y, -12)

	for i in range(5):
		var stone := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.8, 2.5 + i * 0.3, 0.5)
		stone.mesh = box
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.55, 0.55, 0.58)
		mat.roughness = 0.9
		stone.material_override = mat
		var a := (TAU / 5.0) * float(i)
		stone.position = Vector3(cos(a) * 4.0, box.size.y * 0.5, sin(a) * 4.0)
		stone.rotation.y = -a
		landmark.add_child(stone)

		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		body.add_child(col)
		stone.add_child(body)

	var pedestal := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.2
	cyl.bottom_radius = 1.4
	cyl.height = 0.4
	pedestal.mesh = cyl
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.4, 0.45, 0.5)
	pmat.emission_enabled = true
	pmat.emission = Color(0.2, 0.5, 0.7)
	pmat.emission_energy_multiplier = 0.6
	pedestal.material_override = pmat
	pedestal.position.y = 0.2
	landmark.add_child(pedestal)

	add_child(landmark)
