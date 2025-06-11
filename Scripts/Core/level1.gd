extends Node2D

@export var bgm: AudioStream

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var TeleporterScene : PackedScene = preload("res://Scenes/UI/teleporter.tscn")
@onready var player: Player = $Player

var all_events_finished = false

func _ready() -> void:
	var used := tile_map_layer.get_used_rect()
	var tile_size := tile_map_layer.tile_set.tile_size
	
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()
	
	if bgm:
		SoundManager.play_bgm(bgm)
	
func _physics_process(delta: float) -> void:
	var enemies_list = get_tree().get_nodes_in_group("enemies")
	if enemies_list.size() == 0 and not all_events_finished:
		show_teleporter()
		Game.save_base_config()

func update_player(pos: Vector2, direction: Player.Direction) -> void:
	player.global_position = pos
	player.direction = direction
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()

func show_teleporter() -> void:
	all_events_finished = true
	var teleporter = TeleporterScene.instantiate()
	teleporter.path = "res://Scenes/UI/titlescreen.tscn"
	#teleporter.entry_point = "NextEntry"
	add_child(teleporter)
	teleporter.global_position = Vector2(1200, 130)
