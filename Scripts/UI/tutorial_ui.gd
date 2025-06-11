extends CanvasLayer

@onready var label: Label = $Label

func _ready():
	hide()

# 外部传一个已经 bind 好参数的 Callable，调用后显示 3 秒再隐藏
func show_by_callable(fn: Callable) -> void:
	fn.call()  # 执行 label.set_text(…)
	show()
	await get_tree().create_timer(3.0).timeout
	hide()
