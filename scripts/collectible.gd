extends Area3D
## Glowing crystal collectible. Animates and notifies GameManager on pickup.

signal collected

var _mesh: MeshInstance3D
var _light: OmniLight3D
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
	prism.size = Vector3(0.6, 1.2, 0.6)
	_mesh.mesh = prism
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.3, 0.85, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.7, 1.0)
	mat.emission_energy_multiplier = 2.5
	mat.roughness = 0.2
	mat.metallic = 0.4
	_mesh.material_override = mat
	add_child(_mesh)

	_light = OmniLight3D.new()
	_light.light_color = Color(0.4, 0.85, 1.0)
	_light.light_energy = 1.8
	_light.omni_range = 8.0
	_light.shadow_enabled = false
	add_child(_light)

	body_entered.connect(_on_body_entered)
	_base_y = position.y
	_time = randf() * TAU


func _process(delta: float) -> void:
	if _picked:
		return
	_time += delta
	_mesh.rotation.y += delta * 1.5
	_mesh.position.y = sin(_time * 2.0) * 0.25
	_light.light_energy = 1.5 + sin(_time * 3.0) * 0.4


func _on_body_entered(body: Node3D) -> void:
	if _picked:
		return
	if body.is_in_group("player") or body is CharacterBody3D:
		_picked = true
		GameManager.collect_crystal()
		collected.emit()
		_play_pickup()


func _play_pickup() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_mesh, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tween.tween_property(_light, "light_energy", 0.0, 0.3)
	tween.chain().tween_callback(queue_free)
