extends Area3D
## Optional valley flower pickup (side collectible).

var _picked: bool = false
var _mesh: MeshInstance3D
var _time: float = 0.0
var _base_y: float = 0.0


func _ready() -> void:
	collision_layer = 4
	collision_mask = 2
	monitoring = true
	monitorable = true
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 1.0
	shape.shape = sphere
	add_child(shape)

	_mesh = MeshInstance3D.new()
	var stem := CylinderMesh.new()
	stem.top_radius = 0.02
	stem.bottom_radius = 0.03
	stem.height = 0.35
	var stem_mi := MeshInstance3D.new()
	stem_mi.mesh = stem
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.25, 0.45, 0.18)
	stem_mi.material_override = stem_mat
	stem_mi.position.y = 0.15
	add_child(stem_mi)

	var bloom := SphereMesh.new()
	bloom.radius = 0.12
	bloom.height = 0.18
	_mesh.mesh = bloom
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.92, 0.55, 0.75)
	mat.emission_enabled = true
	mat.emission = Color(0.85, 0.4, 0.6)
	mat.emission_energy_multiplier = 0.55
	mat.roughness = 0.55
	_mesh.material_override = mat
	_mesh.position.y = 0.38
	add_child(_mesh)

	var petal_mat := StandardMaterial3D.new()
	petal_mat.albedo_color = Color(0.95, 0.7, 0.85)
	petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in range(5):
		var petal := MeshInstance3D.new()
		var pm := PlaneMesh.new()
		pm.size = Vector2(0.14, 0.1)
		petal.mesh = pm
		petal.material_override = petal_mat
		var a := (TAU / 5.0) * float(i)
		petal.position = Vector3(cos(a) * 0.1, 0.38, sin(a) * 0.1)
		petal.rotation_degrees = Vector3(70, rad_to_deg(a), 0)
		add_child(petal)

	body_entered.connect(_on_body_entered)
	_base_y = position.y
	_time = randf() * TAU
	add_to_group("flower")


func _process(delta: float) -> void:
	if _picked:
		return
	_time += delta
	_mesh.position.y = 0.38 + sin(_time * 2.0) * 0.04
	_mesh.rotation.y += delta * 0.8


func _on_body_entered(body: Node3D) -> void:
	if _picked:
		return
	if body.is_in_group("player") or body is CharacterBody3D:
		_picked = true
		GameManager.collect_flower()
		_play_pickup()


func _play_pickup() -> void:
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _make_sfx()
	sp.volume_db = -10.0
	sp.max_distance = 24.0
	add_child(sp)
	sp.play()
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ZERO, 0.3).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func _make_sfx() -> AudioStreamWAV:
	var sample_rate := 22050
	var n := int(sample_rate * 0.12)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(n):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 28.0)
		var s := sin(TAU * 880.0 * t) * 0.3 * env + rng.randf_range(-0.05, 0.05) * env
		var v := int(clampf(s, -1.0, 1.0) * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
