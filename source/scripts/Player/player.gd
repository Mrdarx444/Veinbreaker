extends CharacterBody2D

var speed := 400.0
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _physics_process(delta: float) -> void:
	movement_handle(delta)
	gravity_handle(delta)
	move_and_slide()
	print("Velocity: ", velocity)

func gravity_handle(delta: float):
	if !is_on_floor():
		velocity.y += gravity * delta
	else :
		velocity.y = 0

func movement_handle(delta: float):
	var joystick := Input.get_vector("Left", "Right", "Up", "Down")
	if joystick.x > 0:
		velocity.x = speed
	elif joystick.x < 0:
		velocity.x = -speed
	else :
		velocity.x = 0
