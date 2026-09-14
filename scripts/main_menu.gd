extends Control
## Main menu: title, start, quit.

@onready var _start_btn: Button = %StartButton
@onready var _quit_btn: Button = %QuitButton


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_start_btn.pressed.connect(_on_start)
	_quit_btn.pressed.connect(_on_quit)
	_start_btn.grab_focus()


func _on_start() -> void:
	GameManager.start_game()


func _on_quit() -> void:
	get_tree().quit()
