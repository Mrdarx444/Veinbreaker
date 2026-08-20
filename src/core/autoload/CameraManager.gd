extends Node

## Autoload
## ------------------------------------------------------------
## Event Bus فقط. لا يحتوي منطق الكاميرا الأساسي.
## ------------------------------------------------------------

signal camera_shake(
	power: float,
	duration: float,
	frequency: float,
	type: PlayerCamera.ShakeType
)

signal camera_shake_preset(preset: GameConstants.ShakePreset)

signal change_facing_direction(new_direction: int)

signal camera_area_entered(
	area: CameraArea,
	limits: Rect2,
	transition_duration: float,
	priority: int
)

signal camera_area_exited(area: CameraArea)


func set_facing_direction(direction: int) -> void:
	if direction == 0:
		return
	change_facing_direction.emit(direction)


func apply_camera_shake(
	power: float,
	duration: float,
	frequency: float = 30.0,
	type: PlayerCamera.ShakeType = PlayerCamera.ShakeType.RANDOM
) -> void:
	camera_shake.emit(power, duration, frequency, type)

func apply_camera_shake_preset(preset: GameConstants.ShakePreset):
	camera_shake_preset.emit(preset)
