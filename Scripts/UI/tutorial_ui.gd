extends CanvasLayer

@onready var label: Label = $Label

func _ready():
	hide()

func show_by_callable(fn: Callable) -> void:
	fn.call()
	show()
	await get_tree().create_timer(5.0).timeout
	hide()
