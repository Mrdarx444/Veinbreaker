extends CharacterBody2D
class_name Player

@export_subgroup("Movement")
@export var speed: float = 700.0
@export var acceleration: float = speed * 8
@export var friction: float = speed * 10
@export_range(0, 1, .01) var aiming_slowdown_ratio: float = 0.75
@export_subgroup("Jump & Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
@export var max_fall_speed: float = 1500.0
@export var jump_velocity: float = -900
@export_range(0, 1, .01) var jump_cut_mult: float = 0.2
@export var coyote_time: float = 0.12
@export var jump_buffer_time: float = 0.15
#@export var jump_buffer_min_velocity: float = 500.0
@export_subgroup("Wall slide/jump")
@export_range(0, 1, .01) var wall_slide_coeffitient: float = 0.1
@export var wall_jump_velocity_x: float = 1000.0

# Nodes
@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var left_raycast: RayCast2D = $RayCasts/LeftWall
@onready var right_raycast: RayCast2D = $RayCasts/RightWall
@onready var bottom_slide_stop_raycast: RayCast2D = $RayCasts/BottomSlideStop

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
	move_and_slide()
	_debugg()

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
