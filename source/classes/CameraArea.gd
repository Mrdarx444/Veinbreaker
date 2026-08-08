class_name CameraArea
extends Area2D

## CameraArea
## ------------------------------------------------------------------
## Placed per-room (or per boss arena / special room). Detects ONLY the
## Player (via the "player" group — safe, no type-check nil risk) and
## broadcasts its `limits` through the CameraManager signal bus.
## PlayerCamera listens and applies the SMALLEST currently-overlapping
## limits (handles stacked/nested areas, e.g. a boss room inside a
## bigger hall).
##
## `limits` is authored manually rather than derived from the
## CollisionShape2D on purpose: the detection trigger (where the player
## crosses to activate this area) and the actual camera bound can be
## different shapes/sizes — e.g. a thin trigger at a doorway applying
## a large room-sized limit.
## ------------------------------------------------------------------

@onready var limits: Rect2 = $Collision.shape.get_rect()
@export var enabled: bool = true

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node2D) -> void:
	if ((body is not Player) or !enabled):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_entered.emit(self, limits)


func _on_body_exited(body: Node2D) -> void:
	if ((body is not Player) or !enabled):
		return
	if has_node("/root/CameraManager"):
		CameraManager.camera_area_exited.emit(self)
