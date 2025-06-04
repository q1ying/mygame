extends Node

const SAVE_PATH := "user://data.sav"

var passed_levels := []
var current_world_states := {}

@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var color_rect: ColorRect = $ColorRect

func _ready() -> void:
	color_rect.color.a = 0

func change_scene(path: String, params := {}) -> void:
	var tree := get_tree()
	tree.paused = true
	
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1, 1)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	await tween.finished
	
	var passed_level := tree.current_scene.scene_file_path.get_file().get_basename()
	passed_levels.append(passed_level)
	
	tree.change_scene_to_file(path)
	await tree.tree_changed
	
	if "entry_point" in params:
		for node in tree.get_nodes_in_group("entry_points"):
			if node.name == params.entry_point:
				tree.current_scene.update_player(node.global_position)
				break
				
	if "position" in params and "direction" in params:
		tree.current_scene.update_player(params.position, params.direction)
			
	tree.paused = false
	tween = create_tween()
	tween.tween_property(color_rect, "color:a", 0, 1)

func save_game() -> void:
	var scene := get_tree().current_scene
	var scene_name := scene.scene_file_path.get_file().get_basename()
	current_world_states[scene_name] = scene.to_dict()
	
	var data := {
		passed_levels = passed_levels,
		current_world_states = current_world_states,
		health_component = health_component.to_dict(),
		mana_component = mana_component.to_dict(),
		scene = scene.scene_file_path,
		player = {
			direction = scene.player.direction,
			position = {
				x = scene.player.global_position.x,
				y = scene.player.global_position.y,
			},
		},
	}
	var json := JSON.stringify(data)
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if not file:
		return
	file.store_string(json)

func load_game() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
		
	var json := file.get_as_text()
	var data := JSON.parse_string(json) as Dictionary
	
	passed_levels = data.passed_levels
	current_world_states = data.current_world_states
	health_component.from_dict(data.health_component)
	mana_component.from_dict(data.mana_component)
	change_scene(data.scene, {
		direction = data.player.position.x,
		position = Vector2(
			data.player.position.x,
			data.player.position.y
		)
	})

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		save_game()
