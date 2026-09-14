extends CharacterBody3D
## Third-person controller with camera smoothing, sprint FOV kick, landing feel, footsteps.

const WALK_SPEED := 6.0
const SPRINT_SPEED := 11.0
const JUMP_VELOCITY := 8.5
const MOUSE_SENSITIVITY := 0.0025
const ACCELERATION := 14.0
const AIR_ACCELERATION := 4.0
const DECELERATION := 16.0
const CAMERA_MIN_PITCH := -1.2
const CAMERA_MAX_PITCH := 0.55
const CAMERA_DISTANCE := 5.2
const CAMERA_HEIGHT := 1.65
const BASE_FOV := 68.0
const SPRINT_FOV := 76.0
const FOV_LERP := 6.0
const CAMERA_SMOOTH := 14.0
const LANDING_THRESHOLD := -4.5

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw: float = 0.0
var _pitch: float = -0.22
var _target_yaw: float = 0.0
var _target_pitch: float = -0.22
var _camera_pivot: Node3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _visual: Node3D
var _mesh_yaw: float = 0.0
var _can_control: bool = true
var _was_on_floor: bool = true
var _landing_punch: float = 0.0
var _footstep_timer: float = 0.0
var _footstep_player: AudioStreamPlayer3D
var _terrain: Node = null
var _bob_time: float = 0.0


func _ready() -> void:
	_build_visuals()
	_build_camera()
	_build_audio()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	await get_tree().process_frame
	_terrain = get_tree().get_first_node_in_group("terrain")
	if _terrain == null:
		_terrain = get_parent().get_node_or_null("Terrain")


func _build_visuals() -> void:
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)

	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.35
	capsule.height = 1.6
	body.mesh = capsule
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.28, 0.38, 0.48)
	mat.roughness = 0.78
	mat.metallic = 0.08
	body.material_override = mat
	body.position.y = 0.9
	_visual.add_child(body)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.82, 0.68, 0.55)
	hmat.roughness = 0.7
	head.material_override = hmat
	head.position = Vector3(0, 1.55, 0)
	_visual.add_child(head)

	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.1, 0.07, 0.22)
	nose.mesh = nose_mesh
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.22, 0.32, 0.42)
	nose.material_override = nmat
	nose.position = Vector3(0, 1.5, -0.28)
	_visual.add_child(nose)

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.6
	collision.shape = shape
	collision.position.y = 0.9
	add_child(collision)


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0, CAMERA_HEIGHT, 0)
	add_child(_camera_pivot)

	_spring_arm = SpringArm3D.new()
	_spring_arm.spring_length = CAMERA_DISTANCE
	_spring_arm.margin = 0.25
	_spring_arm.collision_mask = 1
	_camera_pivot.add_child(_spring_arm)

	_camera = Camera3D.new()
	_camera.fov = BASE_FOV
	_camera.current = true
	_camera.near = 0.08
	_camera.far = 500.0
	_spring_arm.add_child(_camera)


func _build_audio() -> void:
	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.name = "Footsteps"
	_footstep_player.max_distance = 28.0
	_footstep_player.bus = &"Master"
	_footstep_player.volume_db = -8.0
	add_child(_footstep_player)


func _make_footstep_stream(surface: String) -> AudioStreamWAV:
	## Tiny procedural one-shot (commercial-safe).
	var sample_rate := 22050
	var duration := 0.07
	var n := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(surface) + int(Time.get_ticks_msec()) % 1000
	var base_freq := 90.0
	var amp := 0.22
	match surface:
		"rock":
			base_freq = 140.0
			amp = 0.18
		"dirt":
			base_freq = 70.0
			amp = 0.2
		_:
			base_freq = 95.0
			amp = 0.16
	for i in range(n):
		var t := float(i) / float(sample_rate)
		var env := exp(-t * 38.0)
		var noise := rng.randf_range(-1.0, 1.0)
		var tone := sin(TAU * base_freq * t) * 0.35
		var s := clampf((noise * 0.65 + tone) * amp * env, -1.0, 1.0)
		var v := int(s * 32767.0)
		data[i * 2] = v & 0xFF
		data[i * 2 + 1] = (v >> 8) & 0xFF
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _unhandled_input(event: InputEvent) -> void:
	if not _can_control or GameManager.is_paused or GameManager.has_won:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_target_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_target_pitch -= event.relative.y * MOUSE_SENSITIVITY
		_target_pitch = clampf(_target_pitch, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)


