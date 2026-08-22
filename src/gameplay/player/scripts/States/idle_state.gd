extends PlayerState

var _vetrtical_look_input_timer: float = 0.0

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	await get_tree().process_frame # Remove after adding long clicking condition
	player.camera.vertical_look_enabled = true

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	slow_down(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)
	var player: Player = state_owner as Player
	if player.joystick.aim_direction: 
		_vetrtical_look_input_timer += delta
	else :
		player.camera.set_vertical_look_offset(0)
		_vetrtical_look_input_timer = 0
	
	if _vetrtical_look_input_timer > player.camera.vertical_look_input_time:
			player.camera.set_vertical_look_offset(player.joystick.aim_direction * player.camera.vertical_look_offset)
			_vetrtical_look_input_timer = 0

func slow_down(delta: float, player: Player):
	player.velocity.x = move_toward(
		player.velocity.x,
		0.0,
		player.friction * delta
	)

func get_next_state(player: Player) -> StringName:
	if player.joystick.move_direction != 0 and player.can_move:
		return &"Move"
	if !player.is_on_floor():
		if player.velocity.y >= 0:
			player.coyote_timer.start()
			return &"Fall"
	if Input.is_action_just_pressed("Jump") and player.can_jump:
		return &"Jump"
	if !player.jump_buffer_timer.is_stopped() and player.can_jump:
		player.jump_buffer_timer.stop()
		return &"Jump"
	if Input.is_action_just_pressed("Dash") and player.can_dash:
		if player.joystick.aim_direction == player.joystick.AimDirection.UP:
			if player.dodge_cooldown_timer.is_stopped() and player.unlocked_dodge:
				return &"Dodge"
			else :
				return &""
		else :
			if player.dash_cooldown_timer.is_stopped():
				return &"Dash"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	player.camera.set_vertical_look_offset(0)
	player.camera.vertical_look_enabled = false
	_vetrtical_look_input_timer = 0
