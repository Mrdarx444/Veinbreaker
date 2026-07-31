extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	print("Dash Distance = %.2f" % (player.dash_velocity * player.dash_time))
	player.dash_timer.start()
	player.is_dashing = true
	player.velocity.y = 0
	player.velocity.x = player.dash_velocity * player.facing_direction
	if player.is_on_floor():
		CameraManager.camera_shake(GameConstents.CAMERA_SHAKE_FORCES.DASH)
	else :
		CameraManager.camera_shake(GameConstents.CAMERA_SHAKE_FORCES.AIR_DASH)

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		player.velocity.y = min(
			player.velocity.y + (player.gravity * delta * player.dash_gravity_coefficient),
			player.max_fall_speed
		)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if can_wall_slide(player):
		return &"WallSlide"
	if player.dash_timer.is_stopped():
		if player.is_on_floor():
			return &"Idle"
		else:
			if player.velocity.y >= 0:
				return &"Fall"
			else :
				return &"DoubleJump"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = (state_owner as Player)
	player.dash_cooldown_timer.start()
	player.is_dashing = false
	player.velocity.x = 0
