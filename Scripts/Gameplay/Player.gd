class_name Player
extends CharacterBody2D

enum Direction {
	LEFT = -1,
	RIGHT = +1
}

enum State{
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK_1,
	ATTACK_2,
	HURT,
	DIE,
	SKILL,
	PARRY
}

@export var can_combo := false
@export var default_gravity:= ProjectSettings.get("physics/2d/default_gravity") as float
@export var direction := Direction.RIGHT:
	set(v):
		direction = v
		if not is_node_ready():
			await ready
		graphics.scale.x = direction

const NO_GROUND_STATES := [State.JUMP,State.FALL, State.SKILL]
const RUN_SPEED := 160.0
const JUMP_VELOCITY := -300.0
const KNOCKBACK_AMOUNT := 512.0
const SKILL_MANA := 5.0
const SKILL_SPEED := 50.0
const FLOOR_ACCELERATION := RUN_SPEED / 0.2
const SKILL_LAUNCH_VELOCITY := -400.0
const SKILL_DESCEND_VELOCITY := 800.0
const PARRY_PUNISHMENT := 10
const SKILL_PUNISHMENT := 50
const ATTACK_DAMAGE := 10
const SKILL_DAMAGE := 25

var is_first_tick := false
var is_combo_requested := false
var pending_damage: Damage
var skill_launched := false
var is_parry_skill = false
var interacting_with: Array[Interactable]

@onready var graphics: Node2D = $Graphics
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var coyote_timer: Timer = $coyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer
@onready var invincible_timer: Timer = $InvincibleTimer
@onready var state_machine: StateMachine = $StateMachine
@onready var health_component: HealthComponent = Game.health_component
@onready var mana_component: ManaComponent = Game.mana_component
@onready var interaction_icon: AnimatedSprite2D = $InteractionIcon
@onready var gameover: Control = $CanvasLayer/Gameover
@onready var pause_screen: Control = $CanvasLayer/PauseScreen


func _ready() -> void:
	add_to_group("players")

func can_skill() -> bool:
	if mana_component.mana < SKILL_MANA:
		return false
	return true

#预输入jump
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		velocity.y = JUMP_VELOCITY / 2
	if event.is_action_pressed("attack") and can_combo:
		is_combo_requested = true
		
	if event.is_action_pressed("interact") and interacting_with:
		interacting_with.back().interact()
		
	if event.is_action_pressed("pause"):
		pause_screen.show_pause()

func tick_physics(state:State, delta: float) -> void:
	interaction_icon.visible = not interacting_with.is_empty()
	
	if invincible_timer.time_left > 0:
		graphics.modulate.a = sin(Time.get_ticks_msec() / 20) * 0.5 + 0.5
	else:
		graphics.modulate.a = 1
	
	match state:
		State.IDLE:
			move(default_gravity, delta)

		State.RUN:
			move(default_gravity, delta)

		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)

		State.FALL:
			move(default_gravity, delta)
		
		State.ATTACK_1, State.ATTACK_2:
			stand(default_gravity,delta)
		
		State.HURT, State.DIE:
			stand(default_gravity, delta)
			
		State.SKILL:
			skill(delta)
		
		State.PARRY:
			stand(default_gravity, delta)
			
	is_first_tick = false
	
func stand(gravity:float, delta: float) -> void:
	var acceleration := FLOOR_ACCELERATION
	velocity.x = move_toward(velocity.x, 0.0, acceleration * delta)
	velocity.y += gravity * delta

	move_and_slide()

func move(gravity:float, delta: float) -> void:
	var movement := Input.get_axis("move_left","move_right")
	velocity.x = movement * RUN_SPEED
	velocity.y += gravity * delta
	
	if not is_zero_approx(movement):
		direction = Direction.LEFT if movement < 0 else Direction.RIGHT
			
	move_and_slide()
	
func die() -> void:
	gameover.show_game_over()
	
func skill(delta: float) -> void:
	velocity.x = graphics.scale.x * SKILL_SPEED

	if not skill_launched:
		velocity.y = 0
	else:
		velocity.y += default_gravity * delta
	move_and_slide()
	
func register_interactable(v: Interactable) -> void:
	if state_machine.current_state == State.DIE:
		return
	if v in interacting_with:
		return
	interacting_with.append(v)
	
func unregister_interactable(v: Interactable) -> void:
	interacting_with.erase(v)

