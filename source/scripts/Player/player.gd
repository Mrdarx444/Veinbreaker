extends CharacterBody2D

@export_subgroup("Movement")
@export var speed: float = 600.0
@export var acceleration: float = speed * 8
@export var friction: float = speed * 10
@export_range(0, 1, 0.01) var aiming_slowdown_ratio: float = 0.75
@export var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
@export var max_fall_speed: float = 1500.0

@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent

# Debugging
@onready var zone_label: Label = $HUD/Zone
@onready var direction_label: Label = $HUD/Direction
@onready var move_direction_label: Label = $HUD/move_direction
@onready var velocity_label: Label = $HUD/Velocity


func _physics_process(delta: float) -> void:
	movement_handle(delta)
	gravity_handle(delta)
	move_and_slide()
	_debugg()

func gravity_handle(delta: float):
	if !is_on_floor() and velocity.y < max_fall_speed:
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
