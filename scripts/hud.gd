extends CanvasLayer
## In-game HUD: crystal count, objective, win banner.

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


func _on_crystals_changed(collected: int, total: int) -> void:
	crystal_label.text = "Crystals: %d / %d" % [collected, total]
	var remaining := total - collected
	if remaining > 0:
		objective_label.text = "Explore the valley and collect %d more glowing crystal%s." % [
			remaining, "s" if remaining != 1 else ""
		]
	else:
		objective_label.text = "All crystals found!"


func _on_game_won() -> void:
	win_panel.visible = true
	win_label.text = "Valley Restored!\nYou found every crystal."
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var player := get_tree().get_first_node_in_group("player")
	if player and player.has_method("set_control_enabled"):
		player.set_control_enabled(false)


func _on_menu() -> void:
	GameManager.quit_to_menu()