func _physics_process(delta: float) -> void:
	if not _can_control or GameManager.is_paused:
		return

	# Smooth camera follow (yaw/pitch lerp)
	_yaw = lerp_angle(_yaw, _target_yaw, 1.0 - exp(-CAMERA_SMOOTH * delta))
	_pitch = lerpf(_pitch, _target_pitch, 1.0 - exp(-CAMERA_SMOOTH * delta))
	var cam_rot := Vector3(_pitch + _landing_punch, _yaw, 0.0)
	_camera_pivot.rotation = cam_rot
	_landing_punch = lerpf(_landing_punch, 0.0, 1.0 - exp(-10.0 * delta))

	var on_floor_now := is_on_floor()
	if not on_floor_now:
		velocity.y -= gravity * delta

	# Landing feel
	if on_floor_now and not _was_on_floor and velocity.y < LANDING_THRESHOLD:
		_landing_punch = clampf(velocity.y * 0.02, -0.12, 0.0)
	_was_on_floor = on_floor_now

	if Input.is_action_just_pressed("jump") and on_floor_now:
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := Basis.from_euler(Vector3(0, _yaw, 0))
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var sprinting := Input.is_action_pressed("sprint") and direction.length() > 0.1
	var target_speed := SPRINT_SPEED if sprinting else WALK_SPEED
	var accel := ACCELERATION if on_floor_now else AIR_ACCELERATION

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta * target_speed)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta * target_speed)
		_mesh_yaw = atan2(-direction.x, -direction.z)
	else:
		var decel := DECELERATION if on_floor_now else AIR_ACCELERATION * 0.5
		velocity.x = move_toward(velocity.x, 0, decel * delta * WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, decel * delta * WALK_SPEED)

	_visual.rotation.y = lerp_angle(_visual.rotation.y, _mesh_yaw, 12.0 * delta)

	# Subtle head bob via spring arm
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	if on_floor_now and horiz_speed > 0.5:
		_bob_time += delta * (horiz_speed * 0.35)
		_spring_arm.position.y = sin(_bob_time) * 0.04
	else:
		_spring_arm.position.y = lerpf(_spring_arm.position.y, 0.0, 8.0 * delta)

	# Sprint FOV kick
	var want_fov := SPRINT_FOV if sprinting else BASE_FOV
	_camera.fov = lerpf(_camera.fov, want_fov, 1.0 - exp(-FOV_LERP * delta))

	move_and_slide()

	# Footsteps by surface
	if on_floor_now and horiz_speed > 1.2:
		_footstep_timer -= delta
		var interval := 0.38 if sprinting else 0.52
		if _footstep_timer <= 0.0:
			_footstep_timer = interval
			_play_footstep()
	else:
		_footstep_timer = 0.1

	# Soft world bounds
	var limit := 220.0
	var pos := global_position
	if absf(pos.x) > limit or absf(pos.z) > limit:
		global_position.x = clampf(pos.x, -limit, limit)
		global_position.z = clampf(pos.z, -limit, limit)


func _play_footstep() -> void:
	var surface := "grass"
	if _terrain and _terrain.has_method("get_surface_type"):
		surface = _terrain.get_surface_type(global_position.x, global_position.z)
	_footstep_player.stream = _make_footstep_stream(surface)
	_footstep_player.pitch_scale = randf_range(0.92, 1.08)
	_footstep_player.play()


func set_control_enabled(enabled: bool) -> void:
	_can_control = enabled
