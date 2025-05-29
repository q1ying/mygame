extends Enemy

enum State {
	IDLE,
	RUN,
	HIT,
	ATTACK,
	DIE,
}

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE:
			move(0.0, delta)
		State.RUN:
			move(max_speed, delta)

func get_next_state(state: State) -> State:
	if player_checker.is_colliding():
		return State.RUN
	
	match state:
		State.IDLE:
			if state_machine.state_time > 2:
				return State.RUN
			
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
	
	return state

func transition_state(from:State, to:State) ->void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<START>",
		#State.keys()[to]
	#])
	
	match to:
		State.IDLE:
			animation_player.play("idle")
			if wall_checker.is_colliding():
				direction *= -1
		State.RUN:
			animation_player.play("run")
			if not floor_checker.is_colliding():
				direction *= -1
				floor_checker.force_raycast_update()


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	health_component.health -= 25
	if health_component.health == 0:
		queue_free()
