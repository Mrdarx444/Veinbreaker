class_name PlayerCamera
extends Camera2D

## PlayerCamera (v4)
## ------------------------------------------------------------------
## Child of the Player scene. Every physics frame computes ONE target
## position and assigns it to global_position once (X = follow + own-
## smoothing forward offset, Y = normal follow OR vertical-locked +
## fall-lookahead while airborne). Engine smoothing + limit_* clamp
## the result automatically, except during focus_on() where a Tween
## takes exclusive control. Shake stays on `offset` (still not limit-
## clamped by the engine — unchanged trade-off, still deliberate).
##
## v4 changes (see "Camera System 4.md" §0 for full diagnosis):
## - REMOVED `_locked_y = _player.global_position.y` again — it was
##   still defeating Vertical Lock. set_falling() was already wired
##   correctly via your Fall state; that was never the bug.
## - CameraArea limits apply INSTANTLY by default (not tweened). This
##   is closer to how Hollow Knight-style trigger-zone cameras work,
##   and it fully eliminates the "reveals full screen" bug instead of
##   patching around it. Per-area tweening is opt-in via
##   CameraArea.transition_duration for special rooms.
## - Added priority_override support, read from the signal payload.
## ------------------------------------------------------------------

enum ShakeType { RANDOM, HORIZONTAL, VERTICAL }

@export_group("Zoom")
@export var default_zoom: Vector2 = Vector2(0.6, 0.6)

@export_group("Follow / Smoothing")
@export_range(2.0, 12.0, 0.1) var follow_smoothing_speed: float = 8.0

@export_group("Forward Offset")
@export var forward_offset_distance: float = 70.0
@export var forward_offset_smoothing_speed: float = 4.5

@export_group("Vertical Behavior")
@export var vertical_lock_enabled: bool = true
@export var fall_lookahead_distance: float = 200.0
@export var fall_lookahead_smoothing_speed: float = 4.0

@export_group("Shake Defaults")
@export var default_shake_frequency: float = 30.0

var _player: Player = null

var _facing_direction: int = 1
var _forward_offset_enabled: bool = true
var _target_forward_offset: float = 0.0
var _current_forward_offset: float = 0.0

var _is_grounded: bool = true
var _is_falling: bool = false
var _locked_y: float = 0.0
var _current_fall_lookahead: float = 0.0

var _is_focusing: bool = false

var _trauma: float = 0.0
var _trauma_decay_rate: float = 2.0
var _shake_power: float = 0.0
var _shake_type: ShakeType = ShakeType.RANDOM
var _shake_frequency: float = 30.0
var _shake_seed: float = 0.0

# area.instance_id -> {"rect": Rect2, "duration": float, "priority": int}
var _active_limits: Dictionary = {}
var _limit_tween: Tween = null


func _ready() -> void:
	_player = get_parent() as Player
	if _player == null:
		push_error("PlayerCamera: must be a direct child of a Player node. Reparent it.")

	zoom = default_zoom
	position_smoothing_enabled = true
	position_smoothing_speed = follow_smoothing_speed
	limit_smoothed = true
	_shake_seed = randf() * 1000.0
	_locked_y = global_position.y
	make_current()
	_connect_to_camera_manager()


func _connect_to_camera_manager() -> void:
	if not has_node("/root/CameraManager"):
		push_warning("PlayerCamera: CameraManager autoload not found yet.")
		return
	CameraManager.change_facing_direction.connect(set_facing_direction)
	CameraManager.camera_shake.connect(shake)
	CameraManager.camera_shake_preset.connect(shake_preset)
	CameraManager.camera_area_entered.connect(_on_camera_area_entered)
	CameraManager.camera_area_exited.connect(_on_camera_area_exited)


func _physics_process(delta: float) -> void:
	if not is_instance_valid(_player):
		return

	_update_trauma(delta)
	offset = _compute_shake_offset()

	if _is_focusing:
		return  # a Tween owns global_position exclusively during focus_on()

	_update_forward_offset(delta)
	_update_vertical_behavior(delta)

	var target_x: float = _player.global_position.x + _current_forward_offset
	var target_y: float = _compute_target_y()
	global_position = Vector2(target_x, target_y)
	# Deliberately nothing else here — see header note on why the
	# per-frame `_locked_y = ...` line was removed.


