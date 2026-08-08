class_name PlayerCamera
extends Camera2D

## PlayerCamera
## ------------------------------------------------------------------
## Lives as a child node inside the Player scene. Basic "follow" is
## free — it moves with its parent through the scene tree. This script
## adds: mobile-default zoom, Forward Offset (look-ahead), and Shake.
##
## See "Camera System.md" §1 for why Forward Offset uses `position`
## (limit-clamped, auto-smoothed) while Shake uses `offset` (not
## limit-clamped, but small/short-lived by design).
## ------------------------------------------------------------------

enum ShakeType { RANDOM, HORIZONTAL, VERTICAL }

@export var player: Player = get_parent() as Player

@export_group("Zoom")
@export var default_zoom: Vector2 = Vector2(0.6, 0.6)

@export_group("Follow / Smoothing")
#@export_range(3.0, 12.0, 0.1) var smoothing_speed: float = 8.0

@export_group("Forward Offset")
@export var forward_offset_distance: float = 50.0

@export_group("Shake Defaults")
@export var default_shake_frequency: float = 30.0

var _facing_direction: int = 0  # 1 = right, -1 = left

var _trauma: float = 0.0
var _trauma_decay_rate: float = 2.0
var _shake_type: ShakeType = ShakeType.RANDOM
var _shake_frequency: float = 30.0
var _shake_seed: float = 0.0

# area instance_id (int) -> Rect2, tracks every CameraArea currently overlapping the player
var _active_limits: Dictionary = {}


func _ready() -> void:
	zoom = default_zoom
	position_smoothing_enabled = true
	#position_smoothing_speed = smoothing_speed
	limit_smoothed = true
	_shake_seed = randf() * 1000.0
	set_facing_direction(player.facing_direction if player != null else 1)
	make_current()
	_connect_signals()

func _connect_signals():
	if not has_node("/root/CameraManager"):
		push_error("PlayerCamera: CameraManager autoload not found yet.")
		return
	CameraManager.change_facing_direction.connect(set_facing_direction)
	CameraManager.camera_area_entered.connect(_on_camera_area_entered)
	CameraManager.camera_area_exited.connect(_on_camera_area_exited)

func _physics_process(delta: float) -> void:
	#if !player.is_on_floor():
		#position_smoothing_enabled = false
	#else :
		#position_smoothing_enabled = true
	_update_trauma(delta)
	offset = _compute_shake_offset()


# ---------------------------------------------------------------
# Forward Offset
# ---------------------------------------------------------------

## Call this whenever the Player's facing direction changes (once per
## flip, not every frame). Updates local `position.x`, which the engine
## smooths AND clamps against the active CameraArea limits automatically.
func set_facing_direction(dir: int) -> void:
	if dir == 0 or dir == _facing_direction:
		return
	_facing_direction = 1 if dir > 0 else -1
	position.x = forward_offset_distance * _facing_direction


# ---------------------------------------------------------------
# Zoom
# ---------------------------------------------------------------

func zoom_to(target_zoom: Vector2, duration: float = 0.3) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "zoom", target_zoom, duration)


func reset_zoom(duration: float = 0.3) -> void:
	zoom_to(default_zoom, duration)


# ---------------------------------------------------------------
# Shake
# ---------------------------------------------------------------

## Full-featured shake.
## - power:     amplitude, roughly 0–10 (10 = strong hit)
## - duration:  seconds. <= 0.0 triggers INSTANT shake instead (a single
##              sharp kick that snaps back almost immediately — good
##              for hits, parries, impacts, no sustained oscillation).
## - frequency: oscillation speed for the continuous (non-instant) case.
## - type:      RANDOM (both axes), HORIZONTAL, or VERTICAL only.
func shake(power: float = 8.0, duration: float = 0.3,
		frequency: float = default_shake_frequency,
		type: ShakeType = ShakeType.RANDOM) -> void:
	if duration <= 0.0:
		_shake_instant(power, type)
		return
	_shake_type = type
	_shake_frequency = frequency
	_trauma = clampf(_trauma + power / 10.0, 0.0, 1.0)
	_trauma_decay_rate = 1.0 / maxf(duration, 0.01)


func _shake_instant(power: float, type: ShakeType) -> void:
	offset = _direction_for_type(type) * power
	var tw := create_tween()
	tw.tween_property(self, "offset", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_EXPO)


func _update_trauma(delta: float) -> void:
	_trauma = maxf(_trauma - _trauma_decay_rate * delta, 0.0)


func _compute_shake_offset() -> Vector2:
	if _trauma <= 0.0:
		return Vector2.ZERO
	var amount: float = _trauma * _trauma  # squared falloff feels punchier than linear
	var t: float = Time.get_ticks_msec() / 1000.0
	var dir := _direction_for_type(_shake_type)
	var noise_x := sin(t * _shake_frequency + _shake_seed)
	var noise_y := sin(t * (_shake_frequency * 0.9) + _shake_seed * 2.0)
	return Vector2(noise_x * dir.x, noise_y * dir.y) * amount * 16.0


func _direction_for_type(type: ShakeType) -> Vector2:
	match type:
		ShakeType.HORIZONTAL:
			return Vector2(1.0, 0.0)
		ShakeType.VERTICAL:
			return Vector2(0.0, 1.0)
		_:
			return Vector2(1.0, 1.0)


# ---------------------------------------------------------------
# CameraArea stacking — "smallest active area wins"
# ---------------------------------------------------------------


func _on_camera_area_entered(area: Area2D, limits: Rect2) -> void:
	_active_limits[area.get_instance_id()] = limits
	_apply_smallest_limit()


func _on_camera_area_exited(area: Area2D) -> void:
	_active_limits.erase(area.get_instance_id())
	_apply_smallest_limit()


func _apply_smallest_limit() -> void:
	if _active_limits.is_empty():
		_reset_limits_to_default()
		return
	var smallest: Rect2
	var smallest_size: float = INF
	for rect in _active_limits.values():
		var size: float = rect.size.x * rect.size.y
		if size < smallest_size:
			smallest_size = size
			smallest = rect
		
	limit_left = int(smallest.position.x)
	limit_top = int(smallest.position.y)
	limit_right = int(smallest.position.x + smallest.size.x)
	limit_bottom = int(smallest.position.y + smallest.size.y)


func _reset_limits_to_default() -> void:
	# Godot's own engine defaults — functionally "no limit"
	limit_left = -10000000
	limit_top = -10000000
	limit_right = 10000000
	limit_bottom = 10000000
