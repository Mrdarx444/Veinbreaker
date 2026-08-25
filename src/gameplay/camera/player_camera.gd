class_name PlayerCamera
extends Camera2D

## PlayerCamera V6
## ------------------------------------------------------------
## Camera2D مستقل داخل Level.
## لا يعتمد على Camera2D position smoothing.
## يقوم بالتتبع يدويًا مع smoothing مستقل لـ X و Y.
## Default Limits يتم حفظها عند _ready() قبل أي CameraArea override.
## CameraArea تعمل كـ temporary override فوق الـDefault Limits.
## ------------------------------------------------------------

signal limits_changed(previous: Rect2, current: Rect2)
signal focus_started(target_position: Vector2)
signal focus_finished()


enum ShakeType {
	RANDOM,
	HORIZONTAL,
	VERTICAL,
}


# ============================================================
# Target
# ============================================================

@export_group("Target")
@export var target: Node2D


# ============================================================
# Follow
# ============================================================

@export_group("Follow")
@export_range(0.1, 30.0, 0.1)
var follow_smoothing_speed_x: float = 7.0

@export_range(0.1, 30.0, 0.1)
var follow_smoothing_speed_y: float = 15.0

@export var follow_enabled: bool = true


# ============================================================
# Forward Look
# ============================================================

@export_group("Forward Look")
@export var forward_offset_distance: float = 80.0

@export_range(0.1, 30.0, 0.1)
var forward_offset_speed: float = 5.0

@export var forward_offset_enabled: bool = true


# ============================================================
# Vertical Look
# ============================================================

@export_group("Vertical Look")
@export var vertical_look_offset: float = 300.0

@export_range(0.1, 30.0, 0.1)
var vertical_look_speed: float = 7.0

@export var vertical_look_enabled: bool = true
@export var vertical_look_input_time: float = 1.1
var is_looking_vertical: bool = false

# ============================================================
# Ledge Look
# ============================================================

@export_group("Ledge Look")
@export var ledge_offset: float = 120.0

@export_range(0.1, 30.0, 0.1)
var ledge_offset_speed: float = 4.0

@export var ledge_look_enabled: bool = true

@export var ledge_look_delay: float = 0.5

# ============================================================
# Zoom
# ============================================================

@export_group("Zoom")
@export var default_zoom: Vector2 = GameConstants.CAMERA_DEFAULT_ZOOMS.mobile if OS.has_feature("mobile") else GameConstants.CAMERA_DEFAULT_ZOOMS.pc


# ============================================================
# Limits
# ============================================================

@export_group("Limits")
@export_range(0.1, 20.0, 0.1)
var limit_transition_speed: float = 4.0

@export var limit_transition_enabled: bool = true


# ============================================================
# Shake
# ============================================================

@export_group("Shake")
@export var default_shake_frequency: float = 30.0


# ============================================================
# Runtime target values
# ============================================================

var _current_position: Vector2
var _current_forward_offset: float = 0.0
var _target_forward_offset: float = 0.0
var _current_vertical_offset: float = 0.0
var _target_vertical_offset: float = 0.0
var _current_ledge_offset: float = 0.0
var _target_ledge_offset: float = 0.0

var _facing_direction: int = 1
var _is_grounded: bool = true
var _is_falling: bool = false


# ============================================================
# Default Limits
# ============================================================

var _default_limits: Rect2
var _has_default_limits: bool = false


# ============================================================
# Camera Area Overrides
# ============================================================

## area_instance_id -> {
##     "rect": Rect2,
##     "priority": int,
##     "duration": float,
## }
var _active_areas: Dictionary = {}

var _current_area_limits: Rect2
var _has_current_area_limits: bool = false

var _limit_tween: Tween
var _limit_transition_from: Rect2
var _limit_transition_to: Rect2
var _limit_transition_progress: float = 1.0


# ============================================================
# Focus
# ============================================================

var _is_focusing: bool = false
var _focus_tween: Tween


# ============================================================
# Shake
# ============================================================

var _trauma: float = 0.0
var _trauma_decay_rate: float = 0.0
var _shake_power: float = 0.0
var _shake_type: ShakeType = ShakeType.RANDOM
var _shake_frequency: float = 30.0
var _shake_seed: float = 0.0


# ============================================================
# Ready
# ============================================================

func _ready() -> void:
	if target == null:
		push_error("PlayerCamera: target is not assigned.")
		return
		
	global_position = target.global_position
	
	position_smoothing_enabled = false

	zoom = default_zoom
	_current_position = global_position
	_shake_seed = randf() * 1000.0

	_cache_default_limits()

	_connect_to_camera_manager()
	make_current()


# ============================================================
# Default Limits Cache
# ============================================================

