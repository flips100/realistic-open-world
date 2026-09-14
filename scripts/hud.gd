extends CanvasLayer
## v2 HUD: crystals, flowers, stamina, compass to nearest crystal, quest, win banner.

@onready var crystal_label: Label = %CrystalLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var win_panel: PanelContainer = %WinPanel
@onready var win_label: Label = %WinLabel
@onready var menu_btn: Button = %MenuButton
@onready var stamina_bar: ProgressBar = %StaminaBar
@onready var flower_label: Label = %FlowerLabel
@onready var compass_label: Label = %CompassLabel
@onready var version_label: Label = %VersionLabel


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	win_panel.visible = false
	GameManager.crystals_changed.connect(_on_crystals_changed)
	GameManager.flowers_changed.connect(_on_flowers_changed)
	GameManager.stamina_changed.connect(_on_stamina_changed)
	GameManager.quest_changed.connect(_on_quest_changed)
	GameManager.game_won.connect(_on_game_won)
	menu_btn.pressed.connect(_on_menu)
	_on_crystals_changed(GameManager.crystals_collected, GameManager.TOTAL_CRYSTALS)
	_on_flowers_changed(GameManager.flowers_collected, GameManager.TOTAL_FLOWERS)
	_on_quest_changed(GameManager.quest_text)
	_on_stamina_changed(100.0, 100.0)
	if version_label:
		version_label.text = "v2.0"
	var tw := create_tween()
	tw.tween_interval(12.0)
	tw.tween_property(objective_label, "modulate:a", 0.45, 1.5)


func _process(_delta: float) -> void:
	_update_compass()


func _update_compass() -> void:
	if compass_label == null or GameManager.has_won:
		return
	var player := get_tree().get_first_node_in_group("player")
	if player == null:
		compass_label.text = "◆  —"
		return
	var nearest: Node3D = null
	var best := 1e12
	for c in get_tree().get_nodes_in_group("crystal"):
		if c is Node3D:
			var d: float = player.global_position.distance_to((c as Node3D).global_position)
			if d < best:
				best = d
				nearest = c as Node3D
	if nearest == null:
		compass_label.text = "◆  all found"
		return
	var to: Vector3 = nearest.global_position - player.global_position
	to.y = 0.0
	var bearing := atan2(-to.x, -to.z)
	var cam_yaw := 0.0
	if player.has_method("get_camera_yaw"):
		cam_yaw = float(player.get_camera_yaw())
	var rel := wrapf(bearing - cam_yaw, -PI, PI)
	var arrow := "↑"
	if rel > PI * 0.75 or rel < -PI * 0.75:
		arrow = "↓"
	elif rel > PI * 0.25:
		arrow = "←"
	elif rel < -PI * 0.25:
		arrow = "→"
	elif rel > PI * 0.08:
		arrow = "↖"
	elif rel < -PI * 0.08:
		arrow = "↗"
	compass_label.text = "◆  %s  %.0fm" % [arrow, best]


func _on_crystals_changed(collected: int, total: int) -> void:
	crystal_label.text = "%d / %d  crystals" % [collected, total]
	objective_label.modulate.a = 1.0
	var tw := create_tween()
	tw.tween_interval(7.0)
	tw.tween_property(objective_label, "modulate:a", 0.4, 1.2)


func _on_flowers_changed(collected: int, total: int) -> void:
	if flower_label:
		flower_label.text = "%d / %d  flowers" % [collected, total]


func _on_stamina_changed(current: float, maximum: float) -> void:
	if stamina_bar:
		stamina_bar.max_value = maximum
		stamina_bar.value = current
		var ratio := current / maxf(maximum, 1.0)
		if ratio < 0.25:
			stamina_bar.modulate = Color(1.0, 0.55, 0.4)
		elif ratio < 0.5:
			stamina_bar.modulate = Color(1.0, 0.85, 0.5)
		else:
			stamina_bar.modulate = Color(0.55, 0.9, 0.75)


func _on_quest_changed(text: String) -> void:
	objective_label.text = text
	objective_label.modulate.a = 1.0


func _on_game_won() -> void:
	win_panel.visible = true
	var flower_note := ""
	if GameManager.flowers_collected >= GameManager.TOTAL_FLOWERS:
		flower_note = "\nEvery valley flower gathered."
	elif GameManager.flowers_collected > 0:
		flower_note = "\n%d / %d flowers found." % [GameManager.flowers_collected, GameManager.TOTAL_FLOWERS]
	win_label.text = "Valley Restored\nEvery crystal found.%s\n\nThanks for exploring." % flower_note
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_control_enabled"):
		player.set_control_enabled(false)


func _on_menu() -> void:
	GameManager.quit_to_menu()
