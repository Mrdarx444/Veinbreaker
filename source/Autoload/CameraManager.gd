extends Node

#signal shake(force: float)
signal change_facing_direction(new_dir: int)
signal camera_area_entered(area: CameraArea, limits: Rect2)
signal camera_area_exited(area: CameraArea)

func set_facing_direction(dir: int): change_facing_direction.emit(dir)

#func camera_shake(force: float = 0.5):
	#shake.emit(force)
