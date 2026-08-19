class_name CameraArea
extends Area2D

## CameraArea (v5)
## ------------------------------------------------------------------
## THREE optional shapes, all WYSIWYG (draggable in the 2D viewport):
##   - "EntranceShape": ENABLED CollisionShape2D. Fires camera_area_entered.
##     Keep it INSET (smaller) than the room.
##   - "ExitShape": ENABLED CollisionShape2D, larger than EntranceShape.
##     Fires camera_area_exited only once the player is well clear.
##   - "LimitsShape": DISABLED CollisionShape2D — the actual camera
##     bound. Disabled shapes stay visible/draggable in the editor.
##
## Fallback chain if some are missing: LimitsShape -> EntranceShape ->
## any CollisionShape2D found.
##
## `transition_duration`:
##     مدة انتقال الكاميرا عند الدخول إلى هذه المنطقة.
##     ونفس المدة تستخدم عند الخروج منها والعودة إلى Default Limits.
##
## `priority_override`:
##     -1 = unset.
##     إذا كانت >= 0 فإن أعلى Priority تفوز.
## ------------------------------------------------------------------

#TEMP
signal camera_area_entered

@export var active: bool = true
@export var transition_duration: float = 0.0
@export var priority_override: int = -1

var _cached_limits: Rect2
var _has_valid_limits: bool = false
var _entrance_shape: CollisionShape2D
var _exit_shape: CollisionShape2D


func _ready() -> void:
	if not active:
		return

	_resolve_shapes()

	body_shape_entered.connect(
		_on_body_shape_entered
	)

	body_shape_exited.connect(
		_on_body_shape_exited
	)

	await get_tree().physics_frame

	_check_initial_overlap()


func _resolve_shapes() -> void:
	_entrance_shape = get_node_or_null(
		"EntranceShape"
	) as CollisionShape2D

	if _entrance_shape == null:
		push_warning(
			"'%s': has no 'EntranceShape' collision."
			% name
		)

		_entrance_shape = _find_any_collision_shape()


	_exit_shape = get_node_or_null(
		"ExitShape"
	) as CollisionShape2D

	if _exit_shape == null:
		push_warning(
			"'%s': has no 'ExitShape' collision."
			% name
		)

		_exit_shape = _entrance_shape


	var limits_shape: CollisionShape2D = get_node_or_null(
		"LimitsShape"
	) as CollisionShape2D

	if limits_shape == null:
		push_warning(
			"'%s': has no 'LimitsShape' collision."
			% name
		)

		limits_shape = _entrance_shape

		# Do NOT disable this shape.
		# It may also be the EntranceShape.


	_cache_limits_from_shape(
		limits_shape
	)


func _cache_limits_from_shape(
	shape_node: CollisionShape2D
) -> void:

	if shape_node == null or shape_node.shape == null:
		push_error(
			"CameraArea '%s': needs at least one "
			+ "CollisionShape2D with a RectangleShape2D."
			% name
		)
		return

	var rect_shape := shape_node.shape as RectangleShape2D

	if rect_shape == null:
		push_error(
			"CameraArea '%s': the limits shape must "
			+ "be a RectangleShape2D."
			% name
		)
		return

	var half_size: Vector2 = rect_shape.size / 2.0
	var world_center: Vector2 = shape_node.global_position

	_cached_limits = Rect2(
		world_center - half_size,
		rect_shape.size
	)

	_has_valid_limits = true


func _find_any_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child

	return null


func _check_initial_overlap() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body is Player:
			_enter_area()
			return


func _on_body_shape_entered(
	_body_rid: RID,
	body: Node2D,
	_body_shape_index: int,
	local_shape_index: int
) -> void:

	if not active or not _has_valid_limits:
		return

	if shape_owner_get_owner(
		shape_find_owner(local_shape_index)
	) != _entrance_shape:
		return

	if not (
		body.is_in_group("player")
		and body is Player
	):
		return

	_enter_area()


func _on_body_shape_exited(
	_body_rid: RID,
	body: Node2D,
	_body_shape_index: int,
	local_shape_index: int
) -> void:

	if not active or not _has_valid_limits:
		return

	if shape_owner_get_owner(
		shape_find_owner(local_shape_index)
	) != _exit_shape:
		return

	if not (
		body.is_in_group("player")
		and body is Player
	):
		return

	_exit_area()


func _enter_area() -> void:
	camera_area_entered.emit()
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_entered.emit(
			self,
			_cached_limits,
			transition_duration,
			priority_override
		)


func _exit_area() -> void:
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_exited.emit(
			self
		)
