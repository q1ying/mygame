extends Enemy

enum State {
	IDLE,
	HURT,
	SKILL,
	DIE,
}

const SKILL_PUNISHMENT := 34

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
		State.IDLE, State.HURT, State.DIE, State.SKILL:
			move(0.0, delta)

func get_next_state(state: State) -> int:
	if health_component.health == 0:
		return StateMachine.KEEP_CURRENT if state == State.DIE else State.DIE
	
	if state == State.HURT:
		if animation_player.is_playing():
			return StateMachine.KEEP_CURRENT
		else:
			return State.IDLE
	
	if pending_damage:
		return State.HURT
	
	if can_see_player():
		return State.SKILL
	
	match state:
		State.IDLE:
			return StateMachine.KEEP_CURRENT
		
		State.SKILL:
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
		State.SKILL:
			animation_player.play("skill")
			
		State.HURT:
			animation_player.play("hurt")
			health_component.health -= pending_damage.amount
			pending_damage = null		
		State.DIE:
			animation_player.play("die")

func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	pending_damage = Damage.new()
	if hitbox.hitbox_type == 0:
		pending_damage.amount = 0
	if hitbox.hitbox_type == 1:
		pending_damage.amount = 0
	pending_damage.source = hitbox.owner
	
func _on_skillbox_skill(parrybox: Variant) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = SKILL_PUNISHMENT
	pending_damage.source = parrybox.owner
