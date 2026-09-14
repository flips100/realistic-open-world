extends Node3D
## Distant pollen / dust motes for outdoor atmosphere.

func _ready() -> void:
	var particles := GPUParticles3D.new()
	particles.name = "Pollen"
	particles.amount = 64
	particles.lifetime = 12.0
	particles.preprocess = 4.0
	particles.visibility_aabb = AABB(Vector3(-120, -10, -120), Vector3(240, 60, 240))
	particles.position = Vector3(0, 12, 0)

	var mat := ParticleProcessMaterial.new()
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(90, 18, 90)
	mat.direction = Vector3(0.4, 0.05, 0.2)
	mat.spread = 25.0
	mat.initial_velocity_min = 0.15
	mat.initial_velocity_max = 0.55
	mat.gravity = Vector3(0, -0.02, 0)
	mat.scale_min = 0.03
	mat.scale_max = 0.08
	mat.color = Color(0.95, 0.92, 0.75, 0.55)
	particles.process_material = mat

	var draw := SphereMesh.new()
	draw.radius = 0.5
	draw.height = 1.0
	draw.radial_segments = 4
	draw.rings = 2
	var dmat := StandardMaterial3D.new()
	dmat.albedo_color = Color(1, 0.95, 0.8, 0.45)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.emission_enabled = true
	dmat.emission = Color(0.9, 0.85, 0.6)
	dmat.emission_energy_multiplier = 0.35
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material = dmat
	particles.draw_pass_1 = draw
	add_child(particles)
