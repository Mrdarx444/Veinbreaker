extends Node

# CameraManager — AUTOLOAD

signal camera_shake(power: float, duration: float, frequency: float, type: PlayerCamera.ShakeType)
signal camera_shake_preset(preset: GameConstants.ShakePreset)
signal change_facing_direction(new_dir: int)
signal camera_area_entered(area: CameraArea, limits: Rect2, transition_duration: float)
signal camera_area_exited(area: CameraArea)

func set_facing_direction(dir: int) -> void:
	change_facing_direction.emit(dir)

func apply_camera_shake(power: float, duration: float, frequency: float, type: PlayerCamera.ShakeType) -> void:
	camera_shake.emit(power, duration, frequency, type)

func apply_camera_shake_preset(preset: GameConstants.ShakePreset) -> void:
	if GameConstants.SHAKE_PRESETS.has(preset):
		camera_shake_preset.emit(preset)