func _cache_default_limits() -> void:
	_default_limits = Rect2(
		Vector2(limit_left, limit_top),
		Vector2(
			limit_right - limit_left,
			limit_bottom - limit_top
		)
	)

	_has_default_limits = true

	_current_area_limits = _default_limits
	_has_current_area_limits = true


# ============================================================
# Main Update
# ============================================================

func _physics_process(delta: float) -> void:
	if not is_instance_valid(target):
		return

	_update_shake(delta)

	if _is_focusing:
		offset = _compute_shake_offset()
		return

	_update_forward_offset(delta)
	_update_vertical_offset(delta)
	_update_ledge_offset(delta)

	if not follow_enabled:
		offset = _compute_shake_offset()
		return

	var desired_position := _compute_target_position()

	_current_position = _smooth_follow(
		_current_position,
		desired_position,
		delta
	)

	_current_position = _clamp_position_to_limits(_current_position)

	global_position = _current_position

	offset = _compute_shake_offset()
	

# ============================================================
# Target Position
# ============================================================

func _compute_target_position() -> Vector2:
	var position := target.global_position

	position.x += _current_forward_offset
	position.y += _current_vertical_offset
	position.y += _current_ledge_offset

	return position


# ============================================================
# Manual Axis Smoothing
# ============================================================

func _smooth_follow(
	current: Vector2,
	desired: Vector2,
	delta: float
) -> Vector2:
	var x_weight := 1.0 - exp(-follow_smoothing_speed_x * delta)
	var y_weight := 1.0 - exp(-follow_smoothing_speed_y * delta)

	return Vector2(
		lerpf(current.x, desired.x, x_weight),
		lerpf(current.y, desired.y, y_weight)
	)


# ============================================================
# Forward Offset
# ============================================================

func set_facing_direction(direction: int) -> void:
	if direction == 0:
		return

	_facing_direction = 1 if direction > 0 else -1
	_recompute_forward_target()


func set_forward_offset_enabled(enabled: bool) -> void:
	forward_offset_enabled = enabled
	_recompute_forward_target()


func _recompute_forward_target() -> void:
	if not forward_offset_enabled:
		_target_forward_offset = 0.0
		return

	_target_forward_offset = forward_offset_distance * _facing_direction


func _update_forward_offset(delta: float) -> void:
	var weight := 1.0 - exp(-forward_offset_speed * delta)

	_current_forward_offset = lerpf(
		_current_forward_offset,
		_target_forward_offset,
		weight
	)


# ============================================================
# Vertical Look
# ============================================================

func set_vertical_look_offset(offset_value: float) -> void:
	if not vertical_look_enabled:
		_target_vertical_offset = 0.0
		return
	
	is_looking_vertical = bool(offset_value)
	
	_target_vertical_offset = clamp(
		offset_value,
		-vertical_look_offset,
		vertical_look_offset
	)


func clear_vertical_look() -> void:
	_target_vertical_offset = 0.0


func _update_vertical_offset(delta: float) -> void:
	var weight := 1.0 - exp(-vertical_look_speed * delta)

	_current_vertical_offset = lerpf(
		_current_vertical_offset,
		_target_vertical_offset,
		weight
	)


# ============================================================
# Ledge Offset
# ============================================================

func set_ledge_detected(detected: bool) -> void:
	if not ledge_look_enabled or is_looking_vertical:
		_target_ledge_offset = 0.0
		return

	_target_ledge_offset = ledge_offset if detected else 0.0


func _update_ledge_offset(delta: float) -> void:
	var weight := 1.0 - exp(-ledge_offset_speed * delta)

	_current_ledge_offset = lerpf(
		_current_ledge_offset,
		_target_ledge_offset,
		weight
	)


# ============================================================
# Player State Inputs
# ============================================================

func set_grounded(value: bool) -> void:
	_is_grounded = value


func set_falling(value: bool) -> void:
	_is_falling = value


# ============================================================
# Limit Clamp
# ============================================================

func _clamp_position_to_limits(position: Vector2) -> Vector2:
	if not _has_default_limits and not _has_current_area_limits:
		return position

	var rect := _get_active_limit_rect()
	var half_view := _get_half_view_size()

	var min_x := rect.position.x + half_view.x
	var max_x := rect.end.x - half_view.x

	var min_y := rect.position.y + half_view.y
	var max_y := rect.end.y - half_view.y

	var result := position

	if min_x <= max_x:
		result.x = clamp(result.x, min_x, max_x)
	else:
		result.x = rect.get_center().x

	if min_y <= max_y:
		result.y = clamp(result.y, min_y, max_y)
	else:
		result.y = rect.get_center().y

	return result


func _get_half_view_size() -> Vector2:
	var viewport_size := get_viewport_rect().size

	return Vector2(
		viewport_size.x / (2.0 * zoom.x),
		viewport_size.y / (2.0 * zoom.y)
	)


