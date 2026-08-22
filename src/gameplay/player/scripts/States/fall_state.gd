extends PlayerState

@export var fall_shake_max_vel_coeff: float = 0.85
var was_forced_fall: bool = false
var is_big_fall: bool = false
var _time_after_big_fall: float = 0

func enter(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	player.camera.set_falling(true)

func physics_update(delta: float, state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner
	movement_handle(delta, player)
	if Input.is_action_just_pressed("Jump"):
		if (
			player.joystick.aim_direction == player.joystick.AimDirection.DOWN and
			player.forced_fall_raycast.is_colliding() and
			player.unlocked_forced_fall
		):
			was_forced_fall = true
		else :
			player.jump_buffer_timer.start()
	super.physics_update(delta, state_owner, state_machine)
	if is_big_fall and player.big_fall_timer.is_stopped():
		_time_after_big_fall += delta
	if player.velocity.y >= player.max_fall_speed * fall_shake_max_vel_coeff:
		CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.FAST_FALL)

func movement_handle(delta: float, player: Player):
	super.movement_handle(delta, player)
	if was_forced_fall:
		player.velocity.x = 0
	if player.velocity.y >= player.max_fall_speed and !is_big_fall and player.big_fall_timer.is_stopped():
		player.big_fall_timer.start()
		is_big_fall = true

func gravity_handle(delta: float, player: Player):
	if !player.is_on_floor():
		if player.velocity.y < player.max_fall_speed:
			if was_forced_fall and player.velocity.y < player.forced_fall_velocity:
				player.velocity.y = lerp(player.velocity.y, player.forced_fall_velocity, player.forced_fall_transition)
			else :
				player.velocity.y = min(player.velocity.y + get_gravity(player) * delta, player.max_fall_speed)
	else :
		player.velocity.y = 0

func get_next_state(player: Player) -> StringName:
	if player.is_on_floor():
		if was_forced_fall: CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.FORCED_FALL)
		if is_big_fall and player.big_fall_timer.is_stopped():
			CameraManager.apply_camera_shake_preset(GameConstants.ShakePreset.BIG_FALL)
			return &"Stunned"
		if player.joystick.move_direction != 0 and player.can_move:
			return &"Move"
		else :
			return &"Idle"
	if Input.is_action_just_pressed("Jump") and player.can_jump and player.unlocked_double_jump:
		if !player.coyote_timer.is_stopped(): # Still in Coyote time window
			return &"Jump"
		if (
			player.can_double_jump and
			(
				(
					player.unlocked_forced_fall and
					player.joystick.aim_direction != player.joystick.AimDirection.DOWN
				) or
				!player.unlocked_forced_fall
			)
		):
			return &"DoubleJump"
	if can_wall_slide(player):
		return &"WallSlide"
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

func exit(state_owner: Node2D, state_machine: StateMachine) -> void:
	var player: Player = state_owner as Player
	player.camera.set_falling(false)
	was_forced_fall = false
	is_big_fall = false
	_time_after_big_fall = 0
