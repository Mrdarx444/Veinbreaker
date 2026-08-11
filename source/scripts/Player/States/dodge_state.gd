extends PlayerState


func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = (state_owner as Player)
	player.velocity.x = player.dodge_velocity * -player.facing_direction
	player.velocity.y = 0
	player.dodge_timer.start()
	player.is_dodging = true
	CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.DODGE)
	player.camera.dash_zoom_pulse(1.03, 0.3)

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		player.velocity.y = min(
			player.velocity.y + (player.gravity * delta * player.dodge_gravity_coefficient),
			player.max_fall_speed
		)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if player.dodge_timer.is_stopped():
		return &"Stunned"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = (state_owner as Player)
	player.is_dodging = false
	player.dodge_cooldown_timer.start()
