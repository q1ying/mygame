class_name Enemy
extends CharacterBody2D

enum Direction{
	LEFT = -1,
	RIGHT = +1,
}
@onready var graphics: Node2D = $Graphics

@export var direction := Direction.LEFT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = -direction
		
@export var max_speed :float = 180
@export var accelation: float = 2000
@export var default_gravity:= ProjectSettings.get("physics/2d/default_gravity") as float
@onready var health_component: HealthComponent = $HealthComponent

func move(speed: float, delta: float) -> void:
	velocity.x = move_toward(velocity.x, speed * direction, accelation * delta)
	velocity.y += default_gravity * delta
	
	move_and_slide()
