extends CanvasLayer

signal player_state_changed(from: StringName, to: StringName)
const VERSION_SETTING = "application/config/version"

@export var show_player_state_changes: bool = false

var player: Player = null

@onready var debug_control: Control = $Debug
@onready var state_label: Label = $Debug/StateLabel
@onready var zone_label: Label = $Debug/ZoneLabel
@onready var direction_label: Label = $Debug/DirectionLabel
@onready var velocity_label: Label = $Debug/VelocityLabel
@onready var dash_cooldown_timer_label: Label = $Debug/DashCooldownTimerLabel
@onready var dodge_cooldown_timer_label: Label = $Debug/DodgeCooldownTimerLabel

@onready var version_label: Label = $Debug/VersionLabel
@onready var fps_label: Label = $Debug/FPSLabel

func _ready() -> void:
	player_state_changed.connect(_on_state_changed)
	version_label.text = "Version: " + str(ProjectSettings.get_setting(VERSION_SETTING))
	print("Platform: %s"%OS.get_name())

func _process(delta: float) -> void:
	if player == null: return
	if GameManager.debug_mode:
		debug_control.visible = true
		_update_debug()
	else :
		debug_control.visible = false
	
	
	if GameManager.debug_mode:
		player.path_tracing_particels.emitting = true
		player.path_tracing_particels.show()
	else :
		player.path_tracing_particels.emitting = false
		player.path_tracing_particels.restart()
		player.path_tracing_particels.hide()
		
	# NOTE: Will be transported to Platform Manager Code
	if !OS.has_feature("mobile"):
		player.virtual_joystick_dx.visible = false
		player.controllers.hide()
	else :
		player.virtual_joystick_dx.visible = true
		player.controllers.show()

func _update_debug():
	zone_label.text = "Aim Zone: " + player.joystick.aim_zone_debbug[player.joystick.current_zone]
	direction_label.text = "Aim Direction: " + player.joystick.aim_direction_debbug[player.joystick.aim_direction]
	
	velocity_label.text = "Velocity:     x=%d    y=%d" % [player.velocity.x, player.velocity.y]
	dash_cooldown_timer_label.text = "Dash Cooldown: %.2fs" % player.dash_cooldown_timer.time_left
	dodge_cooldown_timer_label.text = "Dodge Cooldown: %.2fs" % player.dodge_cooldown_timer.time_left
	fps_label.text = "FPS: " + str(int(Engine.get_frames_per_second()))

func _on_state_changed(from: StringName, to: StringName):
	if !GameManager.debug_mode:
		return
	if show_player_state_changes: 
		print("'%s': Player Changed State from '%s' to '%s'"%[name, from, to])
	state_label.set_deferred("text", "State: " + str(to))
