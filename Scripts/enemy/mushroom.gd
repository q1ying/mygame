extends Enemy

enum State {
	IDLE,
	RUN,
	HURT,
	ATTACK,
	DIE,
}

const KNOCKBACK_AMOUNT := 512.0

var pending_damage: Damage

@onready var wall_checker: RayCast2D = $Graphics/WallChecker
@onready var floor_checker: RayCast2D = $Graphics/FloorChecker
@onready var player_checker: RayCast2D = $Graphics/PlayerChecker
@onready var state_machine: StateMachine = $StateMachine
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func can_see_player() -> bool:
	if not player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player

func tick_physics(state: State, delta: float) -> void:
	match state:
		State.IDLE, State.HURT, State.DIE, State.ATTACK:
			move(0.0, delta)
		State.RUN:
			move(max_speed, delta)

func get_next_state(state: State) -> int:
	if health_component.health == 0:
		return StateMachine.KEEP_CURRENT if state == State.DIE else State.DIE
	
	if state == State.HURT:
		if animation_player.is_playing():
			return StateMachine.KEEP_CURRENT
		else:
			return State.RUN
	
	if pending_damage:
		return State.HURT
	
	if can_see_player():
		return State.ATTACK
	
	match state:
		State.IDLE:
			if state_machine.state_time > 1:
				return State.RUN
			
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE
		
		State.ATTACK:
			if not can_see_player() and not animation_player.is_playing():
				return State.IDLE
	
	return StateMachine.KEEP_CURRENT

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
				
		State.ATTACK:
			animation_player.play("attack")
			
		State.HURT:
			animation_player.play("hurt")
			health_component.health -= pending_damage.amount
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
			if dir.x > 0:
				direction = Direction.LEFT
			else:
				direction = Direction.RIGHT
			pending_damage = null		
		State.DIE:
			animation_player.play("die")


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_damage = Damage.new()
	if hitbox.hitbox_type == 0:
		pending_damage.amount = 10
	if hitbox.hitbox_type == 1:
		pending_damage.amount = 20
	pending_damage.source = hitbox.owner
