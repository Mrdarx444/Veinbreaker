extends PlayerState

var forced_fall: bool = false

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	movement_handle(delta, player)
	if Input.is_action_just_pressed("Jump"):
		if (
			player.joystick.aim_direction == player.joystick.AimDirection.DOWN and
			player.forced_fall_raycast.is_colliding() and
			player.unlocked_forced_fall
		):
			forced_fall = true
		else :
			player.jump_buffer_timer.start()
	super.physics_update(delta, state_owner, state_machine)

func movement_handle(delta: float, player: Player):
	super.movement_handle(delta, player)
	if forced_fall:
		player.velocity.x = 0

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		if player.velocity.y < player.max_fall_speed:
			if forced_fall:
				player.velocity.y = player.forced_fall_velocity
			else :
				player.velocity.y = min(player.velocity.y + player.gravity * delta, player.max_fall_speed)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		if player.joystick.move_direction != 0 and player.can_move:
			return &"Move"
		else :
			return &"Idle"
	if Input.is_action_just_pressed("Jump") and player.can_jump and player.unlocked_double_jump:
		if !player.coyote_timer.is_stopped(): # Still in Coyote time window
			return &"Jump"
		if (
			player.can_double_jump and
			(
				(
					player.unlocked_forced_fall and
					player.joystick.aim_direction != player.joystick.AimDirection.DOWN
				) or
				!player.unlocked_forced_fall
			)
		):
			return &"DoubleJump"
	if can_wall_slide(player):
		return &"WallSlide"
	if (
		Input.is_action_just_pressed("Dash") and
		player.dash_cooldown_timer.is_stopped() and
		player.can_dash
	):
		if player.joystick.aim_direction == player.joystick.AimDirection.UP:
			if player.dodge_cooldown_timer.is_stopped() and player.unlocked_dodge:
				return &"Dodge"
			else :
				return &""
		else :
			return &"Dash"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	forced_fall = false
