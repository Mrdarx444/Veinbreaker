extends PlayerState

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	movement_handle(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)

func get_next_state(player: Player) -> StringName:
	if player.joystick.move_direction == 0 and player.is_on_floor():
		return &"Idle"
	if !player.is_on_floor():
		if player.velocity.y >= 0:
			player.coyote_timer.start()
			return &"Fall"
	if Input.is_action_just_pressed("Jump") and player.can_jump:
		return &"Jump"
	if !player.jump_buffer_timer.is_stopped() and player.can_jump:
		player.jump_buffer_timer.stop()
		return &"Jump"
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
