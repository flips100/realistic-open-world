extends Node3D
## Open-world scene: cinematic daylight, volumetric fog, water, atmosphere, player, crystals.

const CollectibleScript := preload("res://scripts/collectible.gd")
const PlayerScript := preload("res://scripts/player.gd")
const AmbientAudioScript := preload("res://scripts/ambient_audio.gd")
const WaterPlaneScript := preload("res://scripts/water_plane.gd")
const AtmosphereFxScript := preload("res://scripts/atmosphere_fx.gd")

@onready var terrain: Node3D = $Terrain
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var fill_light: DirectionalLight3D = $FillLight


func _ready() -> void:
	if terrain:
		terrain.add_to_group("terrain")
	_setup_environment()
	_setup_sun()
	_spawn_systems()
	await get_tree().process_frame
	_spawn_player()
	_spawn_crystals()
	_spawn_landmark()


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	# Photographic daylight sky (PhysicalSky when available, Procedural fallback)
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.22, 0.42, 0.72)
	sky_mat.sky_horizon_color = Color(0.85, 0.72, 0.55)  # warm golden-hour haze
	sky_mat.ground_bottom_color = Color(0.18, 0.16, 0.12)
	sky_mat.ground_horizon_color = Color(0.62, 0.55, 0.42)
	sky_mat.sun_angle_max = 28.0
	sky_mat.sky_curve = 0.12
	sky_mat.ground_curve = 0.08
	sky.sky_material = sky_mat
	env.sky = sky
	env.sky_rotation = Vector3(0, 0.3, 0)

	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.48
	env.ambient_light_sky_contribution = 1.0
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# Filmic / ACES tonemap for photographic contrast
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.98
	env.tonemap_white = 6.0

	# Distance fog matching warm horizon
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.82, 0.74, 0.62)
	env.fog_density = 0.0012
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.75
	env.fog_depth_begin = 70.0
	env.fog_depth_end = 320.0
	env.fog_depth_curve = 0.85

	# Volumetric fog (Forward+): soft god-ray haze
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.008
	env.volumetric_fog_albedo = Color(0.85, 0.78, 0.68)
	env.volumetric_fog_emission = Color(0.15, 0.12, 0.08)
	env.volumetric_fog_emission_energy = 0.02
	env.volumetric_fog_anisotropy = 0.35
	env.volumetric_fog_length = 128.0
	env.volumetric_fog_detail_spread = 0.7
	env.volumetric_fog_ambient_inject = 0.35
	env.volumetric_fog_sky_affect = 0.5

	env.glow_enabled = true
	env.glow_intensity = 0.42
	env.glow_strength = 0.9
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.85
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT

	env.ssao_enabled = true
	env.ssao_radius = 1.8
	env.ssao_intensity = 2.0
	env.ssao_power = 1.5
	env.ssao_detail = 0.5
	env.ssao_horizon = 0.06

	env.ssr_enabled = true
	env.ssr_max_steps = 48
	env.ssr_fade_in = 0.15
	env.ssr_fade_out = 2.0
	env.ssr_depth_tolerance = 0.2

	env.adjustment_enabled = true
	env.adjustment_brightness = 1.02
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08

	world_env.environment = env


func _setup_sun() -> void:
	# Golden-hour / late afternoon sun -- warm key light
	sun.light_color = Color(1.0, 0.88, 0.68)
	sun.light_energy = 1.55
	sun.light_angular_distance = 0.6
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = 300.0
	sun.shadow_blur = 1.25
	sun.directional_shadow_pancake_size = 4.0
	# Low warm angle
	sun.rotation_degrees = Vector3(-38, -42, 0)

	fill_light.light_color = Color(0.45, 0.58, 0.82)
	fill_light.light_energy = 0.22
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(-25, 130, 0)


func _spawn_systems() -> void:
	var water := Node3D.new()
	water.name = "Water"
	water.set_script(WaterPlaneScript)
	add_child(water)

	var atmos := Node3D.new()
	atmos.name = "AtmosphereFX"
	atmos.set_script(AtmosphereFxScript)
	add_child(atmos)

	var amb := Node3D.new()
	amb.name = "AmbientAudio"
	amb.set_script(AmbientAudioScript)
	add_child(amb)


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

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.52, 0.51, 0.50)
	stone_mat.roughness = 0.94
	var n := FastNoiseLite.new()
	n.frequency = 0.12
	n.seed = 44
	var ntex := NoiseTexture2D.new()
	ntex.noise = n
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = ntex
	stone_mat.albedo_texture = ntex
	stone_mat.uv1_triplanar = true
	stone_mat.uv1_scale = Vector3(2, 2, 2)

	for i in range(5):
		var stone := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.85, 2.6 + i * 0.35, 0.55)
		stone.mesh = box
		stone.material_override = stone_mat
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
	pmat.albedo_color = Color(0.42, 0.44, 0.48)
	pmat.roughness = 0.55
	pmat.metallic = 0.25
	pmat.emission_enabled = true
	pmat.emission = Color(0.25, 0.55, 0.7)
	pmat.emission_energy_multiplier = 0.45
	pedestal.material_override = pmat
	pedestal.position.y = 0.2
	landmark.add_child(pedestal)

	add_child(landmark)
