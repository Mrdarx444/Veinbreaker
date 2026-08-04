extends CharacterBody2D
class_name Player

@export_category("Settings")
@export_subgroup("Movement")
@export var speed: float = 450.0
var acceleration: float = speed * 10
var friction: float = speed * 10
@export_range(0, 1, .01) var aiming_slowdown_ratio: float = 1.0 # Temp Canceling
var facing_direction: int = 1 # Default Facing Direction = RIGHT
@export_subgroup("Jump & Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.2
@export var max_fall_speed: float = 2500.0
@export var forced_fall_velocity: float = 1800.0
@export var jump_velocity: float = -1050.0
@export var double_jump_velocity: float = -800
@export_range(0, 1, .01) var jump_cut_mult: float = 0.33
@export var coyote_time: float = 0.13
@export var jump_buffer_time: float = 0.12
@export var air_resistence_coefficient: float = 1
@export var big_fall_time: float = 0.5 # After Reaching Max Fall velocity
@export_subgroup("Wall slide & jump")
@export_range(0, 1, .01) var wall_slide_coefficient: float = 1.1
@export var wall_slide_initial_velocity: float = 230.0
@export var wall_jump_velocity_x: float = 800.0
@export var wall_slide_max_gravity: float = gravity * 0.3
@export var wall_slide_forced_fall_gravity: float = gravity * 0.55
var is_wall_sliding: bool = false
@export_subgroup("Dash")
@export var is_dashing: bool = true
@export var dash_velocity: float = 2200.0
@export var dash_time: float = 0.13
@export var dash_cooldown_time: float = 0.9
@export var dash_gravity_coefficient: float = 0.0
@export_subgroup("Dodge")
@export var is_dodging: bool = true
@export var dodge_velocity: float = 1500.0
@export var dodge_time: float = 0.06
@export var dodge_cooldown_time: float = 0.5
@export var dodge_gravity_coefficient: float = 2

@export_subgroup("Stunning")
@export var default_stunning_time: float = 0.4
@export var default_stunning_friction: float = speed * 23
@export var dodge_stunning_time: float = 0.18
@export var big_fall_stunning_time: float = 0.6

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
@export var unlocked_dodge: bool = true

#=== Nodes:
@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
# RayCasts:
@onready var left_raycast: RayCast2D = $RayCasts/LeftWall
@onready var right_raycast: RayCast2D = $RayCasts/RightWall
@onready var bottom_slide_stop_raycast: RayCast2D = $RayCasts/BottomSlideStop
@onready var forced_fall_raycast: RayCast2D = $RayCasts/ForcedFall
# Timers:
@onready var coyote_timer: Timer = $Timers/CoyoteTimer
@onready var jump_buffer_timer: Timer = $Timers/JumpBufferTimer
@onready var dash_timer: Timer = $Timers/DashTimer
@onready var dash_cooldown_timer: Timer = $Timers/DashCooldown
@onready var dodge_timer: Timer = $Timers/DodgeTimer
@onready var dodge_cooldown_timer: Timer = $Timers/DodgeCooldown
@onready var stunning_timer: Timer = $Timers/StunningTimer
@onready var big_fall_timer: Timer = $Timers/BigFallTimer

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
@onready var dodge_cooldown_timer_label: Label = $HUD/Debug/DodgeCooldownTimer

var shaking: bool = false

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
	dodge_timer.wait_time = dodge_time
	dodge_cooldown_timer.wait_time = dodge_cooldown_time
	big_fall_timer.wait_time = big_fall_time

func _debug():
	zone_label.text = "Aim Zone: " + joystick.aim_zone_debbug[joystick.current_zone]
	direction_label.text = "Aim Direction: " + joystick.aim_direction_debbug[joystick.aim_direction]
	
	match int(facing_direction):
		-1:
			move_direction_label.text = "Facing Direction: Left"
		1:
			move_direction_label.text = "Facing Direction: Right"
		_:
			move_direction_label.text = "Facing Direction: ?????"
	
	velocity_label.text = "Velocity:     x=%d    y=%d" % [velocity.x, velocity.y]
	coyote_timer_label.text = "Coyote Timer: %.2fs" % coyote_timer.time_left
	buffer_timer_label.text = "Jump Buffer Timer: %.2fs" % jump_buffer_timer.time_left
	dash_cooldown_timer_label.text = "Dash Cooldown: %.2fs" % dash_cooldown_timer.time_left
	dodge_cooldown_timer_label.text = "Dodge Cooldown: %.2fs" % dodge_cooldown_timer.time_left
