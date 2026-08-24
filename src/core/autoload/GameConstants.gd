extends Node

# GameConstants — AUTOLOAD
# Project-wide constants that benefit from editor autocompletion.
# Shake presets live here (not in PlayerCamera) specifically so typing
# `GameConstants.ShakePreset.` autocompletes the preset names — a
# StringName gives the editor nothing to suggest.

enum ShakePreset {
	FAST_FALL,
	FORCED_FALL,
	BIG_FALL,
	DOUBLE_JUMP,
	GROUND_DASH,
	DODGE,
	WALL_STICK,
	WALL_SLIDE,
	WALL_SLIDE_FAST,
	HIT_LIGHT,
	HIT_HEAVY,
	PARRY_SUCCESS,
	BOSS_INTRO,
}

const SHAKE_PRESETS: Dictionary = {
	ShakePreset.FAST_FALL:       {"power": 6.0,  "duration": 0.04,  "frequency": 60.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.FORCED_FALL:     {"power": 8.0,  "duration": 0.16, "frequency": 20.0, "type": PlayerCamera.ShakeType.VERTICAL},
	ShakePreset.BIG_FALL:        {"power": 15.0, "duration": 0.5,  "frequency": 70.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.DOUBLE_JUMP:     {"power": 6.0, "duration": 0.2,  "frequency": 50.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.GROUND_DASH:     {"power": 8, "duration": 0.1,  "frequency": 30.0, "type": PlayerCamera.ShakeType.HORIZONTAL},
	ShakePreset.DODGE:           {"power": 7.5, "duration": 0.15,  "frequency": 40.0, "type": PlayerCamera.ShakeType.HORIZONTAL},
	ShakePreset.WALL_STICK:      {"power": 7, "duration": 0.14,  "frequency": 30.0, "type": PlayerCamera.ShakeType.HORIZONTAL},
	ShakePreset.WALL_SLIDE:      {"power": 2.0, "duration": 0.05,  "frequency": 10.0, "type": PlayerCamera.ShakeType.RANDOM},
	ShakePreset.WALL_SLIDE_FAST: {"power": 2.5, "duration": 0.04,  "frequency": 24.0, "type": PlayerCamera.ShakeType.RANDOM},
	#ShakePreset.HIT_LIGHT:       {"power": 4.0,  "duration": 0.15, "frequency": 35.0, "type": PlayerCamera.ShakeType.RANDOM},
	#ShakePreset.HIT_HEAVY:       {"power": 9.0,  "duration": 0.35, "frequency": 25.0, "type": PlayerCamera.ShakeType.RANDOM},
	#ShakePreset.PARRY_SUCCESS:   {"power": 3.0,  "duration": 0.0,  "frequency": 0.0,  "type": PlayerCamera.ShakeType.RANDOM},
	#ShakePreset.BOSS_INTRO:      {"power": 6.0,  "duration": 0.6,  "frequency": 15.0, "type": PlayerCamera.ShakeType.RANDOM},
}

# TEMP Until Fix Resulution
const CAMERA_DEFAULT_ZOOMS: Dictionary = {
	"mobile": Vector2(0.6, 0.6),
	"pc": Vector2(0.5, 0.5)
}
