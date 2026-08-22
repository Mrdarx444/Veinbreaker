extends Node2D
class_name WallRayCastSet

@export var disabled: bool = false

func is_colliding():
	if disabled: return false
	for child in get_children(true):
		if child is RayCast2D and child.is_colliding():
			return true
	return false
