extends PlayerState

var _jump_duration_timer: float = 0.0

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.velocity.y = player.jump_velocity
	player.coyote_timer.stop()

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	movement_handle(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)
	_jump_duration_timer += delta

func get_next_state(player: Player) -> StringName:
	if player.velocity.y >= 0:
		return &"Fall"
	if !Input.is_action_pressed("Jump"):
		if _jump_duration_timer <= player.small_jump_max_time:
			player.velocity.y *= player.small_jump_cut_mult
		else :
			player.velocity.y *= player.jump_cut_mult
		return &"Fall"
	if can_wall_slide(player):
		return &"WallSlide"
	if Input.is_action_just_pressed("Dash") and player.can_dash:
		if player.joystick.aim_direction == player.joystick.AimDirection.UP:
			if player.dodge_cooldown_timer.is_stopped() and player.unlocked_dodge:
				return &"Dodge"
			else :
				return &""
		else :
			if player.dash_cooldown_timer.is_stopped():
				return &"Dash"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	_jump_duration_timer = 0.0
