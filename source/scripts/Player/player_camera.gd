extends Camera2D
class_name PlayerCamera

### Recive Signals From CameraManager

@export var decay := 2.2        # How fast the shake fades (0 to 1)
@export var max_offset := Vector2(32, 32)  # Maximum horizontal/vertical shake in pixels
@export var max_roll := 0.1      # Maximum rotation in radians

var trauma := 0.0
var noise = FastNoiseLite.new()
var noise_y := 0.0

func _ready() -> void:
	randomize()
	noise.seed = randi()
	noise.frequency = 4.0
	CameraManager.shake.connect(Callable(self, "add_trauma"))

func add_trauma(amount: float) -> void:
	trauma = clamp(trauma + amount, 0.0, 1.0)

func _process(delta: float) -> void:
	if trauma > 0.0:
		stage_shake(delta)
		trauma = max(trauma - decay * delta, 0.0)
	else:
		offset = Vector2.ZERO
		rotation = 0.0

func stage_shake(delta: float) -> void:
	var shake = pow(trauma, 2.0) # Quadratic curve for natural feel
	noise_y += delta * 50.0
	# Generate smooth noise offsets
	offset = Vector2(
		max_offset.x * shake * noise.get_noise_2d(noise_y, 0.0),
		max_offset.y * shake * noise.get_noise_2d(0.0, noise_y)
	)
	rotation = max_roll * shake * noise.get_noise_2d(noise_y, noise_y)
