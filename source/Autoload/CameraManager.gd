extends Node

# CameraManager AUTO-LOAD
signal camera_shake(
		power: float, duration: float,
		frequency: float,
		type: PlayerCamera.ShakeType
		)
signal camera_shake_preset(preset_name: StringName)
signal change_facing_direction(new_dir: int)
signal camera_area_entered(area: CameraArea, limits: Rect2)
signal camera_area_exited(area: CameraArea)

func set_facing_direction(dir: int): change_facing_direction.emit(dir)

func apply_camera_shake(power: float, duration: float, frequency: float, type: PlayerCamera.ShakeType):
	camera_shake.emit(power, duration, frequency, type)

func apply_camera_shake_preset(preset_name: StringName):
	if PlayerCamera.SHAKE_PRESETS.has(preset_name):
		camera_shake_preset.emit(preset_name)
