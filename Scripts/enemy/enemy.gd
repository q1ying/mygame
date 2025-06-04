class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT = -1,
	RIGHT = +1,
}
@onready var graphics: Node2D = $Graphics

@export var flip_factor := -1

@export var direction := Direction.LEFT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = flip_factor * direction
		
@export var max_speed :float = 100
@export var accelation: float = 2000
@export var default_gravity:= ProjectSettings.get("physics/2d/default_gravity") as float
@onready var health_component: HealthComponent = $HealthComponent
@onready var mana_component: ManaComponent = $ManaComponent

func _ready() -> void:
	add_to_group("enemies")

func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, speed * direction, accelation * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()
	
func die() -> void:
	queue_free()
