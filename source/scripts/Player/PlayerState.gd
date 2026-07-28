class_name PlayerState
extends State

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = (state_owner as Player)
	gravity_handle(delta, player)
	state_machine.change_state(get_next_state(player))
	player.move_and_slide()
	if player.is_on_floor() or player.is_wall_sliding:
		player.can_double_jump = true

func get_next_state(player: Player) -> StringName:
	return &""

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		if player.velocity.y < player.max_fall_speed:
			player.velocity.y = min(player.velocity.y + player.gravity * delta, player.max_fall_speed)
	else :
		player.velocity.y = 0

func movement_handle(delta: float, player: Player) -> void:
	if !player.can_move: return
	match player.joystick.current_zone:
		player.joystick.AimZone.MOVE:
			player.velocity.x = move_toward(
				player.velocity.x,
				player.speed * player.joystick.move_direction,
				player.acceleration * delta
			) * (player.air_resistence_coefficient if !player.is_on_floor() else 1.0)
		player.joystick.AimZone.MOVE_AIM_UP, player.joystick.AimZone.MOVE_AIM_DOWN:
			player.velocity.x = move_toward(
				player.velocity.x,
				player.speed * player.joystick.move_direction * (player.aiming_slowdown_ratio if player.is_on_floor() else 1.0),
				player.acceleration * delta
			) * (player.air_resistence_coefficient if !player.is_on_floor() else 1.0)

func can_wall_slide(player: Player) -> bool:
	# !player.is_on_wall() or
	if player.is_on_floor() or !player.unlocked_wall_slide: return false
	var moving_into_wall = (player.left_raycast.is_colliding() and player.joystick.move_direction == -1) or \
	(player.right_raycast.is_colliding() and player.joystick.move_direction == 1)
	return moving_into_wall and !player.bottom_slide_stop_raycast.is_colliding()
