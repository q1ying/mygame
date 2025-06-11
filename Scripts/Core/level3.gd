extends Node2D

@export var bgm: AudioStream

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var player: Player = $Player
@onready var BossScene : PackedScene = preload("res://Scenes/boss.tscn")

var boss_spawned := false

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

func update_player(pos: Vector2) -> void:
	player.global_position = pos
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()

func _physics_process(delta: float) -> void:
	var enemies_list = get_tree().get_nodes_in_group("enemies")
	if enemies_list.size() == 0 and not boss_spawned:
		_spawn_boss()

func _spawn_boss() -> void:
	boss_spawned = true
	var boss = BossScene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(80, -170)
	var cb = Callable(self, "_on_boss_boss_died")
	boss.connect("boss_died", cb)
	
func _on_boss_boss_died() -> void:
	await get_tree().create_timer(1).timeout
	Game.change_scene("res://Scenes/UI/game_end_screen.tscn")
