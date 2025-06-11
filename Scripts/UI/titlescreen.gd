extends Control

@export var bgm: AudioStream

@onready var new_game: Button = $manu/newGame
@onready var manu: VBoxContainer = $manu
@onready var load_game: Button = $manu/loadGame
@onready var tutorial: Button = $manu/Tutorial

func _ready() -> void:
	new_game.disabled = not Game.tutorial_completed
	load_game.disabled = not Game.has_save() or not Game.tutorial_completed
	
	tutorial.grab_focus()

	SoundManager.setup_ui_sounds(self)
		
	if bgm:
		SoundManager.play_bgm(bgm)

func _on_new_game_pressed() -> void:
	Game.new_game()

func _on_load_game_pressed() -> void:
	Game.load_game()

func _on_exit_game_pressed() -> void:
	get_tree().quit()

func _on_tutorial_pressed() -> void:
	Game.change_scene("res://Scenes/level/level1.tscn")
