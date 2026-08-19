extends TouchScreenButton
class_name PlayerHUDRightButton

@onready var screen_size: Vector2 = get_viewport_rect().size
@export var offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	#if OS.has_feature("Mobile"):
		#visible = true
	#else :
		#visible = false
	var texture_size: Vector2 = Vector2(
		int(texture_normal.get_width() * scale.x),
		int(texture_normal.get_height() * scale.y)
	)
	position = Vector2(
		screen_size.x - texture_size.x - offset.x,
		screen_size.y - texture_size.y - offset.y
	)
