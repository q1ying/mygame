extends CharacterBody2D

enum State{
	IDLE,
	RUN,
	JUMP,
	FALL,
	ATTACK,
}

const NO_GROUND_STATES := [State.JUMP,State.FALL]
const RUN_SPEED := 160.0
const JUMP_VELOCITY := -300.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var sprite_2d: Sprite2D = $Graphics/Sprite2D

@export var default_gravity:= ProjectSettings.get("physics/2d/default_gravity") as float
var is_first_tick := false
@onready var coyote_timer: Timer = $coyoteTimer
@onready var jump_request_timer: Timer = $JumpRequestTimer

#预输入jump
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("jump"):
		jump_request_timer.start()
	if event.is_action_released("jump") and velocity.y < JUMP_VELOCITY / 2:
		velocity.y = JUMP_VELOCITY / 2

func tick_physics(state:State, delta: float) -> void:
	match state:
		State.IDLE:
			move(default_gravity, delta)

		State.RUN:
			move(default_gravity, delta)

		State.JUMP:
			move(0.0 if is_first_tick else default_gravity, delta)

		State.FALL:
			move(default_gravity, delta)
		
		State.ATTACK:
			stand(delta)
	
	is_first_tick = false
	
func stand(delta: float) -> void:
	var direction := Input.get_axis("move_left","move_right")
	velocity.x = 0.0
	velocity.y += default_gravity * delta

	move_and_slide()

func move(gravity:float, delta: float) -> void:
	var direction := Input.get_axis("move_left","move_right")
	velocity.x = direction * RUN_SPEED
	velocity.y += gravity * delta
	
	if not is_zero_approx(direction):
		sprite_2d.flip_h = direction < 0
			
	var was_on_floor := is_on_floor()
	move_and_slide()

func get_next_state(state: State) -> State:
	var can_jump := is_on_floor() or coyote_timer.time_left > 0
	var should_jump := is_on_floor() and Input.is_action_just_pressed("jump")
	if should_jump:
		return State.JUMP
		
	if state not in NO_GROUND_STATES and not is_on_floor():
		return State.FALL
		
	var direction := Input.get_axis("move_left","move_right")
	var is_still := is_zero_approx(direction) and is_zero_approx(velocity.x)
	
	match state:
		State.IDLE:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK
			if not is_still:
				return State.RUN
			
		State.RUN:
			if Input.is_action_just_pressed("attack"):
				return State.ATTACK
			if is_still:
				return State.IDLE
			
		State.JUMP:
			if velocity.y >= 0:
				return State.FALL
			
		State.FALL:
			if is_on_floor():
				return State.IDLE
				
		State.ATTACK:
			if not animation_player.is_playing():
				return State.IDLE
	
	return state

func transition_state(from:State, to:State) ->void:
	print("[%s] %s => %s" % [
		Engine.get_physics_frames(),
		State.keys()[from] if from != -1 else "<START>",
		State.keys()[to]
	])
	
	if from in NO_GROUND_STATES and to not in NO_GROUND_STATES:
		coyote_timer.start()
		
	match to:
		State.IDLE:
			animation_player.play("idle_unarmed")
		State.RUN:
			animation_player.play("run_unarmed")
		State.JUMP:
			animation_player.play("jump")
			velocity.y = JUMP_VELOCITY
			coyote_timer.stop()
			jump_request_timer.stop()
		State.FALL:
			animation_player.play("fall")
			if from not in NO_GROUND_STATES:
				coyote_timer.start()
		State.ATTACK:
			animation_player.play("attack_unarmed")
				
	is_first_tick = true
