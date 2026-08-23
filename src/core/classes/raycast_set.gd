extends Node2D
class_name RayCastsSet

enum SET_TYPES {ALL, ONE_AT_LEAST, MINIMUM}
@export var disabled: bool = false
@export var type: SET_TYPES = SET_TYPES.ONE_AT_LEAST
@export_range(0, 9999, 1) var min_required_collisions: int = 1

func _ready() -> void:
	if get_children().is_empty():
		push_warning("'%s': There is no chilren for this Racast Set"%name)

func is_colliding():
	if disabled: return false
	
	match type:
		SET_TYPES.ALL:
			var _is_colliding: bool = true
			for child in get_children(true):
				if child is RayCast2D and !child.is_colliding():
					_is_colliding = false
			return _is_colliding
		SET_TYPES.ONE_AT_LEAST:
			for child in get_children(true):
				if child is RayCast2D and child.is_colliding():
					return true
			return false
		SET_TYPES.MINIMUM:
			var hit_count := 0
			for child in get_children(true):
				if child is RayCast2D and child.is_colliding():
					hit_count += 1
			if hit_count >= min_required_collisions:
				return true

			return false
		_:
			push_error("'%s': There is an Error."%name)
			return false
