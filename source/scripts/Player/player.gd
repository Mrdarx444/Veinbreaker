extends CharacterBody2D

@export_subgroup("Movement")
@export var speed: float = 700.0
@export var acceleration: float = speed * 8
@export var friction: float = speed * 10
@export_range(0, 1, 0.01) var aiming_slowdown_ratio: float = 0.75
@export_subgroup("Jump & Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
@export var max_fall_speed: float = 1500.0
@export var jump_velocity: float = -900
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.15

@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer

# Debugging
@onready var zone_label: Label = $HUD/Zone
@onready var direction_label: Label = $HUD/Direction
@onready var move_direction_label: Label = $HUD/move_direction
@onready var velocity_label: Label = $HUD/Velocity
@onready var coyote_timer_label: Label = $HUD/CoyoteTimer
@onready var buffer_timer_label: Label = $HUD/BufferTimer

func _ready() -> void:
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time

func _physics_process(delta: float) -> void:
	movement_handle(delta)
	gravity_handle(delta)
	jump_handle(delta)
	move_and_slide()
	_debugg()

func gravity_handle(delta: float):
	if !is_on_floor():
		if velocity.y < max_fall_speed:
			velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	else :
		velocity.y = 0

func movement_handle(delta: float):
	match joystick.current_zone:
		joystick.AimZone.MOVE:
			velocity.x = move_toward(
				velocity.x,
				speed * joystick.move_direction,
				acceleration * delta
			)
		joystick.AimZone.MOVE_AIM_UP, joystick.AimZone.MOVE_AIM_DOWN:
			velocity.x = move_toward(
				velocity.x,
				speed * joystick.move_direction * aiming_slowdown_ratio,
				acceleration * delta
			)
		_:
			velocity.x = move_toward(
				velocity.x,
				0.0,
				friction * delta
			)

func jump_handle(delta: float):
	if is_on_floor():
		coyote_timer.start()
		if !jump_buffer_timer.is_stopped():
			velocity.y = jump_velocity
		jump_buffer_timer.stop()
	
	if Input.is_action_just_pressed("Jump"):
		if !coyote_timer.is_stopped():
			velocity.y = jump_velocity
			coyote_timer.stop()
		
		if !is_on_floor() and velocity.y > 500:
			jump_buffer_timer.start()
	
	if Input.is_action_just_released("Jump") and !is_on_floor() and velocity.y < 0:
		velocity.y = 0

func _debugg():
	zone_label.text = "Aim Zone: " + joystick.aim_zone_debbug[joystick.current_zone]
	direction_label.text = "Aim Direction: " + joystick.aim_direction_debbug[joystick.aim_direction]
	
	match int(joystick.move_direction):
		-1:
			move_direction_label.text = "Direction: Left"
		1:
			move_direction_label.text = "Direction: Right"
		_:
			move_direction_label.text = "Direction: None"
	
	velocity_label.text = "Velocity: " + str(velocity)
	
	coyote_timer_label.text = "Coyote Timer: " + str(coyote_timer.time_left)
	buffer_timer_label.text = "Jump Buffer Timer: " + str(jump_buffer_timer.time_left)
