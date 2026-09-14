extends Node3D
## Open-world scene v2: cinematic daylight (Forward+ + Compatibility), water, player, crystals, shrine, flowers.

const CollectibleScript := preload("res://scripts/collectible.gd")
const PlayerScript := preload("res://scripts/player.gd")
const AmbientAudioScript := preload("res://scripts/ambient_audio.gd")
const WaterPlaneScript := preload("res://scripts/water_plane.gd")
const AtmosphereFxScript := preload("res://scripts/atmosphere_fx.gd")
const ShrineScript := preload("res://scripts/shrine.gd")
const SidePickupScript := preload("res://scripts/side_pickup.gd")

## Performance knobs -- flip these for mid/low GPUs (see README).
const ENABLE_VOLUMETRIC_FOG := true
const ENABLE_SSR := true
const ENABLE_SSIL := true
const ENABLE_DOF := false
const SHADOW_MAX_DISTANCE := 300.0

@onready var terrain: Node3D = $Terrain
@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun: DirectionalLight3D = $Sun
@onready var fill_light: DirectionalLight3D = $FillLight

var _compat_mode: bool = false


func _ready() -> void:
	_compat_mode = _detect_compatibility()
	if terrain:
		terrain.add_to_group("terrain")
	_setup_environment()
	_setup_sun()
	_spawn_systems()
	await get_tree().process_frame
	_spawn_player()
	_spawn_crystals()
	_spawn_flowers()
	_spawn_landmark()
	_spawn_shrine()
	_spawn_watchtower()
	if _compat_mode:
		print("Realistic Open World v2: Compatibility/OpenGL lighting path active. Prefer Forward+ on a real GPU.")


func _detect_compatibility() -> bool:
	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
	return method == "gl_compatibility" or method == "mobile"


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.32, 0.55, 0.92)
	sky_mat.sky_horizon_color = Color(0.95, 0.78, 0.58)
	sky_mat.sky_curve = 0.085
	sky_mat.sky_energy_multiplier = 1.45 if _compat_mode else 1.28
	sky_mat.ground_bottom_color = Color(0.26, 0.22, 0.16)
	sky_mat.ground_horizon_color = Color(0.82, 0.70, 0.52)
	sky_mat.ground_curve = 0.07
	sky_mat.ground_energy_multiplier = 1.1
	sky_mat.sun_angle_max = 30.0
	sky_mat.sun_curve = 0.1
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 1.15 if _compat_mode else 0.78
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_color = Color(0.88, 0.90, 0.96)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC if _compat_mode else Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.28 if _compat_mode else 1.15
	env.tonemap_white = 6.2

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.90, 0.82, 0.68)
	env.fog_density = 0.00065 if _compat_mode else 0.00085
	env.fog_aerial_perspective = 0.6
	env.fog_sky_affect = 0.5
	env.fog_depth_begin = 90.0
	env.fog_depth_end = 420.0
	env.fog_depth_curve = 0.72

	var use_vol := ENABLE_VOLUMETRIC_FOG and not _compat_mode
	if use_vol:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0042
		env.volumetric_fog_albedo = Color(0.92, 0.86, 0.75)
		env.volumetric_fog_emission = Color(0.16, 0.13, 0.08)
		env.volumetric_fog_emission_energy = 0.025
		env.volumetric_fog_anisotropy = 0.32
		env.volumetric_fog_length = 130.0
		env.volumetric_fog_detail_spread = 0.55
		env.volumetric_fog_ambient_inject = 0.6
		env.volumetric_fog_sky_affect = 0.38
	else:
		env.volumetric_fog_enabled = false

	env.glow_enabled = true
	env.glow_intensity = 0.32
	env.glow_strength = 0.85
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95
	env.glow_hdr_scale = 1.5
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(1, 0.0)
	env.set_glow_level(2, 0.55)
	env.set_glow_level(3, 0.8)
	env.set_glow_level(4, 0.45)
	env.set_glow_level(5, 0.18)

	if not _compat_mode:
		env.ssao_enabled = true
		env.ssao_radius = 1.5
		env.ssao_intensity = 1.45
		env.ssao_power = 1.35
		env.ssao_detail = 0.45
		env.ssao_horizon = 0.05
		env.ssao_sharpness = 0.7
	else:
		env.ssao_enabled = false

	if ENABLE_SSIL and not _compat_mode:
		env.ssil_enabled = true
		env.ssil_radius = 3.8
		env.ssil_intensity = 0.75
		env.ssil_sharpness = 0.7
	else:
		env.ssil_enabled = false

	if ENABLE_SSR and not _compat_mode:
		env.ssr_enabled = true
		env.ssr_max_steps = 56
		env.ssr_fade_in = 0.12
		env.ssr_fade_out = 2.2
		env.ssr_depth_tolerance = 0.18
	else:
		env.ssr_enabled = false

	env.adjustment_enabled = true
	env.adjustment_brightness = 1.1 if _compat_mode else 1.05
	env.adjustment_contrast = 1.07
	env.adjustment_saturation = 1.1

	world_env.environment = env

	# Fixed exposure — avoids auto-exposure crush on llvmpipe / first frames
	var attrs := CameraAttributesPractical.new()
	attrs.auto_exposure_enabled = false
	if ENABLE_DOF and not _compat_mode:
		attrs.dof_blur_far_enabled = true
		attrs.dof_blur_far_distance = 110.0
		attrs.dof_blur_far_transition = 55.0
		attrs.dof_blur_amount = 0.05
	world_env.camera_attributes = attrs


