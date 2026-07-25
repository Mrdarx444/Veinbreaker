extends PlayerState

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	if state_machine.previus_state == state_machine.states[&"Fall"]:
		player.velocity.y = player.double_jump_velocity
	else :
		player.velocity.y = player.jump_velocity
	player.coyote_timer.stop()
	player.left_jumps -= 1

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	movement_handle(delta, state_owner as Player)
	super.physics_update(delta, state_owner, state_machine)

func get_next_state(player: Player) -> StringName:
	if player.velocity.y >= 0:
		return &"Fall"
	if !Input.is_action_pressed("Jump"):
		player.velocity.y *= player.jump_cut_mult
		return &"Fall"
	if can_wall_slide(player):
		return &"WallSlide"
	if (
		Input.is_action_just_pressed("Dash") and
		player.dash_cooldown_timer.is_stopped() and
		player.can_dash
	):
		return &"Dash"
	return &""
