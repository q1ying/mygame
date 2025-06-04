extends Node2D

@onready var camera_2d: Camera2D = $Player/Camera2D
@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var TeleporterScene : PackedScene = preload("res://Scenes/UI/teleporter.tscn")
@onready var BossScene : PackedScene = preload("res://Scenes/boss.tscn")
@onready var player: Player = $Player

var boss_spawned := false

func _ready() -> void:
	var used := tile_map_layer.get_used_rect()
	var tile_size := tile_map_layer.tile_set.tile_size
	
	camera_2d.limit_top = used.position.y * tile_size.y
	camera_2d.limit_right = used.end.x * tile_size.x
	camera_2d.limit_bottom = used.end.y * tile_size.y
	camera_2d.limit_left = used.position.x * tile_size.x
	camera_2d.reset_smoothing()
	
func _physics_process(delta: float) -> void:
	var enemies_list = get_tree().get_nodes_in_group("enemies")
	if enemies_list.size() == 0 and not boss_spawned:
		_spawn_boss()
	
func _on_boss_boss_died() -> void:
	await get_tree().create_timer(1).timeout
	var teleporter = TeleporterScene.instantiate()
	teleporter.path = "res://Scenes/level/level3.tscn"
	teleporter.entry_point = "NextEntry"
	add_child(teleporter)
	teleporter.global_position = Vector2(1050, 180)

func update_player(pos: Vector2) -> void:
	player.global_position = pos
	player.fall_from_y = pos.y
	camera_2d.reset_smoothing()
	camera_2d.force_update_scroll()
	
func _spawn_boss() -> void:
	boss_spawned = true
	var boss = BossScene.instantiate()
	add_child(boss)
	boss.global_position = Vector2(776, 144)
	var cb = Callable(self, "_on_boss_boss_died")
	boss.connect("boss_died", cb)

func to_dict() -> Dictionary:
	var enemies_alive := []
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node)
		enemies_alive.append(path)
	
	return{
		enemies_alive = enemies_alive
	}
	
func from_dict(dict: Dictionary) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var path := get_path_to(node)
		if path not in dict.enemies_alive:
			node.queue_free()