# ============================================================
# Camera Area System
# ============================================================

func register_camera_area(
	area: CameraArea,
	limits: Rect2,
	transition_duration: float,
	priority: int
) -> void:
	if area == null:
		return

	_active_areas[area.get_instance_id()] = {
		"rect": limits,
		"duration": transition_duration,
		"priority": priority,
	}

	_resolve_active_area()


func unregister_camera_area(area: CameraArea) -> void:
	if area == null:
		return

	var area_id := area.get_instance_id()

	if not _active_areas.has(area_id):
		return

	# IMPORTANT:
	# Save the duration of the area BEFORE removing it.
	#
	# If this was the last active area, this exact duration
	# will be used for the transition back to Default Limits.
	var exiting_area: Dictionary = _active_areas[area_id]

	_active_areas.erase(area_id)

	if _active_areas.is_empty():
		_apply_limit_rect(
			_default_limits,
			exiting_area["duration"]
		)
		return

	_resolve_active_area()


func _resolve_active_area() -> void:
	if _active_areas.is_empty():
		_apply_limit_rect(_default_limits, 0.0)
		return

	var selected: Dictionary = _select_active_area()

	_apply_limit_rect(
		selected["rect"],
		selected["duration"]
	)


func _select_active_area() -> Dictionary:
	var highest_priority: int = -1
	var selected: Dictionary = {}

	# Priority always wins if one or more areas explicitly define it.
	for entry in _active_areas.values():
		var priority: int = entry["priority"]

		if priority >= 0 and priority > highest_priority:
			highest_priority = priority
			selected = entry

	if not selected.is_empty():
		return selected

	# Otherwise the smallest active area wins.
	var smallest_area: float = INF

	for entry in _active_areas.values():
		var rect: Rect2 = entry["rect"]
		var area_size := rect.size.x * rect.size.y

		if area_size < smallest_area:
			smallest_area = area_size
			selected = entry

	return selected


# ============================================================
# Limit Transition
# ============================================================

func _apply_limit_rect(
	rect: Rect2,
	duration: float
) -> void:

	var previous := _get_active_limit_rect()

	if _limit_tween and _limit_tween.is_valid():
		_limit_tween.kill()

	# Already at this Rect.
	if previous.is_equal_approx(rect):
		_current_area_limits = rect
		_has_current_area_limits = true
		_set_engine_limits(rect)
		return

	# Instant transition.
	if duration <= 0.0 or not limit_transition_enabled:
		_current_area_limits = rect
		_has_current_area_limits = true
		_limit_transition_progress = 1.0

		_set_engine_limits(rect)

		_current_position = _clamp_position_to_limits(
			_current_position
		)

		global_position = _current_position

		limits_changed.emit(previous, rect)
		return

	# --------------------------------------------------------
	# IMPORTANT:
	# The duration comes from the CameraArea involved in the
	# transition.
	#
	# Enter:
	#     duration = entered area's duration
	#
	# Exit to default:
	#     duration = exited area's duration
	# --------------------------------------------------------

	_limit_transition_from = previous
	_limit_transition_to = rect
	_limit_transition_progress = 0.0

	_has_current_area_limits = true

	_limit_tween = create_tween()
	_limit_tween.set_trans(Tween.TRANS_SINE)
	_limit_tween.set_ease(Tween.EASE_IN_OUT)

	_limit_tween.tween_method(
		_set_limit_transition_progress,
		0.0,
		1.0,
		duration
	)

	limits_changed.emit(previous, rect)


func _set_limit_transition_progress(value: float) -> void:
	_limit_transition_progress = clampf(
		value,
		0.0,
		1.0
	)

	var rect := Rect2(
		_limit_transition_from.position.lerp(
			_limit_transition_to.position,
			_limit_transition_progress
		),
		_limit_transition_from.size.lerp(
			_limit_transition_to.size,
			_limit_transition_progress
		)
	)

	_current_area_limits = rect

	# Keep the Camera2D engine limits synchronized with
	# the interpolated Rect.
	_set_engine_limits(rect)

	# IMPORTANT:
	# Manual camera follow must also obey the interpolated limits.
	# This is what was missing from the previous implementation.
	_current_position = _clamp_position_to_limits(
		_current_position
	)

	global_position = _current_position


func _set_engine_limits(rect: Rect2) -> void:
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.end.x)
	limit_bottom = int(rect.end.y)


func _get_active_limit_rect() -> Rect2:
	if _has_current_area_limits:
		return _current_area_limits

	return _default_limits


# ============================================================
# Focus
# ============================================================

