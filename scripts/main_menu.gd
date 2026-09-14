extends Control
## Main menu with stylized 3D valley preview backdrop (SubViewport).

@onready var _start_btn: Button = %StartButton
@onready var _quit_btn: Button = %QuitButton

var _preview_root: Node3D
var _cam_pivot: Node3D
var _time: float = 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_btn.pressed.connect(_on_start)
	_quit_btn.pressed.connect(_on_quit)
	_start_btn.grab_focus()
	_build_preview_backdrop()


func _process(delta: float) -> void:
	_time += delta
	if _cam_pivot:
		_cam_pivot.rotation.y = _time * 0.08
		_cam_pivot.rotation.x = -0.22 + sin(_time * 0.25) * 0.03


func _build_preview_backdrop() -> void:
	var old_bg := get_node_or_null("Background")
	if old_bg:
		old_bg.visible = false

	var host := SubViewportContainer.new()
	host.name = "PreviewHost"
	host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	host.stretch = true
	host.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(host)
	move_child(host, 0)

	var vp := SubViewport.new()
	vp.name = "PreviewViewport"
	vp.transparent_bg = false
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	vp.size = Vector2i(1280, 720)
	host.add_child(vp)

	_preview_root = Node3D.new()
	_preview_root.name = "PreviewWorld"
	vp.add_child(_preview_root)

	var env_node := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	var sky := Sky.new()
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.35, 0.55, 0.9)
	sky_mat.sky_horizon_color = Color(0.95, 0.72, 0.5)
	sky_mat.ground_bottom_color = Color(0.25, 0.3, 0.2)
	sky_mat.ground_horizon_color = Color(0.7, 0.6, 0.45)
	sky_mat.sky_energy_multiplier = 1.3
	sky.sky_material = sky_mat
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.85
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env_node.environment = env
	_preview_root.add_child(env_node)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color(1.0, 0.9, 0.7)
	sun.light_energy = 1.8
	sun.rotation_degrees = Vector3(-40, -50, 0)
	_preview_root.add_child(sun)

	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(80, 80)
	ground.mesh = plane
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.32, 0.5, 0.26)
	gmat.roughness = 0.9
	ground.material_override = gmat
	_preview_root.add_child(ground)

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.26, 0.14)
	var leaf_mat := StandardMaterial3D.new()
	leaf_mat.albedo_color = Color(0.28, 0.52, 0.24)
	var rng := RandomNumberGenerator.new()
	rng.seed = 13
	for i in range(18):
		var tree := Node3D.new()
		var ang := rng.randf() * TAU
		var rad := rng.randf_range(8.0, 28.0)
		tree.position = Vector3(cos(ang) * rad, 0, sin(ang) * rad)
		var scale := rng.randf_range(0.8, 1.6)
		tree.scale = Vector3.ONE * scale
		var trunk := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.12
		cyl.bottom_radius = 0.28
		cyl.height = 2.4
		trunk.mesh = cyl
		trunk.material_override = trunk_mat
		trunk.position.y = 1.2
		tree.add_child(trunk)
		for b in range(3):
			var crown := MeshInstance3D.new()
			var sph := SphereMesh.new()
			sph.radius = 0.9 - b * 0.15
			sph.height = 1.3 - b * 0.15
			crown.mesh = sph
			crown.material_override = leaf_mat
			crown.position = Vector3(rng.randf_range(-0.3, 0.3), 2.6 + b * 0.55, rng.randf_range(-0.3, 0.3))
			tree.add_child(crown)
		_preview_root.add_child(tree)

	var lake := MeshInstance3D.new()
	var lake_mesh := PlaneMesh.new()
	lake_mesh.size = Vector2(18, 14)
	lake.mesh = lake_mesh
	var lmat := StandardMaterial3D.new()
	lmat.albedo_color = Color(0.2, 0.45, 0.5, 0.85)
	lmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	lmat.metallic = 0.4
	lmat.roughness = 0.15
	lmat.emission_enabled = true
	lmat.emission = Color(0.15, 0.35, 0.4)
	lmat.emission_energy_multiplier = 0.25
	lake.material_override = lmat
	lake.position = Vector3(6, 0.05, 8)
	_preview_root.add_child(lake)

	_cam_pivot = Node3D.new()
	_cam_pivot.name = "CamPivot"
	_cam_pivot.position = Vector3(0, 3.5, 0)
	_preview_root.add_child(_cam_pivot)
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 48.0
	cam.position = Vector3(0, 2.5, 14)
	cam.look_at(Vector3(0, 1.5, 0))
	_cam_pivot.add_child(cam)

	var warm := get_node_or_null("WarmOverlay")
	if warm:
		warm.color = Color(0.55, 0.32, 0.12, 0.18)
	var grad := get_node_or_null("GradientOverlay")
	if grad:
		grad.color = Color(0.02, 0.05, 0.08, 0.35)


func _on_start() -> void:
	GameManager.start_game()


func _on_quit() -> void:
	get_tree().quit()
