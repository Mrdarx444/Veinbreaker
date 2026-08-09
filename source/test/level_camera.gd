extends Camera2D
class_name LevelCameraDemo

@onready var player_camera: Camera2D = $"../Player".get_node("Camera")

@export var limit_border_enabled: bool = true

func _ready() -> void:
	if limit_border_enabled:
			player_camera.set_limit(SIDE_LEFT, limit_left)
			player_camera.set_limit(SIDE_TOP, limit_top)
			player_camera.set_limit(SIDE_RIGHT, limit_right)
			player_camera.set_limit(SIDE_BOTTOM, limit_bottom)
