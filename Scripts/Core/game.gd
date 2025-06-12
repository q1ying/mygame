extends Node

const SAVE_PATH := "user://data.sav"
var AES_KEY := PackedByteArray([
	0x5A, 0xC3, 0x9F, 0x47,
	0x1E, 0xD8, 0x6B, 0xA4,
	0x0D, 0x73, 0xE1, 0x9B,
	0x2F, 0x5D, 0x80, 0xC6,
	0x37, 0x4A, 0x91, 0xBE,
	0xA2, 0x54, 0x6F, 0xD1,
	0x28, 0x3C, 0x8E, 0xF5,
	0xB7, 0x02, 0x49, 0x6D
])
const MUSIC_CONFIG_PATH := "user://music_config.ini"
const BASE_CONFIG_PATH := "user://base_config.ini"

#var passed_levels := []
#var current_world_states := {}
var tutorial_completed := false 

@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent
@onready var color_rect: ColorRect = $ColorRect
@onready var default_health_component := health_component.to_dict()
@onready var default_mana_component := mana_component.to_dict()

func _ready() -> void:
	color_rect.color.a = 0
	load_music_config()
	load_base_config()

func change_scene(path: String, params := {}) -> void:
	var tree := get_tree()
	tree.paused = true
	
	var tween := create_tween()
	tween.tween_property(color_rect, "color:a", 1, 1)
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	await tween.finished
	
	#var passed_level := tree.current_scene.scene_file_path.get_file().get_basename()
	#passed_levels.append(passed_level)
	
	if "init" in params:
		params.init.call()
	
	tree.change_scene_to_file(path)
	await tree.tree_changed
	
	if "entry_point" in params:
		for node in tree.get_nodes_in_group("entry_points"):
			if node.name == params.entry_point:
				tree.current_scene.update_player(node.global_position, node.direction)
				break
				
	if "position" in params and "direction" in params:
		tree.current_scene.update_player(params.position, params.direction)
			
	tree.paused = false
	tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(color_rect, "color:a", 0, 1)

func save_game() -> void:
	var scene := get_tree().current_scene
	var scene_name := scene.scene_file_path.get_file().get_basename()
	#current_world_states[scene_name] = scene.to_dict()
	
	var data := {
		#passed_levels = passed_levels,
		#current_world_states = current_world_states,
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
	var file := FileAccess.open_encrypted(SAVE_PATH, FileAccess.WRITE, AES_KEY)

	if not file:
		return
	file.store_string(json)

func load_game() -> void:
	var file := FileAccess.open_encrypted(SAVE_PATH, FileAccess.READ, AES_KEY)
	if not file:
		return
		
	var json := file.get_as_text()
	var data := JSON.parse_string(json) as Dictionary
	
	change_scene(data.scene, {
		direction = data.player.direction,
		position = Vector2(
			data.player.position.x,
			data.player.position.y
		),
		init=func ():
			#passed_levels = data.passed_levels
			#current_world_states = data.current_world_states
			health_component.from_dict(data.health_component)
			mana_component.from_dict(data.mana_component)
	})
	
func new_game() -> void:
	change_scene("res://Scenes/level/level2.tscn", {
		init=func ():
			#passed_levels = []
			#current_world_states = {}
			health_component.from_dict(default_health_component)
			mana_component.from_dict(default_mana_component)
	})
	

func back_to_title() -> void:
	change_scene("res://Scenes/UI/titlescreen.tscn")

func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)
	
func save_music_config() -> void:
	var config := ConfigFile.new()
	
	config.set_value("audio", "master", SoundManager.get_volume(SoundManager.Bus.Master))
	config.set_value("audio", "SFX", SoundManager.get_volume(SoundManager.Bus.SFX))
	config.set_value("audio", "BGM", SoundManager.get_volume(SoundManager.Bus.BGM))
	
	config.save(MUSIC_CONFIG_PATH)
	
func load_music_config() -> void:
	var config := ConfigFile.new()
	config.load(MUSIC_CONFIG_PATH)
	
	SoundManager.set_volume(
		SoundManager.Bus.Master,
		config.get_value("audio", "master", 0.5)
	)
	SoundManager.set_volume(
		SoundManager.Bus.SFX,
		config.get_value("audio", "SFX", 1.0)
	)
	SoundManager.set_volume(
		SoundManager.Bus.BGM,
		config.get_value("audio", "BGM", 1.0)
	)
	
func save_base_config() -> void:
	var config := ConfigFile.new()
	
	config.set_value("base", "tutorial_completed", true)
	tutorial_completed = true
	
	config.save(BASE_CONFIG_PATH)

func load_base_config() -> void:
	var config := ConfigFile.new()
	
	config.load(BASE_CONFIG_PATH)
	
	tutorial_completed = config.get_value("base", "tutorial_completed", false)
