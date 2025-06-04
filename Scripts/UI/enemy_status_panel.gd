extends HBoxContainer

@export var healthcomponent: HealthComponent

@onready var health_bar: TextureProgressBar = $HealthBar

func _ready() -> void:
	healthcomponent.health_changed.connect(update_health)
	update_health()

func update_health() -> void:
	var percantage := healthcomponent.health / float(healthcomponent.max_health)
	health_bar.value = percantage