# ---------------------------------------------------------------
# Forward Offset
# ---------------------------------------------------------------

func set_facing_direction(dir: int) -> void:
	if dir == 0:
		return
	_facing_direction = 1 if dir > 0 else -1
	_recompute_forward_offset_target()


func set_forward_offset_enabled(enabled: bool) -> void:
	_forward_offset_enabled = enabled
	_recompute_forward_offset_target()


func _recompute_forward_offset_target() -> void:
	_target_forward_offset = (forward_offset_distance * _facing_direction) if _forward_offset_enabled else 0.0


func _update_forward_offset(delta: float) -> void:
	_current_forward_offset = lerpf(
		_current_forward_offset, _target_forward_offset, forward_offset_smoothing_speed * delta
	)


# ---------------------------------------------------------------
# Vertical Behavior
# ---------------------------------------------------------------

func set_grounded(grounded: bool) -> void:
	if grounded == _is_grounded:
		return
	_is_grounded = grounded
	if not grounded:
		_locked_y = global_position.y


func set_falling(falling: bool) -> void:
	if falling == _is_falling:
		return
	_is_falling = falling
	set_forward_offset_enabled(not falling)


func _update_vertical_behavior(delta: float) -> void:
	var target_lookahead: float = fall_lookahead_distance if (_is_falling and not _is_grounded) else 0.0
	_current_fall_lookahead = lerpf(
		_current_fall_lookahead, target_lookahead, fall_lookahead_smoothing_speed * delta
	)


func _compute_target_y() -> float:
	if _is_grounded or not vertical_lock_enabled:
		return _player.global_position.y
	return _locked_y + _current_fall_lookahead


# ---------------------------------------------------------------
# Focus (cinematic — boss intros, cutscene beats)
# ---------------------------------------------------------------

func focus_on(target_position: Vector2, transition_duration: float = 0.6, hold_duration: float = 1.0) -> void:
	_is_focusing = true
	position_smoothing_enabled = false

	var in_tween := create_tween()
	in_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	in_tween.tween_property(self, "global_position", target_position, transition_duration)
	await in_tween.finished

	await get_tree().create_timer(hold_duration).timeout

	var return_position: Vector2 = _player.global_position if is_instance_valid(_player) else global_position
	var out_tween := create_tween()
	out_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	out_tween.tween_property(self, "global_position", return_position, transition_duration)
	await out_tween.finished

	position_smoothing_enabled = true
	_is_focusing = false


# ---------------------------------------------------------------
# Zoom
# ---------------------------------------------------------------

func zoom_to(target_zoom: Vector2, duration: float = 0.3) -> void:
	var tw := create_tween()
	tw.set_trans(Tween.TRANS_SINE)
	tw.tween_property(self, "zoom", target_zoom, duration)


func reset_zoom(duration: float = 0.3) -> void:
	zoom_to(default_zoom, duration)


func dash_zoom_pulse(zoom_multiplier: float = 1.05, duration: float = 0.5) -> void:
	var pulse_zoom: Vector2 = default_zoom * zoom_multiplier
	var tw := create_tween()
	tw.tween_property(self, "zoom", pulse_zoom, duration * 0.4)
	tw.tween_property(self, "zoom", default_zoom, duration * 0.6)


# ---------------------------------------------------------------
# Shake
# ---------------------------------------------------------------

func shake(power: float = 8.0, duration: float = 0.3,
		frequency: float = default_shake_frequency,
		type: ShakeType = ShakeType.RANDOM) -> void:
	if duration <= 0.0:
		_shake_instant(power, type)
		return
	_shake_type = type
	_shake_frequency = frequency
	_shake_power = maxf(_shake_power, power)
	_trauma = 1.0
	_trauma_decay_rate = 1.0 / maxf(duration, 0.01)


