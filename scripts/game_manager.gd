extends Node
## Autoload: crystals, flowers, shrine checkpoint, win state, scene transitions (v2).

signal crystals_changed(collected: int, total: int)
signal flowers_changed(collected: int, total: int)
signal stamina_changed(current: float, maximum: float)
signal quest_changed(text: String)
signal shrine_activated
signal game_won

const TOTAL_CRYSTALS := 8
const TOTAL_FLOWERS := 5
const MAIN_MENU_PATH := "res://scenes/main_menu.tscn"
const WORLD_PATH := "res://scenes/world.tscn"

var crystals_collected: int = 0
var flowers_collected: int = 0
var is_paused: bool = false
var has_won: bool = false
var shrine_visited: bool = false
var checkpoint_position: Vector3 = Vector3.ZERO
var has_checkpoint: bool = false
var quest_text: String = "Explore the valley — collect 8 crystals. Visit the lakeside shrine for guidance."


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset() -> void:
	crystals_collected = 0
	flowers_collected = 0
	has_won = false
	is_paused = false
	shrine_visited = false
	has_checkpoint = false
	checkpoint_position = Vector3.ZERO
	quest_text = "Explore the valley — collect 8 crystals. Visit the lakeside shrine for guidance."
	get_tree().paused = false
	crystals_changed.emit(0, TOTAL_CRYSTALS)
	flowers_changed.emit(0, TOTAL_FLOWERS)
	quest_changed.emit(quest_text)


func collect_crystal() -> void:
	if has_won:
		return
	crystals_collected += 1
	crystals_changed.emit(crystals_collected, TOTAL_CRYSTALS)
	_refresh_quest()
	if crystals_collected >= TOTAL_CRYSTALS:
		has_won = true
		quest_text = "All crystals recovered — the valley sings again."
		quest_changed.emit(quest_text)
		game_won.emit()


func collect_flower() -> void:
	if flowers_collected >= TOTAL_FLOWERS:
		return
	flowers_collected += 1
	flowers_changed.emit(flowers_collected, TOTAL_FLOWERS)
	_refresh_quest()


func activate_shrine(pos: Vector3) -> void:
	checkpoint_position = pos
	has_checkpoint = true
	if not shrine_visited:
		shrine_visited = true
		shrine_activated.emit()
	_refresh_quest()


func set_quest(text: String) -> void:
	quest_text = text
	quest_changed.emit(quest_text)


func _refresh_quest() -> void:
	if has_won:
		return
	var parts: PackedStringArray = []
	var rem_c := TOTAL_CRYSTALS - crystals_collected
	if rem_c > 0:
		parts.append("Find %d crystal%s" % [rem_c, "s" if rem_c != 1 else ""])
	else:
		parts.append("Crystals complete")
	if not shrine_visited:
		parts.append("Visit the lakeside shrine (E)")
	elif has_checkpoint:
		parts.append("Checkpoint set at shrine")
	var rem_f := TOTAL_FLOWERS - flowers_collected
	if rem_f > 0:
		parts.append("Optional: %d valley flower%s" % [rem_f, "s" if rem_f != 1 else ""])
	else:
		parts.append("All flowers gathered")
	quest_text = " · ".join(parts)
	quest_changed.emit(quest_text)


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
