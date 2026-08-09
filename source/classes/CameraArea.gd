class_name CameraArea
extends Area2D

## CameraArea
## ------------------------------------------------------------------
## Placed per-room / boss arena / special room. Detects ONLY the Player
## (via the "player" group) and broadcasts this room's camera limits
## through the CameraManager signal bus.
##
## WHY v1 broke: Camera2D's limit_left/top/right/bottom are ABSOLUTE
## WORLD PIXEL COORDINATES from the scene's (0,0) origin — not a size,
## not relative to this node. Typing a Rect2 by hand has zero visual
## reference for where (0,0) even is, so the numbers were guesses.
##
## Fix: limits are read from a CHILD CollisionShape2D using a
## RectangleShape2D. That shape IS visible and draggable in the 2D
## viewport — resize it to match the room, and correct absolute world
## coordinates are computed automatically from its real transform.
## No manual numbers, ever.
## ------------------------------------------------------------------

@export var active: bool = true

var _cached_limits: Rect2
var _has_valid_limits: bool = false


func _ready() -> void:
	if not active: return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_cache_limits_from_shape()


func _cache_limits_from_shape() -> void:
	if not active: return
	var shape_node: CollisionShape2D = null
	for child in get_children():
		if child is CollisionShape2D:
			shape_node = child
			break

	if shape_node == null or shape_node.shape == null:
		push_error("CameraArea '%s': needs a child CollisionShape2D with a RectangleShape2D." % name)
		return

	var rect_shape := shape_node.shape as RectangleShape2D
	if rect_shape == null:
		push_error("CameraArea '%s': the CollisionShape2D's shape must be a RectangleShape2D." % name)
		return

	var half_size: Vector2 = rect_shape.size / 2.0
	var world_center: Vector2 = shape_node.global_position
	_cached_limits = Rect2(world_center - half_size, rect_shape.size)
	_has_valid_limits = true


func _on_body_entered(body: Node2D) -> void:
	if not active: return
	if not _has_valid_limits or !(body.is_in_group("player") and body is Player):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_entered.emit(self, _cached_limits)


func _on_body_exited(body: Node2D) -> void:
	if not active: return
	if not _has_valid_limits or !(body.is_in_group("player") and body is Player):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_exited.emit(self)
