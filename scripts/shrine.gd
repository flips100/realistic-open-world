extends Area3D
## Lakeside checkpoint shrine — press E nearby to set respawn / restore stamina / advance quest.

signal activated

var _prompt_visible: bool = false
var _base_y: float = 0.0
var _time: float = 0.0
var _glow: OmniLight3D
var _active: bool = false
var _label: Label3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	monitorable = false
	_build_visual()
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_base_y = position.y
	set_process(true)


func _build_visual() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 3.2
	col.shape = shape
	add_child(col)

	var stone_mat := StandardMaterial3D.new()
	stone_mat.albedo_color = Color(0.52, 0.50, 0.48)
	stone_mat.roughness = 0.88
	var n := FastNoiseLite.new()
	n.frequency = 0.12
	n.seed = 91
	var ntex := NoiseTexture2D.new()
	ntex.noise = n
	ntex.width = 256
	ntex.height = 256
	ntex.seamless = true
	ntex.as_normal_map = true
	ntex.bump_strength = 8.0
	stone_mat.normal_enabled = true
	stone_mat.normal_texture = ntex
	stone_mat.uv1_triplanar = true

	var base := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.6
	cyl.bottom_radius = 1.9
	cyl.height = 0.35
	base.mesh = cyl
	base.material_override = stone_mat
	base.position.y = 0.15
	add_child(base)

	for i in range(3):
		var pillar := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 2.2 + i * 0.15, 0.35)
		pillar.mesh = box
		pillar.material_override = stone_mat
		var a := (TAU / 3.0) * float(i) - 0.4
		pillar.position = Vector3(cos(a) * 1.1, box.size.y * 0.5, sin(a) * 1.1)
		pillar.rotation.y = -a
		add_child(pillar)

	var bowl := MeshInstance3D.new()
	var bowl_mesh := CylinderMesh.new()
	bowl_mesh.top_radius = 0.55
	bowl_mesh.bottom_radius = 0.4
	bowl_mesh.height = 0.25
	bowl.mesh = bowl_mesh
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.35, 0.7, 0.85)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.3, 0.65, 0.9)
	glow_mat.emission_energy_multiplier = 1.8
	glow_mat.roughness = 0.25
	glow_mat.metallic = 0.2
	bowl.material_override = glow_mat
	bowl.position.y = 1.15
	bowl.name = "ShrineBowl"
	add_child(bowl)

	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.45, 0.8, 1.0)
	_glow.light_energy = 1.4
	_glow.omni_range = 10.0
	_glow.position.y = 1.4
	_glow.shadow_enabled = false
	add_child(_glow)

	_label = Label3D.new()
	_label.text = "Press E — Shrine"
	_label.font_size = 48
	_label.modulate = Color(0.85, 0.95, 1.0, 0.0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, 2.8, 0)
	_label.outline_modulate = Color(0, 0, 0, 0.7)
	_label.outline_size = 8
	add_child(_label)


func _process(delta: float) -> void:
	_time += delta
	_glow.light_energy = (1.8 if _active else 1.2) + sin(_time * 2.0) * 0.25
	if _prompt_visible and Input.is_action_just_pressed("interact"):
		_activate()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_prompt_visible = true
		_label.modulate.a = 1.0


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_prompt_visible = false
		_label.modulate.a = 0.0


func _activate() -> void:
	_active = true
	GameManager.activate_shrine(global_position + Vector3(0, 1.5, 2.5))
	activated.emit()
	_label.text = "Checkpoint set"
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("restore_stamina"):
		player.restore_stamina()
	var sp := AudioStreamPlayer3D.new()
	sp.stream = _make_chime()
	sp.volume_db = -6.0
	sp.max_distance = 40.0
	add_child(sp)
	sp.play()
	sp.finished.connect(sp.queue_free)
	var tw := create_tween()
	tw.tween_property(_glow, "light_energy", 3.5, 0.2)
	tw.tween_property(_glow, "light_energy", 1.8, 0.6)


func _make_chime() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.45
	var n := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 4.5)
		var s := (
			sin(TAU * 523.25 * t) * 0.35
			+ sin(TAU * 659.25 * t) * 0.25
			+ sin(TAU * 783.99 * t) * 0.15
		) * env
		s = clampf(s, -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
