extends CharacterBody2D
class_name Player

@export_subgroup("Movement")
@export var speed: float = 700.0
@export var acceleration: float = speed * 8
@export var friction: float = speed * 10
@export_range(0, 1, .01) var aiming_slowdown_ratio: float = 0.75
var facing_direction: int = 1
@export_subgroup("Jump & Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
@export var max_fall_speed: float = 1500.0
@export var jump_velocity: float = -900
@export_range(0, 1, .01) var jump_cut_mult: float = 0.3
@export var coyote_time: float = 0.13
@export var jump_buffer_time: float = 0.17
#@export var jump_buffer_min_velocity: float = 500.0
@export_subgroup("Wall slide/jump")
@export_range(0, 1, .01) var wall_slide_coefficient: float = 0.45
@export var wall_jump_velocity_x: float = 800.0
@export_subgroup("Dash")
@export var is_dashing: bool = true
@export var dash_velocity: float = 5000.0
@export var dash_time: float = 0.1
@export var dash_cooldown_time: float = 0.9
@export var dash_gravity_coefficient: float = 0.07

# Nodes
@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var left_raycast: RayCast2D = $RayCasts/LeftWall
@onready var right_raycast: RayCast2D = $RayCasts/RightWall
@onready var bottom_slide_stop_raycast: RayCast2D = $RayCasts/BottomSlideStop
@onready var dash_timer: Timer = $Timers/DashTimer
@onready var dash_cooldown_timer: Timer = $Timers/DashCooldown

# Debugging
const DEBUG_MODE: bool = true
@onready var debug_labels_container: Control = $HUD/Debug
@onready var zone_label: Label = $HUD/Debug/Zone
@onready var direction_label: Label = $HUD/Debug/Direction
@onready var move_direction_label: Label = $HUD/Debug/move_direction
@onready var velocity_label: Label = $HUD/Debug/Velocity
@onready var coyote_timer_label: Label = $HUD/Debug/CoyoteTimer
@onready var buffer_timer_label: Label = $HUD/Debug/BufferTimer

func _ready() -> void:
	
	set_timers()
	debug_labels_container.visible = DEBUG_MODE

func _physics_process(delta: float) -> void:
	if joystick.move_direction: facing_direction = int(joystick.move_direction)
	if DEBUG_MODE: _debug()

func set_timers():
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time
	dash_timer.wait_time = dash_time
	dash_cooldown_timer.wait_time = dash_cooldown_time

func _debug():
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
