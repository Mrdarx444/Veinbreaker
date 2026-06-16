extends PlayerState

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	movement_handle(delta, player)
	if Input.is_action_just_pressed("Jump"): #  and player.velocity.y > player.jump_buffer_min_velocity
		player.jump_buffer_timer.start()
	super.physics_update(delta, state_owner, state_machine)

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		if player.joystick.move_direction != 0:
			return &"Move"
		else :
			return &"Idle"
	if Input.is_action_just_pressed("Jump"):
		if !player.coyote_timer.is_stopped():
			return &"Jump"
	if player.is_on_wall() and !player.is_on_floor():
		if (
			((player.left_raycast.is_colliding() and player.joystick.move_direction == -1) or 
			(player.right_raycast.is_colliding() and player.joystick.move_direction == 1)) and
			!player.bottom_slide_stop_raycast.is_colliding()
		):
			return &"WallSlide"
	
	return &""
