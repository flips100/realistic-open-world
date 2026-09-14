extends Node3D
## Distant pollen / dust motes + subtle ground mist for photographic atmosphere.

func _ready() -> void:
	_spawn_pollen()
	_spawn_ground_haze()


func _spawn_pollen() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Pollen"
	particles.amount = 96
	particles.lifetime = 14.0
	particles.preprocess = 5.0
	particles.visibility_aabb = AABB(Vector3(-140, -10, -140), Vector3(280, 70, 280))
	particles.position = Vector3(0, 10, 0)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(100, 20, 100)
	mat.direction = Vector3(0.35, 0.04, 0.18)
	mat.spread = 28.0
	mat.initial_velocity_min = 0.12
	mat.initial_velocity_max = 0.5
	mat.gravity = Vector3(0, -0.015, 0)
	mat.scale_min = 0.025
	mat.scale_max = 0.07
	mat.color = Color(0.96, 0.93, 0.78, 0.5)
	particles.process_material = mat

	var draw := SphereMesh.new()
	draw.radius = 0.5
	draw.height = 1.0
	draw.radial_segments = 4
	draw.rings = 2
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(1, 0.96, 0.82, 0.4)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.emission_enabled = true
	dmat.emission = Color(0.92, 0.88, 0.65)
	dmat.emission_energy_multiplier = 0.3
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material = dmat
	particles.draw_pass_1 = draw
	add_child(particles)


func _spawn_ground_haze() -> void:
	## Soft low mist sheet near lake / valley floor
	var particles := GPUParticles3D.new()
	particles.name = "GroundHaze"
	particles.amount = 40
	particles.lifetime = 18.0
	particles.preprocess = 8.0
	particles.visibility_aabb = AABB(Vector3(-80, -5, -80), Vector3(160, 30, 160))
	particles.position = Vector3(25, 4, 35)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(55, 2.5, 55)
	mat.direction = Vector3(0.2, 0.02, 0.1)
	mat.spread = 40.0
	mat.initial_velocity_min = 0.05
	mat.initial_velocity_max = 0.2
	mat.gravity = Vector3(0, 0.005, 0)
	mat.scale_min = 2.5
	mat.scale_max = 5.0
	mat.color = Color(0.85, 0.82, 0.75, 0.08)
	particles.process_material = mat

	var draw := SphereMesh.new()
	draw.radius = 1.0
	draw.height = 1.6
	draw.radial_segments = 6
	draw.rings = 3
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(0.9, 0.88, 0.82, 0.06)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.disable_receive_shadows = true
	draw.material = dmat
	particles.draw_pass_1 = draw
	particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(particles)
