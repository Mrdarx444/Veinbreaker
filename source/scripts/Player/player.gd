extends CharacterBody2D
class_name Player

@export_category("Settings")
@export_subgroup("Movement")
@export var speed: float = 550.0
var acceleration: float = speed * 10
var friction: float = speed * 7
@export_range(0, 1, .01) var aiming_slowdown_ratio: float = 1 # Temp Canceling
var facing_direction: int = 1 # Default Facing Direction = RIGHT
@export_subgroup("Jump & Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2
@export var max_fall_speed: float = 2300.0
@export var forced_fall_velocity: float = 2000.0
@export var jump_velocity: float = -970.0
@export var double_jump_velocity: float = -800
@export_range(0, 1, .01) var jump_cut_mult: float = 0.35
@export var coyote_time: float = 0.13
@export var jump_buffer_time: float = 0.17
@export var air_resistence_coefficient: float = 0.9
@export_subgroup("Wall slide & jump")
@export_range(0, 1, .01) var wall_slide_coefficient: float = 1.1
@export var wall_slide_initial_velocity: float = 120.0
@export var wall_jump_velocity_x: float = 900.0
@export var wall_slide_max_gravity: float = gravity * 0.23
var is_wall_sliding: bool = false
@export_subgroup("Dash")
@export var is_dashing: bool = true
@export var dash_velocity: float = 2500
@export var dash_time: float = 0.125
@export var dash_cooldown_time: float = 1.15
@export var dash_gravity_coefficient: float = 0.0

@export_category("Basic Abilities")
@export var can_move: bool = true
@export var can_jump: bool = true
@export var can_dash: bool = true

@export_category("Skills")
# Default = false
@export var unlocked_double_jump: bool = true
var can_double_jump = false
@export var unlocked_forced_fall: bool = true
@export var unlocked_wall_slide: bool = true
@export var unlocked_wall_jump: bool = true

# Nodes
@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var left_raycast: RayCast2D = $RayCasts/LeftWall
@onready var right_raycast: RayCast2D = $RayCasts/RightWall
@onready var bottom_slide_stop_raycast: RayCast2D = $RayCasts/BottomSlideStop
@onready var forced_fall_raycast: RayCast2D = $RayCasts/ForcedFall
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
@onready var dash_cooldown_timer_label: Label = $HUD/Debug/DashCooldownTimer

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
	
	velocity_label.text = "Velocity:     x=%d    y=%d" % [velocity.x, velocity.y]
	
	coyote_timer_label.text = "Coyote Timer: %.2f" % coyote_timer.time_left
	buffer_timer_label.text = "Jump Buffer Timer: %.2f" % jump_buffer_timer.time_left
	dash_cooldown_timer_label.text = "Dash Cooldown: %.2f" % dash_cooldown_timer.time_left