func get_next_state(state: State) -> int:
	if health_component.health == 0:
		return State.DIE
		
	if pending_damage:
		return State.HURT
		
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := is_on_floor() and Input.is_action_just_pressed("jump")
	if should_jump:
		return State.JUMP
		
	if state not in NO_GROUND_STATES and not is_on_floor():
		return State.FALL
		
	var movement := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(movement) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if Input.is_action_just_pressed("skill") and can_skill():
				return State.SKILL
			if Input.is_action_just_pressed("parry"):
				return State.PARRY
			if not is_still:
				return State.RUN
			
		State.RUN:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK_1
			if Input.is_action_just_pressed("skill") and can_skill():
				return State.SKILL
			if Input.is_action_just_pressed("parry"):
				return State.PARRY
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if Input.is_action_just_pressed("skill") and can_skill():
				return State.SKILL
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if Input.is_action_just_pressed("skill") and can_skill():
				return State.SKILL
			if is_on_floor():
				return State.IDLE
				
		State.ATTACK_1:
			if not animation_player.is_playing():
				return State.ATTACK_2 if is_combo_requested else State.IDLE
		
		State.ATTACK_2:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.HURT:
			if not animation_player.is_playing():
				return State.IDLE
				
		State.SKILL:
			if not animation_player.is_playing():
				return State.IDLE
			if not animation_player.is_playing() and velocity.y >= 0:
				return State.FALL
				
		State.PARRY:
			if not animation_player.is_playing():
				if not is_parry_skill:
					mana_component.mana -= PARRY_PUNISHMENT
					return State.IDLE
				else:
					is_parry_skill = false
					return State.IDLE
			
			
	
	return StateMachine.KEEP_CURRENT

func transition_state(from:State, to:State) ->void:
	#print("[%s] %s => %s" % [
		#Engine.get_physics_frames(),
		#State.keys()[from] if from != -1 else "<START>",
		#State.keys()[to]
	#])
	
	if from in NO_GROUND_STATES and to not in NO_GROUND_STATES:
		coyote_timer.start()
		
	match to:
		State.IDLE:
			animation_player.play("idle")
		State.RUN:
			animation_player.play("run")
		State.JUMP:
			animation_player.play("jump")
			SoundManager.play_sfx("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
		State.FALL:
			animation_player.play("fall")
			if from not in NO_GROUND_STATES:
				coyote_timer.start()
		State.ATTACK_1:
			animation_player.play("attack_1")
			SoundManager.play_sfx("attack")
			is_combo_requested = false
		
		State.ATTACK_2:
			animation_player.play("attack_2")
			SoundManager.play_sfx("attack")
			is_combo_requested = false
			
		State.HURT:
			animation_player.play("hurt")
			SoundManager.play_sfx("hurt")
			health_component.health -= pending_damage.amount
			var dir := pending_damage.source.global_position.direction_to(global_position)
			velocity = dir * KNOCKBACK_AMOUNT
					
			pending_damage = null
			invincible_timer.start()
		State.DIE:
			animation_player.play("die")
			SoundManager.play_sfx("die")
			invincible_timer.stop()
			interacting_with.clear()
			
		State.SKILL:
			animation_player.play("skill")
			SoundManager.play_sfx("skill")
			mana_component.mana -= SKILL_MANA
			skill_launched = false
		State.PARRY:
			animation_player.play("parry")
			SoundManager.play_sfx("parry")
			
	is_first_tick = true


func skill_launch() -> void:
	if not skill_launched:
		velocity.y = SKILL_LAUNCH_VELOCITY
		skill_launched = true

func skill_descend() -> void:
	velocity.y = SKILL_DESCEND_VELOCITY

func _on_hurtbox_hurt(hitbox: Variant) -> void:
	if invincible_timer.time_left > 0:
		return
	
	if not is_parry_skill:
		pending_damage = Damage.new()
		if hitbox.hitbox_type == 0:
			pending_damage.amount = ATTACK_DAMAGE
		if hitbox.hitbox_type == 1:
			pending_damage.amount = SKILL_DAMAGE

		pending_damage.source = hitbox.owner


func _on_skillbox_skill(parrybox: Variant) -> void:
	pending_damage = Damage.new()
	pending_damage.amount = SKILL_PUNISHMENT
	pending_damage.source = parrybox.owner

func _on_parrybox_parry(skillbox: Variant) -> void:
	is_parry_skill = true
