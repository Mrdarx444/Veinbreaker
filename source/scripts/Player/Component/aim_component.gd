class_name PlayerAimComponent
extends Node

enum AimZone { MOVE, MOVE_AIM_UP, MOVE_AIM_DOWN, AIM_UP_IDLE }
enum AimDirection { FORWARD, UP, DOWN }

# Debugg
var aim_zone_debbug := {
	AimZone.MOVE: "Move",
	AimZone.MOVE_AIM_UP: "Move Aim Up",
	AimZone.MOVE_AIM_DOWN: "Move Aim Down",
	AimZone.AIM_UP_IDLE: "Aim Up Idle"
}

var aim_direction_debbug := {
	AimDirection.FORWARD: "Forward",
	AimDirection.UP: "Up",
	AimDirection.DOWN: "Down"
}

@export_range(0, 1, 0.01) var AIM_THRESHOLD  : float = 0.5
@export_range(0, 1, 0.01) var IDLE_THRESHOLD : float = 0.2

var current_zone     : AimZone     = AimZone.MOVE
var aim_direction    : AimDirection = AimDirection.FORWARD
var move_direction   : float = 0.0  # -1, 0, 1

func _physics_process(delta: float) -> void:
	var input_vector := Input.get_vector("Left", "Right", "Up", "Down")
	var x = input_vector.x
	var y = input_vector.y
	move_direction = 0.0

	if abs(x) > IDLE_THRESHOLD:
		move_direction = sign(x)
		if y < -AIM_THRESHOLD:
			current_zone  = AimZone.MOVE_AIM_UP
			aim_direction = AimDirection.UP
		elif y > AIM_THRESHOLD:
			current_zone  = AimZone.MOVE_AIM_DOWN
			aim_direction = AimDirection.DOWN
		else:
			current_zone  = AimZone.MOVE
			aim_direction = AimDirection.FORWARD
	elif y < -AIM_THRESHOLD:
		current_zone  = AimZone.AIM_UP_IDLE
		aim_direction = AimDirection.UP
	else:
		current_zone  = AimZone.MOVE
		aim_direction = AimDirection.FORWARD
