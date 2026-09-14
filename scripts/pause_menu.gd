extends CanvasLayer
## Pause overlay (Esc): resume / quit to menu.

@onready var panel: PanelContainer = %PausePanel
@onready var dim: ColorRect = %Dim
@onready var resume_btn: Button = %ResumeButton
@onready var menu_btn: Button = %QuitMenuButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	panel.visible = false
	dim.visible = false
	resume_btn.pressed.connect(_on_resume)
	menu_btn.pressed.connect(_on_quit_menu)


func _unhandled_input(event: InputEvent) -> void:
	if GameManager.has_won:
		return
	if event.is_action_pressed("pause"):
		if GameManager.is_paused:
			_on_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()


func _pause() -> void:
	panel.visible = true
	dim.visible = true
	GameManager.set_paused(true)
	resume_btn.grab_focus()


func _on_resume() -> void:
	panel.visible = false
	dim.visible = false
	GameManager.set_paused(false)


func _on_quit_menu() -> void:
	GameManager.quit_to_menu()
