class_name Skillbox
extends Area2D

signal skill(parrybox)

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(parrybox: Parrybox) -> void:
	print("[Skill] %s => %s" % [owner.name, parrybox.owner.name])
	skill.emit(parrybox)
	parrybox.parry.emit(self)
