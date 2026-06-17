extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.velocity = Vector2.ZERO

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	super.physics_update(delta, state_owner, state_machine)

func gravity_handle(delta: float, player: Player):
	player.velocity.y += player.gravity * delta * player.wall_slide_coefficient

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		return &"Idle"
	if Input.is_action_just_pressed("Jump"):
		if player.right_raycast.is_colliding():
			player.velocity.x = -player.wall_jump_velocity_x
		if player.left_raycast.is_colliding():
			player.velocity.x = player.wall_jump_velocity_x
		return &"Jump"
	if player.joystick.move_direction == 0 or player.bottom_slide_stop_raycast.is_colliding():
		return &"Fall"
	
	return &""
