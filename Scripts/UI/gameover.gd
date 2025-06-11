extends Control

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	hide()
	set_process_input(false)

func _input(event: InputEvent) -> void:
	get_window().set_input_as_handled()
	
	if animation_player.is_playing():
		return
	
	if event is InputEventKey or event is InputEventMouseButton:
		if event.is_pressed() and not event.is_echo():
			if Game.has_save():
				get_tree().paused = false
				Game.load_game()
			else:
				Game.back_to_title()
				
func show_game_over() -> void:
	get_tree().paused = true
	show()
	set_process_input(true)
	animation_player.play("enter")
