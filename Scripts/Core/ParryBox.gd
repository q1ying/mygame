class_name Parrybox
extends Area2D

signal parry(skillbox)

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(skillbox: Skillbox) -> void:
	print("[Paryy] %s => %s" % [owner.name, skillbox.owner.name])
	parry.emit(skillbox)
	skillbox.skill.emit(self)
