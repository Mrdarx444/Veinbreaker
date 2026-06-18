extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.dash_timer.start()
	player.is_dashing = true
	player.velocity.y = 0
	player.velocity.x = player.dash_velocity * player.facing_direction

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		player.velocity.y = min(
			player.velocity.y + (player.gravity * delta * player.dash_gravity_coefficient),
			player.max_fall_speed
		)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if player.dash_timer.is_stopped():
		print("test")
		player.is_dashing = false
		player.velocity.x = 0
		return &"Idle"
	return &""
