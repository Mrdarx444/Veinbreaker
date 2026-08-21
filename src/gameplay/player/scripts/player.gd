extends CharacterBody2D
class_name Player

@export_category("Settings")
@export_subgroup("Movement")
@export var speed: float = 450.0
var acceleration: float = speed * 10
var friction: float = speed * 10
@export_range(0, 1, .01) var aiming_slowdown_ratio: float = 1.0 # Temp Canceling
var facing_direction: int = 0:
	set(value):
		if facing_direction == value:
			return
		facing_direction = value
		if has_node("/root/CameraManager"):
			CameraManager.set_facing_direction(value)

@export_subgroup("Air Movement")
@export_subgroup("Air Movement/Fall")
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity") * 2.5
@export var max_fall_speed: float = 2200.0
@export var forced_fall_velocity: float = 1700.0
@export_range(0, 1, .01) var forced_fall_transition: float = 0.8
@export var air_hang_threshold: float = 40.0
@export_range(0, 1, .01) var air_hang_coefficient: float = 0.6
@export var big_fall_time: float = 0.3 # After Reaching Max Fall velocity
@export_subgroup("Air Movement/Jump")
@export_range(0, 1, .01) var jump_gravity_coefficient: float = 0.75
@export var jump_velocity: float = -1100.0
@export_range(0, 1, .01) var jump_cut_mult: float = 0.3
@export_range(0, 1, .01) var small_jump_max_time: float = 0.15
@export_range(0, 1, .01) var small_jump_cut_mult: float = 0.01
@export var coyote_time: float = 0.13
@export var jump_buffer_time: float = 0.12
@export var air_resistence_coefficient: float = 1
@export_subgroup("Air Movement/Double Jump")
@export_range(0, 1, .01) var double_jump_velocity_ratio: float = 0.82
var double_jump_velocity: float = jump_velocity * double_jump_velocity_ratio
@export_range(0, 1, .01) var double_jump_cut_mult: float = 0.05
@export_subgroup("Wall Movement")
@export_subgroup("Wall Movement/Wall Slide")
@export_range(0, 2, .01) var wall_slide_coefficient: float = 1.15
@export var wall_slide_initial_velocity: float = 230.0
@export var wall_slide_max_gravity: float = gravity * 0.3
@export var wall_slide_forced_fall_gravity: float = gravity * 0.55
var is_wall_sliding: bool = false
@export_subgroup("Wall Movement/Wall Jump")
@export var wall_jump_velocity_x: float = 720.0 # Update it!
@export_subgroup("Dash")
@export var is_dashing: bool = false
@export var dash_velocity: float = 2200.0
@export var dash_time: float = 0.13
@export var dash_cooldown_time: float = 0.9
@export var dash_gravity_coefficient: float = 0.0
@export_subgroup("Dodge")
var is_dodging: bool = false
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

# Components:
@onready var joystick: PlayerAimComponent = $Components/PlayerAimComponent
@onready var camera: PlayerCamera = %Camera
@onready var path_tracing_particels: CPUParticles2D = $PathTracingParticels
@onready var controllers: Control = $HUD/Controllers
@onready var virtual_joystick_dx: VirtualJoystickDX = $HUD/Controllers/VirtualJoystickDX
@onready var jump_button: PlayerHUDRightButton = $HUD/Controllers/JumpButton
@onready var dash_button: PlayerHUDRightButton = $HUD/Controllers/DashButton

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

func _ready() -> void:
	DebugOverlay.player = self
	set_timers()
	facing_direction = 1

func _physics_process(delta: float) -> void:
	camera.set_grounded(is_on_floor())
	if joystick.move_direction: facing_direction = int(joystick.move_direction)

func set_timers():
	coyote_timer.wait_time = coyote_time
	jump_buffer_timer.wait_time = jump_buffer_time
	dash_timer.wait_time = dash_time
	dash_cooldown_timer.wait_time = dash_cooldown_time
	dodge_timer.wait_time = dodge_time
	dodge_cooldown_timer.wait_time = dodge_cooldown_time
	big_fall_timer.wait_time = big_fall_time
