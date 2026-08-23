extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	if player.right_wall_raycasts.is_colliding():
		player.velocity.x = -player.wall_jump_velocity.x
	elif player.left_wall_raycasts.is_colliding():
		player.velocity.x = player.wall_jump_velocity.x
	
	player.velocity.y = player.wall_jump_velocity.y

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	super.physics_update(delta, state_owner, state_machine)
	movement_handle(delta, state_owner as Player)

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		if abs(player.velocity.x) > 0:
			return &"Move"
		else :
			return &"Idle"
	else :
		if can_wall_slide(player):
			return &"WallSlide"
		if player.velocity.y >= 0:
			return &"Fall"
	#if !Input.is_action_pressed("Jump"):
		#player.velocity.y *= player.wall_jump_cut_mult
		#return &"Fall"
	if Input.is_action_just_pressed("Dash") and player.can_dash:
		if player.joystick.aim_direction == player.joystick.AimDirection.UP:
			if player.dodge_cooldown_timer.is_stopped() and player.unlocked_dodge:
				return &"Dodge"
			else :
				return &""
		else :
			if player.dash_cooldown_timer.is_stopped() and player.air_dash_current_times > 0:
				return &"Dash"
	return &""
