extends Enemy

signal boss_died

@onready var ai_decision: AIDecision = $AIDecision
@onready var player_checker: RayCast2D = $"Graphics/PlayerChecker"
@onready var wall_checker:   RayCast2D = $"Graphics/WallChecker"
@onready var floor_checker:  RayCast2D = $"Graphics/FloorChecker"
@onready var animation_player: AnimationPlayer = $"AnimationPlayer"
@onready var state_machine: StateMachine = $StateMachine
@onready var player: Node

func _ready():
	super()
	var players = get_tree().get_nodes_in_group("players")
	if players.size() > 0:
		player = players[0]
	else:
		push_error("not found Player！")
		
	randomize()

func _physics_process(_delta: float) -> void:
	check_start_combo()
	
func die() -> void:
	super()
	boss_died.emit()

enum State {
	IDLE,
	APPROACH,
	RETREAT,
	RUN,
	HURT,
	ATTACK,
	SKILL,
	PARRY,
	DIE,
}

const KNOCKBACK_AMOUNT := 512.0
const SKILL_MANA := 50.0
const PARRY_PUNISHMENT := 100
const SKILL_PUNISHMENT := 250
const L: int = 3

var pending_damage: Damage = null
var combo_sequence: Array = []
var combo_index: int = 0
var in_combo: bool = false
var is_parry_skill = false

var last_env: Dictionary = {
	"player_hp":  0.0,
	"boss_hp":    0.0,
	"player_mp":  0.0,
	"boss_mp":    0.0,
	"dist_diff":  0.0
}

func get_next_state(state: State) -> int:
	if health_component.health <= 0:
		return StateMachine.KEEP_CURRENT if state == State.DIE else State.DIE

	if pending_damage != null:
		in_combo = false
		combo_sequence.clear()
		combo_index = 0
		return State.HURT
	
	if in_combo:
		var current_action: String = combo_sequence[combo_index]
		if current_action == "approach" or current_action == "retreat":
			if state_machine.state_time <= 0.5:
				return StateMachine.KEEP_CURRENT
		else:
			if current_action == "idle":
				if state_machine.state_time <= 0.6:
					return StateMachine.KEEP_CURRENT
			else:
				if animation_player.is_playing():
					return StateMachine.KEEP_CURRENT
		combo_index += 1
		if combo_index < combo_sequence.size():
			return _action_to_state(combo_sequence[combo_index])
		else:
			in_combo = false
			combo_sequence.clear()
			combo_index = 0
			return State.IDLE
		
	match state:
		State.IDLE:
			if state_machine.state_time > 1.0:
				return State.RUN
		State.RUN:
			if wall_checker.is_colliding() or not floor_checker.is_colliding():
				return State.IDLE

	return StateMachine.KEEP_CURRENT


func tick_physics(state: State, delta: float) -> void:
	match state:
		State.APPROACH:
			if is_instance_valid(player):
				var dir_vec : Vector2 = player.global_position - global_position
				direction = Direction.LEFT if dir_vec.x < 0.0 else Direction.RIGHT
				move(max_speed, delta)

		State.RETREAT:
			if is_instance_valid(player):
				var dir_vec : Vector2 = player.global_position - global_position
				direction = Direction.RIGHT if dir_vec.x < 0.0 else Direction.RIGHT
				move(max_speed, delta)
					
		State.IDLE, State.HURT, State.DIE, State.ATTACK, State.SKILL, State.PARRY:
			move(0.0, delta)
		State.RUN:
			move(max_speed, delta)

func transition_state(from: State, to: State) -> void:
	print("[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	
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
		State.ATTACK:
			animation_player.play("attack")
		State.SKILL:
			animation_player.play("skill")
			mana_component.mana -= SKILL_MANA
		State.PARRY:
			animation_player.play("parry")
			await get_tree().create_timer(0.4).timeout
			if not animation_player.is_playing() and not is_parry_skill:
				mana_component.mana -= PARRY_PUNISHMENT
			is_parry_skill = false
		State.DIE:
			animation_player.play("die")
		State.APPROACH:
			animation_player.play("run")
			if is_instance_valid(player):
				if player.global_position.x < global_position.x:
					direction = Direction.LEFT
				else:
					direction = Direction.RIGHT
		State.RETREAT:
			animation_player.play("run")
			if is_instance_valid(player):
				if player.global_position.x < global_position.x:
					direction = Direction.RIGHT
				else:
					direction = Direction.LEFT

func _can_see_player() -> bool:
	if not player_checker.is_colliding():
		return false
	return player_checker.get_collider() is Player

func check_start_combo() -> void:
	if in_combo:
		return
	
	if not _can_see_player():
		return

	if not is_instance_valid(player):
		return

	var p_hp = player.health_component.health
	var p_mp = player.mana_component.mana
	var b_hp := health_component.health
	var b_mp := mana_component.mana
	var dist := global_position.distance_to(player.global_position)
	dist = clamp(dist, 0.0, 500.0)

	last_env["player_hp"] = p_hp
	last_env["boss_hp"]   = b_hp
	last_env["player_mp"] = p_mp
	last_env["boss_mp"]   = b_mp
	last_env["dist_diff"] = dist

	print(last_env)
	var seq: Array = ai_decision.decide_sequence(last_env)
	print(seq)
	if seq.size() != L:
		return

	combo_sequence = seq.duplicate()
	combo_index = 0
	in_combo = true

	var first_action: String = combo_sequence[combo_index]
	state_machine.current_state = _action_to_state(first_action)
	
func _action_to_state(action_name: String) -> int:
	match action_name:
		"approach":
			return State.APPROACH
		"retreat":
			return State.RETREAT
		"attack":
			return State.ATTACK
		"skill":
			return State.SKILL
		"parry":
			return State.PARRY
		"idle":
			return State.IDLE
		_:
			return State.IDLE


func _on_hurtbox_hurt(hitbox: Hitbox) -> void:
	if pending_damage != null:
		return
	pending_damage = Damage.new()
	if hitbox.hitbox_type == 0:
		pending_damage.amount = 500
	if hitbox.hitbox_type == 1 and not is_parry_skill:
		pending_damage.amount = 125
	pending_damage.source = hitbox.owner

func _on_skillbox_skill(parrybox: Variant) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = SKILL_PUNISHMENT
	pending_damage.source = parrybox.owner

func _on_parrybox_parry(skillbox: Variant) -> void:
	is_parry_skill = true
