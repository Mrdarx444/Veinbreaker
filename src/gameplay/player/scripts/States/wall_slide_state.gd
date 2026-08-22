extends PlayerState

var _is_fast_sliding: bool = false

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.velocity = Vector2(0.0, player.wall_slide_initial_velocity)
	player.is_wall_sliding = true
	CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.WALL_STICK)

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	super.physics_update(delta, state_owner, state_machine)
	if _is_fast_sliding:
		CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.WALL_SLIDE_FAST)
	else :
		CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.WALL_SLIDE)

func gravity_handle(delta: float, player: Player):
	if player.joystick.current_zone == player.joystick.AimZone.MOVE_AIM_DOWN:
		player.velocity.y = lerp(player.velocity.y, player.wall_slide_forced_fall_gravity, 0.2)
		_is_fast_sliding = true
	else :
		player.velocity.y = min(player.velocity.y + (player.gravity * delta * player.wall_slide_coefficient), player.wall_slide_max_gravity)
		_is_fast_sliding = false

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		return &"Idle"
	if !can_wall_slide(player):
		if player.is_on_floor():
			return &"Idle"
		else :
			return &"Fall"
		
	if Input.is_action_just_pressed("Jump") and player.unlocked_wall_jump:
		return &"WallJump"
	if player.joystick.move_direction == 0 or player.bottom_slide_stop_raycast.is_colliding():
		return &"Fall"
	return &""

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	player.is_wall_sliding = false
	_is_fast_sliding = false
