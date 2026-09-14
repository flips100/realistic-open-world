extends Node3D
## Open-world scene: reliable daylight (ProceduralSky + Compatibility fallback), water, player, crystals.

const CollectibleScript := preload("res://scripts/collectible.gd")
const PlayerScript := preload("res://scripts/player.gd")
const AmbientAudioScript := preload("res://scripts/ambient_audio.gd")
const WaterPlaneScript := preload("res://scripts/water_plane.gd")
const AtmosphereFxScript := preload("res://scripts/atmosphere_fx.gd")

## Performance knobs -- flip these for mid/low GPUs (see README).
const ENABLE_VOLUMETRIC_FOG := true
const ENABLE_SSR := true
const ENABLE_SSIL := true
const ENABLE_DOF := false
const SHADOW_MAX_DISTANCE := 280.0

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
	_spawn_landmark()
	if _compat_mode:
		print("Realistic Open World: Compatibility/OpenGL lighting path active (brighter ambient, no volumetric/SSR/SSIL). Prefer Forward+ on a real GPU.")


func _detect_compatibility() -> bool:
	var method := str(ProjectSettings.get_setting("rendering/renderer/rendering_method", "forward_plus"))
	if method == "gl_compatibility" or method == "mobile":
		return true
	# Runtime driver check (Godot 4.x)
	if RenderingServer.has_method("get_current_rendering_method"):
		var cur := str(RenderingServer.call("get_current_rendering_method"))
		if cur == "gl_compatibility" or cur == "mobile":
			return true
	var driver := ""
	if RenderingServer.has_method("get_current_rendering_driver_name"):
		driver = str(RenderingServer.get_current_rendering_driver_name()).to_lower()
	if "opengl" in driver or "gl_" in driver:
		return true
	return false


