extends CharacterBody3D
## Prefect-blazer humanoid from assets/player/reference_person.jpg (likeness: user's responsibility).

const PlayerAppearance := preload("res://scripts/player_appearance.gd")

const WALK_SPEED := 6.0
const SPRINT_SPEED := 11.0
const JUMP_VELOCITY := 8.4
const MOUSE_SENSITIVITY := 0.0025
const ACCELERATION := 14.0
const AIR_ACCELERATION := 3.8
const DECELERATION := 16.0
const CAMERA_MIN_PITCH := -1.2
const CAMERA_MAX_PITCH := 0.55
const CAMERA_DISTANCE := 4.4
const CAMERA_HEIGHT := 1.58
const CAMERA_SHOULDER := 0.55
const BASE_FOV := 58.0
const SPRINT_FOV := 66.0
const FOV_LERP := 5.5
const CAMERA_SMOOTH := 14.0
const LANDING_THRESHOLD := -4.0
const REF_FACE_PATH := "res://assets/player/reference_person.jpg"

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw: float = 0.0
var _pitch: float = -0.16
var _target_yaw: float = 0.0
var _target_pitch: float = -0.16
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
var _strafe_roll: float = 0.0
var _left_arm: Node3D
var _right_arm: Node3D
var _left_leg: Node3D
var _right_leg: Node3D
var _anim_phase: float = 0.0


func _ready() -> void:
	var face := _load_face_texture()
	var parts: Dictionary = PlayerAppearance.build_body(self, face)
	_visual = parts["visual"]
	_left_arm = parts["left_arm"]
	_right_arm = parts["right_arm"]
	_left_leg = parts["left_leg"]
	_right_leg = parts["right_leg"]
	_build_camera()
	_build_audio()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")
	await get_tree().process_frame
	_terrain = get_tree().get_first_node_in_group("terrain")
	if _terrain == null:
		_terrain = get_parent().get_node_or_null("Terrain")


func _load_face_texture() -> Texture2D:
	if ResourceLoader.exists(REF_FACE_PATH):
		var res := load(REF_FACE_PATH)
		if res is Texture2D:
			return res as Texture2D
		if res is Image:
			return ImageTexture.create_from_image(res as Image)
	if FileAccess.file_exists(REF_FACE_PATH):
		var img := Image.new()
		if img.load(REF_FACE_PATH) == OK:
			return ImageTexture.create_from_image(img)
	var b64 := ""
	var b64_path := "res://assets/player/reference_person.jpg.b64"
	if FileAccess.file_exists(b64_path):
		var f := FileAccess.open(b64_path, FileAccess.READ)
		if f:
			b64 = f.get_as_text().strip_edges()
			f.close()
	elif FileAccess.file_exists("res://assets/player/reference_person.jpg.b64.part1"):
		var f1 := FileAccess.open("res://assets/player/reference_person.jpg.b64.part1", FileAccess.READ)
		var f2 := FileAccess.open("res://assets/player/reference_person.jpg.b64.part2", FileAccess.READ)
		if f1 and f2:
			b64 = f1.get_as_text().strip_edges() + f2.get_as_text().strip_edges()
			f1.close()
			f2.close()
	if b64 != "":
		var raw := Marshalls.base64_to_raw(b64)
		var img2 := Image.new()
		if img2.load_jpg_from_buffer(raw) == OK:
			return ImageTexture.create_from_image(img2)
	push_warning("Player: reference face texture missing at %s" % REF_FACE_PATH)
	return null


func _build_camera() -> void:
	_camera_pivot = Node3D.new()
	_camera_pivot.name = "CameraPivot"
	_camera_pivot.position = Vector3(0, CAMERA_HEIGHT, 0)
	add_child(_camera_pivot)
	_spring_arm = SpringArm3D.new()
	_spring_arm.spring_length = CAMERA_DISTANCE
	_spring_arm.margin = 0.2
	_spring_arm.collision_mask = 1
	_spring_arm.position = Vector3(CAMERA_SHOULDER, 0.2, 0)
	_camera_pivot.add_child(_spring_arm)
	_camera = Camera3D.new()
	_camera.fov = BASE_FOV
	_camera.current = true
	_camera.near = 0.08
	_camera.far = 520.0
	_camera.keep_aspect = Camera3D.KEEP_HEIGHT
	_spring_arm.add_child(_camera)


