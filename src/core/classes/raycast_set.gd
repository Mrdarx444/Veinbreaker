extends Node2D
class_name RayCastsSet

@export var disabled: bool = false

func _ready() -> void:
	if get_children().is_empty():
		push_warning("'%s': There is no chilren for this Racast Set"%name)

func is_colliding():
	if disabled: return false
	for child in get_children(true):
		if child is RayCast2D and child.is_colliding():
			return true
	return false