func _setup_sun() -> void:
	sun.light_color = Color(1.0, 0.93, 0.78)
	sun.light_energy = 2.25 if _compat_mode else 1.95
	sun.light_angular_distance = 0.55
	sun.light_specular = 0.95
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = SHADOW_MAX_DISTANCE
	sun.shadow_blur = 1.6
	sun.directional_shadow_pancake_size = 3.5
	sun.directional_shadow_split_1 = 0.07
	sun.directional_shadow_split_2 = 0.2
	sun.directional_shadow_split_3 = 0.48
	sun.rotation_degrees = Vector3(-36, -45, 0)

	fill_light.light_color = Color(0.52, 0.68, 0.98)
	fill_light.light_energy = 0.5 if _compat_mode else 0.36
	fill_light.light_specular = 0.12
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(-22, 145, 0)

	# Soft bounce always — helps valley floors stay readable
	var bounce := DirectionalLight3D.new()
	bounce.name = "SkyBounce"
	bounce.light_color = Color(0.65, 0.78, 1.0)
	bounce.light_energy = 0.32 if _compat_mode else 0.16
	bounce.shadow_enabled = false
	bounce.rotation_degrees = Vector3(-72, 25, 0)
	add_child(bounce)


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
	var min_dist := 38.0
	var positions: Array[Vector3] = []

	while placed < count and attempts < 220:
		attempts += 1
		var angle := (TAU / float(count)) * float(placed) + rng.randf_range(-0.28, 0.28)
		var radius := rng.randf_range(45.0, 175.0)
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


func _spawn_flowers() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4044
	var placed := 0
	var attempts := 0
	while placed < GameManager.TOTAL_FLOWERS and attempts < 120:
		attempts += 1
		var angle := rng.randf() * TAU
		var radius := rng.randf_range(18.0, 90.0)
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		if Vector2(x - 25.0, z - 35.0).length() < 50.0:
			continue
		var y: float = terrain.get_height_at(x, z) + 0.05
		if y < 4.0 or y > 22.0:
			continue
		var flower := Area3D.new()
		flower.set_script(SidePickupScript)
		flower.position = Vector3(x, y, z)
		flower.name = "Flower_%d" % placed
		add_child(flower)
		placed += 1


func _spawn_shrine() -> void:
	var shrine := Area3D.new()
	shrine.set_script(ShrineScript)
	shrine.name = "LakesideShrine"
	# Near lake shore
	var sx := 48.0
	var sz := 55.0
	var sy: float = terrain.get_height_at(sx, sz)
	shrine.position = Vector3(sx, sy, sz)
	add_child(shrine)


func _spawn_landmark() -> void:
	var landmark := Node3D.new()
	landmark.name = "StandingStones"
	var center_y: float = terrain.get_height_at(8.0, -12.0)
	landmark.position = Vector3(8, center_y, -12)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.58, 0.56, 0.52)
	stone_mat.roughness = 0.9
	var n := FastNoiseLite.new()
	n.frequency = 0.11
	n.seed = 44
	n.fractal_octaves = 4
	var ntex := NoiseTexture2D.new()
	ntex.noise = n
	ntex.width = 512
	ntex.height = 512
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 10.0
	ntex.generate_mipmaps = true
	var atex := NoiseTexture2D.new()
	atex.noise = n
	atex.width = 512
	atex.height = 512
	atex.seamless = true
	atex.generate_mipmaps = true
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = ntex
	stone_mat.normal_scale = 1.1
	stone_mat.albedo_texture = atex
	stone_mat.uv1_triplanar = true
	stone_mat.uv1_scale = Vector3(1.8, 1.8, 1.8)

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
	pmat.albedo_color = Color(0.42, 0.46, 0.52)
	pmat.roughness = 0.45
	pmat.metallic = 0.3
	pmat.emission_enabled = true
	pmat.emission = Color(0.25, 0.55, 0.7)
	pmat.emission_energy_multiplier = 0.65
	pedestal.material_override = pmat
	pedestal.position.y = 0.2
	landmark.add_child(pedestal)

	add_child(landmark)


func _spawn_watchtower() -> void:
	## Distant ruin arch / watchtower landmark on a ridge
	var tower := Node3D.new()
	tower.name = "WatchtowerRuin"
	var tx := -95.0
	var tz := 70.0
	var ty: float = terrain.get_height_at(tx, tz)
	tower.position = Vector3(tx, ty, tz)

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.52, 0.48)
	mat.roughness = 0.92
	var n := FastNoiseLite.new()
	n.seed = 66
	n.frequency = 0.09
	var ntex := NoiseTexture2D.new()
	ntex.noise = n
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 9.0
	mat.normal_enabled = true
	mat.normal_texture = ntex
	mat.uv1_triplanar = true

	# Two pillars + lintel = ruin arch
	for side in [-1.0, 1.0]:
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.9, 7.5, 0.9)
		pillar.mesh = box
		pillar.material_override = mat
		pillar.position = Vector3(side * 1.6, 3.75, 0)
		tower.add_child(pillar)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = box.size
		col.shape = shape
		body.add_child(col)
		pillar.add_child(body)

	var lintel := MeshInstance3D.new()
	var lb := BoxMesh.new()
	lb.size = Vector3(4.2, 0.7, 1.1)
	lintel.mesh = lb
	lintel.material_override = mat
	lintel.position = Vector3(0, 7.6, 0)
	tower.add_child(lintel)

	# Platform
	var plat := MeshInstance3D.new()
	var pb := BoxMesh.new()
	pb.size = Vector3(5.5, 0.4, 4.0)
	plat.mesh = pb
	plat.material_override = mat
	plat.position = Vector3(0, 0.2, 0)
	tower.add_child(plat)

	add_child(tower)
