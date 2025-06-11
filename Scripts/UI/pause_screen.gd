extends Control

@onready var h_box_container: HBoxContainer = $VBoxContainer/Actions/HBoxContainer
@onready var Continue: Button = $VBoxContainer/Actions/HBoxContainer/Continue

func _ready() -> void:
	hide()
	SoundManager.setup_ui_sounds(self)
	visibility_changed.connect(func ():
		get_tree().paused = visible
	)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		hide()
		get_window().set_input_as_handled()

func show_pause() -> void:
	show()
	Continue.grab_focus()

func _on_continue_pressed() -> void:
	hide()

func _on_quit_pressed() -> void:
	Game.back_to_title()

func _on_save_pressed() -> void:
	Game.save_game()
