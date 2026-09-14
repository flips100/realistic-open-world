extends CharacterBody3D
## Third-person controller: WASD, mouse look, sprint, jump, gravity.

const WALK_SPEED := 6.0
const SPRINT_SPEED := 11.0
const JUMP_VELOCITY := 8.5
const MOUSE_SENSITIVITY := 0.0025
const ACCELERATION := 12.0
const AIR_ACCELERATION := 4.0
const DECELERATION := 14.0
const CAMERA_MIN_PITCH := -1.2
const CAMERA_MAX_PITCH := 0.55
const CAMERA_DISTANCE := 5.5
const CAMERA_HEIGHT := 1.6

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var _yaw: float = 0.0
var _pitch: float = -0.25
var _camera_pivot: Node3D
var _spring_arm: SpringArm3D
var _camera: Camera3D
var _visual: Node3D
var _mesh_yaw: float = 0.0
var _can_control: bool = true


func _ready() -> void:
	_build_visuals()
	_build_camera()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	add_to_group("player")


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
	mat.albedo_color = Color(0.25, 0.45, 0.75)
	mat.roughness = 0.7
	mat.metallic = 0.15
	body.material_override = mat
	body.position.y = 0.9
	_visual.add_child(body)

	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.22
	sphere.height = 0.44
	head.mesh = sphere
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.85, 0.7, 0.55)
	head.material_override = hmat
	head.position = Vector3(0, 1.55, 0)
	_visual.add_child(head)

	# Nose marker for facing direction
	var nose := MeshInstance3D.new()
	var nose_mesh := BoxMesh.new()
	nose_mesh.size = Vector3(0.12, 0.08, 0.25)
	nose.mesh = nose_mesh
	var nmat := StandardMaterial3D.new()
	nmat.albedo_color = Color(0.2, 0.35, 0.6)
	nose.material_override = nmat
	nose.position = Vector3(0, 1.5, -0.3)
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
	_spring_arm.margin = 0.2
	_spring_arm.collision_mask = 1
	_camera_pivot.add_child(_spring_arm)

	_camera = Camera3D.new()
	_camera.fov = 70.0
	_camera.current = true
	_spring_arm.add_child(_camera)


func _unhandled_input(event: InputEvent) -> void:
	if not _can_control or GameManager.is_paused or GameManager.has_won:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_pitch -= event.relative.y * MOUSE_SENSITIVITY
		_pitch = clampf(_pitch, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
		_camera_pivot.rotation = Vector3(_pitch, _yaw, 0.0)


func _physics_process(delta: float) -> void:
	if not _can_control or GameManager.is_paused:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var cam_basis := Basis.from_euler(Vector3(0, _yaw, 0))
	var direction := (cam_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed := SPRINT_SPEED if Input.is_action_pressed("sprint") else WALK_SPEED
	var accel := ACCELERATION if is_on_floor() else AIR_ACCELERATION

	if direction.length() > 0.01:
		velocity.x = move_toward(velocity.x, direction.x * target_speed, accel * delta * target_speed)
		velocity.z = move_toward(velocity.z, direction.z * target_speed, accel * delta * target_speed)
		_mesh_yaw = atan2(-direction.x, -direction.z)
	else:
		var decel := DECELERATION if is_on_floor() else AIR_ACCELERATION * 0.5
		velocity.x = move_toward(velocity.x, 0, decel * delta * WALK_SPEED)
		velocity.z = move_toward(velocity.z, 0, decel * delta * WALK_SPEED)

	_visual.rotation.y = lerp_angle(_visual.rotation.y, _mesh_yaw, 12.0 * delta)
	move_and_slide()

	# Soft world bounds
	var limit := 220.0
	var pos := global_position
	if absf(pos.x) > limit or absf(pos.z) > limit:
		global_position.x = clampf(pos.x, -limit, limit)
		global_position.z = clampf(pos.z, -limit, limit)


func set_control_enabled(enabled: bool) -> void:
	_can_control = enabled