func _build_audio() -> void:
	_footstep_player = AudioStreamPlayer3D.new()
	_footstep_player.name = "Footsteps"
	_footstep_player.max_distance = 28.0
	_footstep_player.bus = &"Master"
	_footstep_player.volume_db = -8.0
	add_child(_footstep_player)


func _make_footstep_stream(surface: String) -> AudioStreamWAV:
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
	_yaw = lerp_angle(_yaw, _target_yaw, 1.0 - exp(-CAMERA_SMOOTH * delta))
	_pitch = lerpf(_pitch, _target_pitch, 1.0 - exp(-CAMERA_SMOOTH * delta))
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	_strafe_roll = lerpf(_strafe_roll, -input_dir.x * 0.03, 1.0 - exp(-7.0 * delta))
	_camera_pivot.rotation = Vector3(_pitch + _landing_punch, _yaw, _strafe_roll)
	_landing_punch = lerpf(_landing_punch, 0.0, 1.0 - exp(-9.0 * delta))
	var on_floor_now := is_on_floor()
	if not on_floor_now:
		velocity.y -= gravity * delta
	if on_floor_now and not _was_on_floor and velocity.y < LANDING_THRESHOLD:
		_landing_punch = clampf(velocity.y * 0.018, -0.1, 0.0)
	_was_on_floor = on_floor_now
	if Input.is_action_just_pressed("jump") and on_floor_now:
		velocity.y = JUMP_VELOCITY
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
	var horiz_speed := Vector2(velocity.x, velocity.z).length()
	_update_locomotion_anim(delta, horiz_speed, on_floor_now, sprinting)
	if on_floor_now and horiz_speed > 0.5:
		_bob_time += delta * (horiz_speed * 0.34)
		_spring_arm.position.y = 0.2 + sin(_bob_time) * 0.04
		_spring_arm.position.x = CAMERA_SHOULDER + cos(_bob_time * 0.5) * 0.015
	else:
		_spring_arm.position.y = lerpf(_spring_arm.position.y, 0.2, 8.0 * delta)
		_spring_arm.position.x = lerpf(_spring_arm.position.x, CAMERA_SHOULDER, 8.0 * delta)
	_camera.fov = lerpf(_camera.fov, SPRINT_FOV if sprinting else BASE_FOV, 1.0 - exp(-FOV_LERP * delta))
	move_and_slide()
	if on_floor_now and horiz_speed > 1.2:
		_footstep_timer -= delta
		var interval := 0.38 if sprinting else 0.52
		if _footstep_timer <= 0.0:
			_footstep_timer = interval
			_play_footstep()
	else:
		_footstep_timer = 0.1
	var limit := 220.0
	var pos := global_position
	if absf(pos.x) > limit or absf(pos.z) > limit:
		global_position.x = clampf(pos.x, -limit, limit)
		global_position.z = clampf(pos.z, -limit, limit)


func _update_locomotion_anim(delta: float, speed: float, on_floor: bool, sprinting: bool) -> void:
	if not on_floor or speed < 0.4:
		_anim_phase = lerpf(_anim_phase, 0.0, 8.0 * delta)
		if _left_arm:
			_left_arm.rotation.x = lerpf(_left_arm.rotation.x, 0.05, 10.0 * delta)
			_right_arm.rotation.x = lerpf(_right_arm.rotation.x, -0.05, 10.0 * delta)
			_left_leg.rotation.x = lerpf(_left_leg.rotation.x, 0.0, 10.0 * delta)
			_right_leg.rotation.x = lerpf(_right_leg.rotation.x, 0.0, 10.0 * delta)
		return
	var rate := 7.5 if sprinting else 5.5
	_anim_phase += delta * rate * clampf(speed / WALK_SPEED, 0.5, 1.6)
	var swing := sin(_anim_phase) * (0.55 if sprinting else 0.4)
	_left_arm.rotation.x = swing
	_right_arm.rotation.x = -swing
	_left_leg.rotation.x = -swing * 0.9
	_right_leg.rotation.x = swing * 0.9


func _play_footstep() -> void:
	var surface := "grass"
	if _terrain and _terrain.has_method("get_surface_type"):
		surface = _terrain.get_surface_type(global_position.x, global_position.z)
	_footstep_player.stream = _make_footstep_stream(surface)
	_footstep_player.pitch_scale = randf_range(0.92, 1.08)
	_footstep_player.play()


func set_control_enabled(enabled: bool) -> void:
	_can_control = enabled
