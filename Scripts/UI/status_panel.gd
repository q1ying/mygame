extends HBoxContainer

@export var healthcomponent: HealthComponent
@export var manacomponent: ManaComponent

@onready var health_bar: TextureProgressBar = $V/HealthBar
@onready var eased_health_bar: TextureProgressBar = $V/HealthBar/EasedHealthBar
@onready var mana_bar: TextureProgressBar = $V/ManaBar
@onready var eased_mana_bar: TextureProgressBar = $V/ManaBar/EasedManaBar


func _ready() -> void:
	if not healthcomponent:
		healthcomponent = Game.health_component
	if not manacomponent:
		manacomponent = Game.mana_component
	
	healthcomponent.health_changed.connect(update_health)
	update_health(true)
	
	manacomponent.mana_changed.connect(update_mana)
	update_mana(true)

func update_health(skip_anim := false) -> void:
	var percantage := healthcomponent.health / float(healthcomponent.max_health)
	health_bar.value = percantage
	
	if skip_anim:
		eased_health_bar.value = percantage
	else:
		create_tween().tween_property(eased_health_bar, "value", percantage, 0.3)


func update_mana(skip_anim := false) -> void:
	var percantage := manacomponent.mana / manacomponent.max_mana
	mana_bar.value = percantage
	if skip_anim:
		eased_mana_bar.value = percantage
	else:
		create_tween().tween_property(eased_mana_bar, "value", percantage, 0.3)
