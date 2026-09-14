extends CanvasLayer
## Polished HUD: crystal badge, readable objective, win banner.

@onready var crystal_label: Label = %CrystalLabel
@onready var objective_label: Label = %ObjectiveLabel
@onready var win_panel: PanelContainer = %WinPanel
@onready var win_label: Label = %WinLabel
@onready var menu_btn: Button = %MenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	win_panel.visible = false
	GameManager.crystals_changed.connect(_on_crystals_changed)
	GameManager.game_won.connect(_on_game_won)
	menu_btn.pressed.connect(_on_menu)
	_on_crystals_changed(GameManager.crystals_collected, GameManager.TOTAL_CRYSTALS)
	var tw := create_tween()
	tw.tween_interval(10.0)
	tw.tween_property(objective_label, "modulate:a", 0.4, 1.5)


func _on_crystals_changed(collected: int, total: int) -> void:
	crystal_label.text = "%d / %d  crystals" % [collected, total]
	var remaining := total - collected
	objective_label.modulate.a = 1.0
	if remaining > 0:
		objective_label.text = "Find %d more crystal%s hidden across the valley" % [
			remaining, "s" if remaining != 1 else ""
		]
	else:
		objective_label.text = "All crystals recovered — the valley is restored"
	var tw := create_tween()
	tw.tween_interval(6.0)
	tw.tween_property(objective_label, "modulate:a", 0.35, 1.2)


func _on_game_won() -> void:
	win_panel.visible = true
	win_label.text = "Valley Restored\nEvery crystal found."
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_control_enabled"):
		player.set_control_enabled(false)


func _on_menu() -> void:
	GameManager.quit_to_menu()
