class_name ManaComponent
extends Node

signal mana_changed

@export var max_mana: float = 100
@export var mana_regen: float = 0.5

@onready var mana: float = max_mana:
	set(v):
		v = clampf(v, 0, max_mana)
		if mana == v:
			return
		mana = v
		mana_changed.emit()

func _process(delta: float) -> void:
	mana += mana_regen * delta

func to_dict() -> Dictionary:
	return {
		max_mana =max_mana,
		mana = mana
	}
	
func from_dict(dict: Dictionary) -> void:
	max_mana = dict.max_mana
	mana = dict.mana
