extends Node
## Autoload: tracks collectibles, win state, and scene transitions.

signal crystals_changed(collected: int, total: int)
signal game_won

const TOTAL_CRYSTALS := 8
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const WORLD_PATH := "res://scenes/world.tscn"

var crystals_collected: int = 0
var is_paused: bool = false
var has_won: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset() -> void:
	crystals_collected = 0
	has_won = false
	is_paused = false
	get_tree().paused = false
	crystals_changed.emit(0, TOTAL_CRYSTALS)


func collect_crystal() -> void:
	if has_won:
		return
	crystals_collected += 1
	crystals_changed.emit(crystals_collected, TOTAL_CRYSTALS)
	if crystals_collected >= TOTAL_CRYSTALS:
		has_won = true
		game_won.emit()


func start_game() -> void:
	reset()
	get_tree().change_scene_to_file(WORLD_PATH)


func quit_to_menu() -> void:
	get_tree().paused = false
	is_paused = false
	has_won = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().change_scene_to_file(MAIN_MENU_PATH)


func set_paused(paused: bool) -> void:
	is_paused = paused
	get_tree().paused = paused
	if paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