func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	# ProceduralSky -- reads reliably on Forward+ AND Compatibility (PhysicalSky often fails / blacks out on OpenGL)
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.38, 0.58, 0.92)
	sky_mat.sky_horizon_color = Color(0.92, 0.78, 0.62)
	sky_mat.sky_curve = 0.09
	sky_mat.sky_energy_multiplier = 1.35 if _compat_mode else 1.2
	sky_mat.ground_bottom_color = Color(0.28, 0.24, 0.18)
	sky_mat.ground_horizon_color = Color(0.78, 0.68, 0.52)
	sky_mat.ground_curve = 0.08
	sky_mat.ground_energy_multiplier = 1.05
	sky_mat.sun_angle_max = 28.0
	sky_mat.sun_curve = 0.12
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	# High ambient so terrain/water stay readable even if Forward+ features soft-fail
	env.ambient_light_energy = 1.05 if _compat_mode else 0.72
	env.ambient_light_sky_contribution = 1.0
	env.ambient_light_color = Color(0.85, 0.88, 0.95)
	env.reflected_light_source = Environment.REFLECTION_SOURCE_SKY

	# Filmic but brighter than v1.2 (fixes underexposure)
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC if _compat_mode else Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.25 if _compat_mode else 1.12
	env.tonemap_white = 6.0

	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Color(0.88, 0.80, 0.68)
	env.fog_density = 0.0007 if _compat_mode else 0.0009
	env.fog_aerial_perspective = 0.55
	env.fog_sky_affect = 0.55
	env.fog_depth_begin = 80.0
	env.fog_depth_end = 380.0
	env.fog_depth_curve = 0.75

	var use_vol := ENABLE_VOLUMETRIC_FOG and not _compat_mode
	if use_vol:
		env.volumetric_fog_enabled = true
		env.volumetric_fog_density = 0.0045
		env.volumetric_fog_albedo = Color(0.90, 0.84, 0.74)
		env.volumetric_fog_emission = Color(0.14, 0.12, 0.08)
		env.volumetric_fog_emission_energy = 0.02
		env.volumetric_fog_anisotropy = 0.35
		env.volumetric_fog_length = 120.0
		env.volumetric_fog_detail_spread = 0.6
		env.volumetric_fog_ambient_inject = 0.55
		env.volumetric_fog_sky_affect = 0.4
	else:
		env.volumetric_fog_enabled = false

	env.glow_enabled = true
	env.glow_intensity = 0.28
	env.glow_strength = 0.8
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.0
	env.glow_hdr_scale = 1.4
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(1, 0.0)
	env.set_glow_level(2, 0.5)
	env.set_glow_level(3, 0.75)
	env.set_glow_level(4, 0.4)
	env.set_glow_level(5, 0.15)

	# Softer SSAO so it doesn't crush midtones (esp. Compatibility where it may no-op or misbehave)
	if not _compat_mode:
		env.ssao_enabled = true
		env.ssao_radius = 1.6
		env.ssao_intensity = 1.6
		env.ssao_power = 1.4
		env.ssao_detail = 0.5
		env.ssao_horizon = 0.06
		env.ssao_sharpness = 0.65
	else:
		env.ssao_enabled = false

	if ENABLE_SSIL and not _compat_mode:
		env.ssil_enabled = true
		env.ssil_radius = 3.5
		env.ssil_intensity = 0.7
		env.ssil_sharpness = 0.65
	else:
		env.ssil_enabled = false

	if ENABLE_SSR and not _compat_mode:
		env.ssr_enabled = true
		env.ssr_max_steps = 48
		env.ssr_fade_in = 0.15
		env.ssr_fade_out = 2.0
		env.ssr_depth_tolerance = 0.2
	else:
		env.ssr_enabled = false

	env.adjustment_enabled = true
	env.adjustment_brightness = 1.08 if _compat_mode else 1.04
	env.adjustment_contrast = 1.06
	env.adjustment_saturation = 1.08

	world_env.environment = env

	# Fixed exposure -- auto-exposure was a common cause of "pitch black" first seconds / Compatibility quirks
	var attrs := CameraAttributesPractical.new()
	attrs.auto_exposure_enabled = false
	if ENABLE_DOF and not _compat_mode:
		attrs.dof_blur_far_enabled = true
		attrs.dof_blur_far_distance = 100.0
		attrs.dof_blur_far_transition = 50.0
		attrs.dof_blur_amount = 0.06
	world_env.camera_attributes = attrs


func _setup_sun() -> void:
	# Bright late-afternoon / golden hour that still fills the valley
	sun.light_color = Color(1.0, 0.92, 0.76)
	sun.light_energy = 2.1 if _compat_mode else 1.85
	sun.light_angular_distance = 0.6
	sun.light_specular = 0.9
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS
	sun.directional_shadow_max_distance = SHADOW_MAX_DISTANCE
	sun.shadow_blur = 1.5
	sun.directional_shadow_pancake_size = 3.5
	sun.directional_shadow_split_1 = 0.08
	sun.directional_shadow_split_2 = 0.22
	sun.directional_shadow_split_3 = 0.5
	sun.rotation_degrees = Vector3(-38, -42, 0)

	fill_light.light_color = Color(0.55, 0.68, 0.95)
	fill_light.light_energy = 0.45 if _compat_mode else 0.32
	fill_light.light_specular = 0.15
	fill_light.shadow_enabled = false
	fill_light.rotation_degrees = Vector3(-25, 140, 0)

	# Extra soft sky bounce for Compatibility so shadows aren't inky black
	if _compat_mode:
		var bounce := DirectionalLight3D.new()
		bounce.name = "SkyBounce"
		bounce.light_color = Color(0.7, 0.8, 1.0)
		bounce.light_energy = 0.28
		bounce.shadow_enabled = false
		bounce.rotation_degrees = Vector3(-70, 20, 0)
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
	pmat.emission_energy_multiplier = 0.55
	pedestal.material_override = pmat
	pedestal.position.y = 0.2
	landmark.add_child(pedestal)

	add_child(landmark)
