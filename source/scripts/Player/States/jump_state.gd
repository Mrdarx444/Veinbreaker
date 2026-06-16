extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.velocity.y = player.jump_velocity
	player.coyote_timer.stop()

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	movement_handle(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)

func get_next_state(player: Player) -> StringName:
	if player.velocity.y >= 0:
		return &"Fall"
	if player.is_on_floor():
		if player.velocity.x:
			return &"Move"
		else :
			return &"Idle"
	if Input.is_action_just_released("Jump"):
		if player.is_on_floor():
			if player.velocity.x:
				return &"Move"
			else :
				return &"Idle"
		else :
			player.velocity.y = 0
			return &"Fall"
	if player.is_on_wall() and !player.is_on_floor():
		if (
			(player.left_raycast.is_colliding() and player.joystick.move_direction == -1) or 
			(player.right_raycast.is_colliding() and player.joystick.move_direction == 1)
		):
			return &"WallSlide"
	
	return &""
