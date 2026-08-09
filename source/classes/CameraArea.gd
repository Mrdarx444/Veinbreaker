class_name CameraArea
extends Area2D

## CameraArea (v3)
## ------------------------------------------------------------------
## Two SEPARATE shapes, both WYSIWYG (draggable in the 2D viewport):
##   - "DetectionShape": a normal, ENABLED CollisionShape2D. Triggers
##     body_entered/exited. Keep it INSET (smaller than) the room's
##     true bounds — the player then crosses into the new area a bit
##     before the camera limits finish tweening, hiding the switch.
##   - "LimitsShape": a DISABLED CollisionShape2D (disabled = true, so
##     it never affects physics) whose size/position define the actual
##     camera bounds. Disabled shapes are still fully visible/draggable
##     in the editor — you keep exact, independent visual control over
##     both rects.
## If no "LimitsShape" child exists, DetectionShape is used for both
## (fine for small rooms where the distinction doesn't matter).
## ------------------------------------------------------------------

@export var active: bool = true

var _cached_limits: Rect2
var _has_valid_limits: bool = false


func _ready() -> void:
	if not active:
		return
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_cache_limits_from_shape()


func _cache_limits_from_shape() -> void:
	var shape_node: CollisionShape2D = get_node_or_null("LimitsShape") as CollisionShape2D
	if shape_node == null:
		shape_node = _find_any_collision_shape()

	if shape_node == null or shape_node.shape == null:
		push_error("CameraArea '%s': needs a CollisionShape2D (named 'LimitsShape', or any CollisionShape2D) with a RectangleShape2D." % name)
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


func _on_body_entered(body: Node2D) -> void:
	if not active or not _has_valid_limits:
		return
	if not (body.is_in_group("player") and body is Player):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_entered.emit(self, _cached_limits)


func _on_body_exited(body: Node2D) -> void:
	if not active or not _has_valid_limits:
		return
	if not (body.is_in_group("player") and body is Player):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_exited.emit(self)
