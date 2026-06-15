class_name PlayerState
extends State

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	gravity_handle(delta, state_owner as Player)
	state_machine.change_state(get_next_state(player))

func get_next_state(player: Player) -> StringName:
	
	return &""

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		if player.velocity.y < player.max_fall_speed:
			player.velocity.y = min(player.velocity.y + player.gravity * delta, player.max_fall_speed)
	else :
		player.velocity.y = 0

func movement_handle(delta: float, player: Player):
	match player.joystick.current_zone:
		player.joystick.AimZone.MOVE:
			player.velocity.x = move_toward(
				player.velocity.x,
				player.speed * player.joystick.move_direction,
				player.acceleration * delta
			)
		player.joystick.AimZone.MOVE_AIM_UP, player.joystick.AimZone.MOVE_AIM_DOWN:
			player.velocity.x = move_toward(
				player.velocity.x,
				player.speed * player.joystick.move_direction * player.aiming_slowdown_ratio,
				player.acceleration * delta
			)
	player.move_and_slide()
