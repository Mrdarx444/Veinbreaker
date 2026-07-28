extends Camera2D

@onready var player_camera: Camera2D = $"../Player".get_node("Camera")

@export var limit_border_enabled: bool = true

func _ready() -> void:
	if limit_border_enabled:
		player_camera.limit_left = limit_left
		player_camera.limit_top = limit_top
		player_camera.limit_right = limit_right
		player_camera.limit_bottom = limit_bottom