func shake_preset(preset: GameConstants.ShakePreset) -> void:
	if not GameConstants.SHAKE_PRESETS.has(preset):
		push_warning("PlayerCamera: unknown shake preset '%s'" % preset)
		return
	var p: Dictionary = GameConstants.SHAKE_PRESETS[preset]
	shake(p["power"], p["duration"], p["frequency"], p["type"])


func _shake_instant(power: float, type: ShakeType) -> void:
	offset = _direction_for_type(type) * power
	var tw := create_tween()
	tw.tween_property(self, "offset", Vector2.ZERO, 0.08).set_trans(Tween.TRANS_EXPO)


func _update_trauma(delta: float) -> void:
	_trauma = maxf(_trauma - _trauma_decay_rate * delta, 0.0)
	if _trauma <= 0.0:
		_shake_power = 0.0


func _compute_shake_offset() -> Vector2:
	if _trauma <= 0.0:
		return Vector2.ZERO
	var envelope: float = _trauma * _trauma
	var t: float = Time.get_ticks_msec() / 1000.0
	var dir := _direction_for_type(_shake_type)
	var noise_x := sin(t * _shake_frequency + _shake_seed)
	var noise_y := sin(t * (_shake_frequency * 0.9) + _shake_seed * 2.0)
	return Vector2(noise_x * dir.x, noise_y * dir.y) * envelope * _shake_power


func _direction_for_type(type: ShakeType) -> Vector2:
	match type:
		ShakeType.HORIZONTAL:
			return Vector2(1.0, 0.0)
		ShakeType.VERTICAL:
			return Vector2(0.0, 1.0)
		_:
			return Vector2(1.0, 1.0)


# ---------------------------------------------------------------
# CameraArea stacking — priority override, else smallest wins;
# limits apply instantly unless the winning area asks for a tween.
# ---------------------------------------------------------------

func _on_camera_area_entered(area: CameraArea, limits: Rect2, transition_duration: float) -> void:
	_active_limits[area.get_instance_id()] = {
		"rect": limits,
		"duration": transition_duration,
		"priority": area.priority_override,
	}
	_apply_active_limit()


func _on_camera_area_exited(area: CameraArea) -> void:
	_active_limits.erase(area.get_instance_id())
	_apply_active_limit()


func _apply_active_limit() -> void:
	if _active_limits.is_empty():
		_apply_limit(Rect2(Vector2(-10000000, -10000000), Vector2(20000000, 20000000)), 0.0)
		return

	var best_priority: int = -1
	var priority_entry: Dictionary = {}
	for entry in _active_limits.values():
		if entry["priority"] > best_priority:
			best_priority = entry["priority"]
			priority_entry = entry

	if best_priority >= 0:
		_apply_limit(priority_entry["rect"], priority_entry["duration"])
		return

	var smallest_entry: Dictionary = {}
	var smallest_size: float = INF
	for entry in _active_limits.values():
		var rect: Rect2 = entry["rect"]
		var size: float = rect.size.x * rect.size.y
		if size < smallest_size:
			smallest_size = size
			smallest_entry = entry

	_apply_limit(smallest_entry["rect"], smallest_entry["duration"])


## duration <= 0.0 (the default) snaps instantly — see doc §0 for why
## this replaced the always-tweened v3 behavior. duration > 0.0 still
## tweens, for a room that wants a deliberate slow reveal.
func _apply_limit(rect: Rect2, duration: float) -> void:
	if _limit_tween and _limit_tween.is_valid():
		_limit_tween.kill()

	if duration <= 0.0:
		limit_left = int(rect.position.x)
		limit_top = int(rect.position.y)
		limit_right = int(rect.position.x + rect.size.x)
		limit_bottom = int(rect.position.y + rect.size.y)
		return

	_limit_tween = create_tween()
	_limit_tween.set_parallel(true)
	_limit_tween.tween_property(self, "limit_left", int(rect.position.x), duration)
	_limit_tween.tween_property(self, "limit_top", int(rect.position.y), duration)
	_limit_tween.tween_property(self, "limit_right", int(rect.position.x + rect.size.x), duration)
	_limit_tween.tween_property(self, "limit_bottom", int(rect.position.y + rect.size.y), duration)
