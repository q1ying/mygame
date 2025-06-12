extends Area2D

@export var line: String = ""

signal interacted

func _init() -> void:
	collision_layer = 0
	collision_mask = 0
	set_collision_mask_value(2, true)
	
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	
func interact() -> void:
	print("[Interact] %s" % name)
	interacted.emit()
	
func _on_body_entered(player: Player) -> void:
	var ui = get_tree().current_scene.get_node("TutorialUI")
	var fn: Callable = ui.label.set_text.bind(line)
	ui.show_by_callable(fn)

func _on_body_exited(player: Player) -> void:
	queue_free()
