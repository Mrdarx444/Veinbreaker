extends PlayerState

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	slow_down(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)

func slow_down(delta: float, player: Player):
	player.velocity.x = move_toward(
		player.velocity.x,
		0.0,
		player.friction * delta
	)

func get_next_state(player: Player) -> StringName:
	if player.joystick.move_direction != 0:
		return &"Move"
	if !player.is_on_floor():
		if player.velocity.y >= 0:
			player.coyote_timer.start()
			return &"Fall"
	if Input.is_action_just_pressed("Jump"):
		return &"Jump"
	if !player.jump_buffer_timer.is_stopped():
		player.jump_buffer_timer.stop()
		return &"Jump"
	if Input.is_action_just_pressed("Dash"):
		return &"Dash"
	return &""
