extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player

	_set_stunning_time(player, state_machine)

	player.stunning_timer.start()

func _set_stunning_time(player: Player, state_machine: StateMachine):
	match state_machine.previus_state.name:
		&"Dodge":
			player.stunning_timer.wait_time = player.dodge_stunning_time
		&"Fall":
			player.stunning_timer.wait_time = player.big_fall_stunning_time
			player.can_move = false
		_:
			player.stunning_timer.wait_time = player.default_stunning_time

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	slow_down(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)

func slow_down(delta: float, player: Player):
	player.velocity.x = move_toward(
		player.velocity.x,
		0.0,
		player.default_stunning_friction * delta
	)

func get_next_state(player: Player) -> StringName:
	if player.stunning_timer.is_stopped():
		if player.is_on_floor():
			if player.joystick.move_direction != 0 and player.can_move:
				return &"Move"
			else :
				return &"Idle"
		else :
			return &"Fall"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	player.can_move = true