func focus_on(
	focus_position: Vector2,
	transition_duration: float = 0.6,
	hold_duration: float = 1.0
) -> void:

	if _focus_tween and _focus_tween.is_valid():
		_focus_tween.kill()

	_is_focusing = true
	focus_started.emit(focus_position)

	_focus_tween = create_tween()
	_focus_tween.set_trans(Tween.TRANS_SINE)
	_focus_tween.set_ease(Tween.EASE_IN_OUT)

	_focus_tween.tween_property(
		self,
		"global_position",
		focus_position,
		transition_duration
	)

	await _focus_tween.finished

	await get_tree().create_timer(
		hold_duration
	).timeout

	if not is_instance_valid(target):
		_is_focusing = false
		focus_finished.emit()
		return

	var return_position := _clamp_position_to_limits(
		target.global_position
	)

	_focus_tween = create_tween()
	_focus_tween.set_trans(Tween.TRANS_SINE)
	_focus_tween.set_ease(Tween.EASE_IN_OUT)

	_focus_tween.tween_property(
		self,
		"global_position",
		return_position,
		transition_duration
	)

	await _focus_tween.finished

	_current_position = global_position
	_is_focusing = false

	focus_finished.emit()


# ============================================================
# Zoom
# ============================================================

func zoom_to(
	target_zoom: Vector2,
	duration: float = 0.3
) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	#tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"zoom",
		target_zoom,
		duration
	)


func reset_zoom(duration: float = 0.3) -> void:
	zoom_to(default_zoom, duration)


func dash_zoom_pulse(
	zoom_multiplier: float = 1.05,
	duration: float = 0.5
) -> void:

	var pulse := default_zoom * zoom_multiplier

	var tween := create_tween()

	tween.set_trans(Tween.TRANS_SINE)

	tween.tween_property(
		self,
		"zoom",
		pulse,
		duration * 0.4
	)

	tween.tween_property(
		self,
		"zoom",
		default_zoom,
		duration * 0.6
	)


# ============================================================
# Shake
# ============================================================

func shake(
	power: float = 8.0,
	duration: float = 0.3,
	frequency: float = 30.0,
	type: ShakeType = ShakeType.RANDOM
) -> void:

	if duration <= 0.0:
		_trauma = 1.0
		_shake_power = power
		_shake_type = type
		_shake_frequency = frequency
		return

	_shake_type = type
	_shake_frequency = frequency
	_shake_power = maxf(_shake_power, power)
	_trauma = 1.0
	_trauma_decay_rate = 1.0 / maxf(duration, 0.01)


func shake_preset(
	preset: GameConstants.ShakePreset
) -> void:

	if !GameConstants.SHAKE_PRESETS.has(preset):
		push_warning("'%s': didn't find the shake preset.")
		return

	var shake_preset: Dictionary = GameConstants.SHAKE_PRESETS.get(
		preset
	)

	shake(
		shake_preset["power"],
		shake_preset["duration"],
		shake_preset["frequency"],
		shake_preset["type"]
	)


func _update_shake(delta: float) -> void:
	_trauma = maxf(
		_trauma - _trauma_decay_rate * delta,
		0.0
	)

	if _trauma <= 0.0:
		_shake_power = 0.0


func _compute_shake_offset() -> Vector2:
	if _trauma <= 0.0:
		return Vector2.ZERO

	var envelope := _trauma * _trauma
	var time := Time.get_ticks_msec() / 1000.0

	var direction := _direction_for_shake(
		_shake_type
	)

	var noise_x := sin(
		time * _shake_frequency + _shake_seed
	)

	var noise_y := sin(
		time * (_shake_frequency * 0.9)
		+ _shake_seed * 2.0
	)

	return Vector2(
		noise_x * direction.x,
		noise_y * direction.y
	) * envelope * _shake_power


func _direction_for_shake(
	type: ShakeType
) -> Vector2:

	match type:
		ShakeType.HORIZONTAL:
			return Vector2.RIGHT

		ShakeType.VERTICAL:
			return Vector2.DOWN

		_:
			return Vector2.ONE


# ============================================================
# CameraManager Connection
# ============================================================

func _connect_to_camera_manager() -> void:
	if not has_node("/root/CameraManager"):
		push_warning(
			"PlayerCamera: CameraManager autoload not found."
		)
		return

	CameraManager.change_facing_direction.connect(
		set_facing_direction
	)

	CameraManager.camera_shake.connect(
		shake
	)

	CameraManager.camera_shake_preset.connect(
		shake_preset
	)

	CameraManager.camera_area_entered.connect(
		_on_manager_area_entered
	)

	CameraManager.camera_area_exited.connect(
		_on_manager_area_exited
	)


func _on_manager_area_entered(
	area: CameraArea,
	limits: Rect2,
	transition_duration: float,
	priority: int
) -> void:

	register_camera_area(
		area,
		limits,
		transition_duration,
		priority
	)


func _on_manager_area_exited(
	area: CameraArea
) -> void:

	unregister_camera_area(area)
