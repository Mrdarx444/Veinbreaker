extends PlayerState

var forced_fall: bool = false

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	movement_handle(delta, player)
	if Input.is_action_just_pressed("Jump"):
		# Update Conditions HERE! (Certain Height)
		if player.joystick.aim_direction == player.joystick.AimDirection.DOWN:
			forced_fall = true
			print("test 1")
		else :
			player.jump_buffer_timer.start()
	super.physics_update(delta, state_owner, state_machine)


func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		if player.velocity.y < player.max_fall_speed:
			if forced_fall:
				player.velocity.y = player.forced_fall_velocity
				print("test 2")
			else :
				player.velocity.y = min(player.velocity.y + player.gravity * delta, player.max_fall_speed)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		if player.joystick.move_direction != 0:
			return &"Move"
		else :
			return &"Idle"
	if Input.is_action_just_pressed("Jump"):
		if !player.coyote_timer.is_stopped():
			return &"Jump"
	if can_wall_slide(player):
		return &"WallSlide"
	if Input.is_action_just_pressed("Dash") and player.dash_cooldown_timer.is_stopped():
		return &"Dash"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	forced_fall = false
