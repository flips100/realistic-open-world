extends Area3D
## Subtle crystal collectible with soft glow + sparkle particles (fits realistic world).

signal collected

var _mesh: MeshInstance3D
var _light: OmniLight3D
var _particles: GPUParticles3D
var _base_y: float = 0.0
var _time: float = 0.0
var _picked: bool = false


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true

	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.2
	shape.shape = sphere
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.55, 1.15, 0.55)
	_mesh.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.82, 0.95, 0.92)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(0.35, 0.75, 0.95)
	mat.emission_energy_multiplier = 1.4
	mat.roughness = 0.12
	mat.metallic = 0.55
	mat.specular = 0.7
	_mesh.material_override = mat
	add_child(_mesh)

	_light = OmniLight3D.new()
	_light.light_color = Color(0.5, 0.85, 1.0)
	_light.light_energy = 1.1
	_light.omni_range = 7.0
	_light.omni_attenuation = 1.2
	_light.shadow_enabled = false
	add_child(_light)

	_particles = GPUParticles3D.new()
	_particles.amount = 12
	_particles.lifetime = 2.5
	_particles.emitting = true
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 0.4
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 40.0
	pm.initial_velocity_min = 0.1
	pm.initial_velocity_max = 0.35
	pm.gravity = Vector3(0, 0.15, 0)
	pm.scale_min = 0.02
	pm.scale_max = 0.05
	pm.color = Color(0.7, 0.95, 1.0, 0.7)
	_particles.process_material = pm
	var dm := SphereMesh.new()
	dm.radius = 0.4
	dm.height = 0.8
	dm.radial_segments = 4
	dm.rings = 2
	var dmat := StandardMaterial3D.new()
	dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dmat.albedo_color = Color(0.8, 0.95, 1.0, 0.6)
	dmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dmat.emission_enabled = true
	dmat.emission = Color(0.5, 0.85, 1.0)
	dmat.emission_energy_multiplier = 0.8
	dm.material = dmat
	_particles.draw_pass_1 = dm
	add_child(_particles)

	body_entered.connect(_on_body_entered)
	_base_y = position.y
	_time = randf() * TAU


func _process(delta: float) -> void:
	if _picked:
		return
	_time += delta
	_mesh.rotation.y += delta * 0.9
	_mesh.position.y = sin(_time * 1.6) * 0.18
	_light.light_energy = 0.95 + sin(_time * 2.2) * 0.25


func _on_body_entered(body: Node3D) -> void:
	if _picked:
		return
	if body.is_in_group("player") or body is CharacterBody3D:
		_picked = true
		GameManager.collect_crystal()
		collected.emit()
		_play_pickup()


func _play_pickup() -> void:
	_particles.emitting = false
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mesh, "scale", Vector3.ZERO, 0.35).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", 0.0, 0.35)
	tween.chain().tween_callback(queue_free)
