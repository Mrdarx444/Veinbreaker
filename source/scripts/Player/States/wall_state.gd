extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.velocity = Vector2.ZERO
	player.is_wall_sliding = true

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	super.physics_update(delta, state_owner, state_machine)

func gravity_handle(delta: float, player: Player):
	player.velocity.y = min(player.velocity.y + (player.gravity * delta * player.wall_slide_coefficient), player.wall_slide_max_gravity)

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		return &"Idle"
	# Second Condition: Has no meaning but is an additional protection
	if Input.is_action_just_pressed("Jump") and player.unlocked_wall_jump:
		if player.right_raycast.is_colliding():
			player.velocity.x = -player.wall_jump_velocity_x
		elif player.left_raycast.is_colliding():
			player.velocity.x = player.wall_jump_velocity_x
		return &"Jump"
	if player.joystick.move_direction == 0 or player.bottom_slide_stop_raycast.is_colliding():
		return &"Fall"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.is_wall_sliding = false
