class_name CameraArea
extends Area2D

## CameraArea (v4)
## ------------------------------------------------------------------
## THREE optional shapes, all WYSIWYG (draggable in the 2D viewport):
##   - "EntranceShape": ENABLED CollisionShape2D. Fires camera_area_entered.
##     Keep it INSET (smaller) than the room — the player commits into
##     the room before the limit change happens.
##   - "ExitShape": ENABLED CollisionShape2D, larger than EntranceShape.
##     Fires camera_area_exited only once the player is well clear.
##     A bigger exit than entrance prevents "limit thrashing" (rapid
##     enter/exit flicker) when the player lingers on a doorway.
##   - "LimitsShape": DISABLED CollisionShape2D — the actual camera
##     bound. Disabled shapes are still visible/draggable in the
##     editor, just excluded from physics.
## Fallback chain if some are missing: LimitsShape -> EntranceShape ->
## any CollisionShape2D found. EntranceShape/ExitShape both fall back
## to the same single shape if only one exists — a simple one-shape
## room needs zero extra setup.
##
## `transition_duration` (0.0 default): limits snap instantly. Set
## > 0.0 only where a deliberate slow reveal is wanted (boss arena).
##
## `priority_override` (-1 = unset): if >= 0 on any active area,
## PlayerCamera uses the highest-priority active area regardless of
## size — escape hatch for the rare "smallest wins" mistake.
## ------------------------------------------------------------------

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
	body_shape_entered.connect(_on_body_shape_entered)
	body_shape_exited.connect(_on_body_shape_exited)
	await get_tree().physics_frame
	_check_initial_overlap()


func _resolve_shapes() -> void:
	_entrance_shape = get_node_or_null("EntranceShape") as CollisionShape2D
	if _entrance_shape == null:
		_entrance_shape = _find_any_collision_shape()

	_exit_shape = get_node_or_null("ExitShape") as CollisionShape2D
	if _exit_shape == null:
		_exit_shape = _entrance_shape

	var limits_shape: CollisionShape2D = get_node_or_null("LimitsShape") as CollisionShape2D
	if limits_shape == null:
		limits_shape = _entrance_shape

	_cache_limits_from_shape(limits_shape)


func _cache_limits_from_shape(shape_node: CollisionShape2D) -> void:
	if shape_node == null or shape_node.shape == null:
		push_error("CameraArea '%s': needs at least one CollisionShape2D with a RectangleShape2D." % name)
		return
	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		push_error("CameraArea '%s': the limits shape must be a RectangleShape2D." % name)
		return
	var half_size: Vector2 = rect_shape.size / 2.0
	var world_center: Vector2 = shape_node.global_position
	_cached_limits = Rect2(world_center - half_size, rect_shape.size)
	_has_valid_limits = true


func _find_any_collision_shape() -> CollisionShape2D:
	for child in get_children():
		if child is CollisionShape2D:
			return child
	return null


## Catches a Player that spawns already overlapping this area — the
## shape-entered signal only fires for NEW overlaps, so a fresh scene
## load could otherwise show one frame of default (unclamped) limits
## before anything "enters." See doc §0.
func _check_initial_overlap() -> void:
	for body in get_overlapping_bodies():
		if body.is_in_group("player") and body is Player:
			_enter_area()
			return


func _on_body_shape_entered(_body_rid: RID, body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	if not active or not _has_valid_limits:
		return
	if shape_owner_get_owner(shape_find_owner(local_shape_index)) != _entrance_shape:
		return
	if not (body.is_in_group("player") and body is Player):
		return
	_enter_area()


func _on_body_shape_exited(_body_rid: RID, body: Node2D, _body_shape_index: int, local_shape_index: int) -> void:
	if not active or not _has_valid_limits:
		return
	if shape_owner_get_owner(shape_find_owner(local_shape_index)) != _exit_shape:
		return
	if not (body.is_in_group("player") and body is Player):
		return
	_exit_area()


func _enter_area() -> void:
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_entered.emit(self, _cached_limits, transition_duration)


func _exit_area() -> void:
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_exited.emit(self)
