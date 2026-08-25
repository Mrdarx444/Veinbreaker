extends AnimatableBody2D
class_name Door

@export var close_offset: float = 200.0
@export var close_speed: float = 0.3
var is_closed: bool = false

func _ready() -> void:
	for cameraArea in get_tree().get_nodes_in_group("CameraArea"):
		(cameraArea as CameraArea).camera_area_entered.connect(close)

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("interact") and is_closed:
		open()

func close():
	if is_closed: return
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(global_position.x, global_position.y + close_offset), close_speed)
	is_closed = true

func open():
	if !is_closed: return
	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", Vector2(global_position.x, global_position.y - close_offset), close_speed)
	is_closed = false
