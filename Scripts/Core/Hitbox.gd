class_name Hitbox
extends Area2D

signal hit(hurtbox)

enum TYPE{
	ATTACK = 0,
	SKILL = +1,
}

@export var hitbox_type := TYPE.ATTACK

func _init() -> void:
	area_entered.connect(_on_area_entered)

func _on_area_entered(hurtbox: Hurtbox) -> void:
	print("[Hit] %s => %s" % [owner.name, hurtbox.owner.name])
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
